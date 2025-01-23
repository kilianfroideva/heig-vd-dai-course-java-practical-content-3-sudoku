#!/bin/bash

# Text colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Function to print Sudoku board
print_board() {
    local grid=$1
    echo "   1 2 3   4 5 6   7 8 9"
    echo "  ─────────────────────────"
    for ((i=0; i<9; i++)); do
        local row_letter=$(printf "\\$(printf '%03o' $((65 + i)))")
        printf "$row_letter │"
        for ((j=0; j<9; j++)); do
            local val=${grid:$((i*9+j)):1}
            if [ "$val" == "0" ]; then
                printf " ·"
            else
                printf " $val"
            fi
            if [ $((j % 3)) -eq 2 ] && [ $j -lt 8 ]; then
                printf " │"
            fi
        done
        printf " │\n"
        if [ $((i % 3)) -eq 2 ] && [ $i -lt 8 ]; then
            echo "  ├───────┼───────┼───────┤"
        fi
    done
    echo "  ─────────────────────────"
}

echo -e "${BLUE}Starting Sudoku Battle...${NC}"

# 1. Create new game
echo -e "\n${GREEN}1. Creating new game...${NC}"
CREATE_RESPONSE=$(curl -s -X POST http://localhost:1236/api/games \
  -H "Content-Type: application/json" \
  -d '{"type": "SUDOKU_9X9", "difficulty": true}')

GAME_ID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
INITIAL_GRID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['initialGrid'])")
SOLUTION_GRID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(''.join(str(x) for row in json.load(sys.stdin)['grid'] for x in row))")

echo -e "\n${BLUE}Initial Board:${NC}"
print_board "$INITIAL_GRID"

# 2. Players join
echo -e "\n${GREEN}2. Players joining...${NC}"
PLAYER1_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" \
  -H "Content-Type: application/json" \
  -d '{"name": "Player 1"}')
PLAYER1_ID=$(echo $PLAYER1_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")

PLAYER2_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" \
  -H "Content-Type: application/json" \
  -d '{"name": "Player 2"}')
PLAYER2_ID=$(echo $PLAYER2_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")

# Initialize scores
PLAYER1_SCORE=0
PLAYER2_SCORE=0
CURRENT_GRID=$INITIAL_GRID

# 3. Battle simulation
for ((i=0; i<81; i++)); do
    if [ "${INITIAL_GRID:$i:1}" == "0" ]; then
        row=$((i / 9))
        col=$((i % 9))
        row_letter=$(printf "\\$(printf '%03o' $((65 + row)))")
        position="${row_letter}$((col + 1))"
        correct_value="${SOLUTION_GRID:$i:1}"
        
        # Randomly choose player
        if [ $((RANDOM % 2)) -eq 0 ]; then
            PLAYER="Player 1"
            PLAYER_ID=$PLAYER1_ID
            COLOR=$GREEN
        else
            PLAYER="Player 2"
            PLAYER_ID=$PLAYER2_ID
            COLOR=$BLUE
        fi
        
        echo -e "\n${COLOR}$PLAYER trying position $position with value $correct_value${NC}"
        
        RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER_ID/moves" \
          -H "Content-Type: application/json" \
          -d "{\"position\": \"$position\", \"value\": \"$correct_value\"}")
        
        # Check if move was successful
        if [[ $RESPONSE == *"CORRECT_MOVE"* ]] || [[ $RESPONSE == *"COMPLETED"* ]]; then
            echo -e "${COLOR}✓ HIT! $PLAYER correctly placed $correct_value at $position${NC}"
            # Update current grid
            CURRENT_GRID="${CURRENT_GRID:0:$i}${correct_value}${CURRENT_GRID:$((i+1))}"
            print_board "$CURRENT_GRID"
            
            if [ "$PLAYER" == "Player 1" ]; then
                ((PLAYER1_SCORE++))
            else
                ((PLAYER2_SCORE++))
            fi
            
            echo -e "\nCurrent Scores:"
            echo -e "${GREEN}Player 1: $PLAYER1_SCORE${NC}"
            echo -e "${BLUE}Player 2: $PLAYER2_SCORE${NC}"
            
            if [[ $RESPONSE == *"COMPLETED"* ]]; then
                echo -e "\n${COLOR}🏆 $PLAYER completed the puzzle!${NC}"
                break
            fi
        fi
        
        sleep 0.5
    fi
done

# 4. Final results
echo -e "\n${BLUE}Final Board State:${NC}"
print_board "$CURRENT_GRID"

echo -e "\n${GREEN}Final Scores:${NC}"
echo -e "${GREEN}Player 1: $PLAYER1_SCORE${NC}"
echo -e "${BLUE}Player 2: $PLAYER2_SCORE${NC}"

if [ $PLAYER1_SCORE -gt $PLAYER2_SCORE ]; then
    echo -e "\n${GREEN}🏆 Player 1 wins!${NC}"
elif [ $PLAYER2_SCORE -gt $PLAYER1_SCORE ]; then
    echo -e "\n${BLUE}🏆 Player 2 wins!${NC}"
else
    echo -e "\n${RED}It's a tie!${NC}"
fi

echo -e "\n${GREEN}Battle complete!${NC}"