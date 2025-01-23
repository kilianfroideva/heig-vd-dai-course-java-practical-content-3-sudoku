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
        if [ "$VALIDITY" == "CORRECT_MOVE" ] || [ "$VALIDITY" == "COMPLETED" ]; then
            echo -e "${COLOR}✓ HIT! $PLAYER correctly placed $value at $position${NC}"

            # Update grid state with the new move
            CURRENT_GRID="${CURRENT_GRID:0:$i}${value}${CURRENT_GRID:$((i+1))}"
            print_board "$CURRENT_GRID"

            # Update scores
            if [ "$PLAYER" == "Player 1" ]; then
                ((PLAYER1_SCORE++))
            else
                ((PLAYER2_SCORE++))
            fi

            echo -e "\nCurrent Scores:"
            echo -e "${GREEN}Player 1: $PLAYER1_SCORE${NC}"
            echo -e "${BLUE}Player 2: $PLAYER2_SCORE${NC}"

            if [ "$VALIDITY" == "COMPLETED" ]; then
                echo -e "\n${COLOR}🏆 $PLAYER completed the puzzle!${NC}"
                break
            fi
        else
            echo -e "${RED}✗ MISS! $PLAYER failed to place a valid number at $position ($VALIDITY)${NC}"
        fi

        # Add a small delay between positions
        sleep 0.5
        printf " │\n"
        if [ $((i % 3)) -eq 2 ] && [ $i -lt 8 ]; then
            echo "  ├───────┼───────┼───────┤"
        fi
    done
    echo "  ─────────────────────────"
}

echo -e "${BLUE}Starting Sudoku Battle...${NC}"
# Function to check JSON validity
check_json() {
    local json="$1"
    local description="$2"
    if ! echo "$json" | python3 -m json.tool &>/dev/null; then
        echo "Error: Invalid JSON response for $description"
        echo "Response was: $json"
        return 1
    fi
    return 0
}
# Function to validate move response
validate_response() {
    local response=$1
    if [ -z "$response" ]; then
        echo "ERROR: Empty response"
        return 1
    fi
    if ! echo "$response" | python3 -c "import sys, json; json.load(sys.stdin)" &>/dev/null; then
        echo "ERROR: Invalid JSON response: $response"
        return 1
    fi
    return 0
}

# 1. Create new game
echo -e "\n${GREEN}1. Creating new game...${NC}"
CREATE_RESPONSE=$(curl -v -X POST http://localhost:1236/api/games \
  -H "Content-Type: application/json" \
  -d '{
    "type": "SUDOKU_9X9",
    "difficulty": "MEDIUM",
    "status": "WAITING"
  }')

# Check if the request was successful
if [ -z "$CREATE_RESPONSE" ]; then
    echo "Error: Failed to create game. No response from server."
    exit 1
fi

GAME_ID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
INITIAL_GRID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['initialGrid'])")
SOLUTION_GRID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['solutionGrid'])")
CURRENT_GRID=$INITIAL_GRID

echo -e "\n${BLUE}Initial Board:${NC}"
print_board "$INITIAL_GRID"

# 2. Players join
echo -e "\n${GREEN}2. Players joining...${NC}"
PLAYER1_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Player 1",
    "id": null,
    "startTime": 0,
    "endTime": 0
  }')

# Check if the request was successful
if [ -z "$PLAYER1_RESPONSE" ]; then
    echo "Error: Failed to join game for Player 1. No response from server."
    exit 1
fi
PLAYER1_ID=$(echo $PLAYER1_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")

PLAYER2_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Player 2",
    "id": null,
    "startTime": 0,
    "endTime": 0
  }')

# Check if the request was successful
if [ -z "$PLAYER2_RESPONSE" ]; then
    echo "Error: Failed to join game for Player 2. No response from server."
    exit 1
fi
PLAYER2_ID=$(echo $PLAYER2_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")

# Initialize scores
PLAYER1_SCORE=0
PLAYER2_SCORE=0
CURRENT_GRID=$INITIAL_GRID

# 3. Battle simulation
for ((i=0; i<81; i++)); do
# Check if the position is empty (either 0 or ·)
current_cell="${INITIAL_GRID:$i:1}"
if [ "$current_cell" == "0" ] || [ "$current_cell" == "·" ] || [ "$current_cell" == " " ]; then
        row=$((i / 9))
        col=$((i % 9))
        row_letter=$(printf "\\$(printf '%03o' $((65 + row)))")
        position="${row_letter}$((col + 1))"

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

        # Try each number from 1-9
        for value in {1..9}; do
            echo -e "\n${COLOR}$PLAYER trying position $position with value $value${NC}"

            RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER_ID/moves" \
                      -H "Content-Type: application/json" \
                      -d "{\"position\": \"$position\", \"value\": \"$value\"}" \
                      2>/dev/null)

            # Parse the response
            VALIDITY=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('validity', 'INVALID'))")

            if [ "$VALIDITY" == "CORRECT_MOVE" ] || [ "$VALIDITY" == "COMPLETED" ]; then
                echo -e "${COLOR}✓ HIT! $PLAYER correctly placed $value at $position${NC}"

                # Update grid state with the new move
                CURRENT_GRID="${CURRENT_GRID:0:$i}${value}${CURRENT_GRID:$((i+1))}"
                print_board "$CURRENT_GRID"

                # Update scores
                if [ "$PLAYER" == "Player 1" ]; then
                    ((PLAYER1_SCORE++))
                else
                    ((PLAYER2_SCORE++))
                fi

                echo -e "\nCurrent Scores:"
                echo -e "${GREEN}Player 1: $PLAYER1_SCORE${NC}"
                echo -e "${BLUE}Player 2: $PLAYER2_SCORE${NC}"

                if [ "$VALIDITY" == "COMPLETED" ]; then
                    echo -e "\n${COLOR}🏆 $PLAYER completed the puzzle!${NC}"
                    break 2
                fi
                break
            else
                echo -e "${RED}✗ MISS! $PLAYER failed to place $value at $position ($VALIDITY)${NC}"
            fi
            sleep 0.1
        done
        sleep 0.5
    fi
done
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

            echo -e "\n${COLOR}$PLAYER trying position $position with value $value${NC}"

            # Convert the value to string to ensure proper JSON formatting
            RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER_ID/moves" \
                      -H "Content-Type: application/json" \
                      -d "{\"position\": \"$position\", \"value\": \"$correct_value\"}" \
              2>/dev/null)

            # If we got a correct move, break the loop
            VALIDITY=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('validity', 'INVALID'))")
            if [ "$VALIDITY" == "CORRECT_MOVE" ] || [ "$VALIDITY" == "COMPLETED" ]; then
                break
            fi

            # Add a small delay between attempts
            sleep 0.1
        done

          # Parse the response
          VALIDITY=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('validity', 'INVALID'))")

          if [ "$VALIDITY" == "CORRECT_MOVE" ] || [ "$VALIDITY" == "COMPLETED" ]; then
              echo -e "${COLOR}✓ HIT! $PLAYER correctly placed $correct_value at $position${NC}"

              # Update grid state with the new move
              CURRENT_GRID="${CURRENT_GRID:0:$i}${correct_value}${CURRENT_GRID:$((i+1))}"
              print_board "$CURRENT_GRID"

              # Update scores
              if [ "$PLAYER" == "Player 1" ]; then
                  ((PLAYER1_SCORE++))
              else
                  ((PLAYER2_SCORE++))
              fi

              echo -e "\nCurrent Scores:"
              echo -e "${GREEN}Player 1: $PLAYER1_SCORE${NC}"
              echo -e "${BLUE}Player 2: $PLAYER2_SCORE${NC}"

              if [ "$VALIDITY" == "COMPLETED" ]; then
                  echo -e "\n${COLOR}🏆 $PLAYER completed the puzzle!${NC}"
                  break
              fi
          else
              echo -e "${RED}✗ MISS! $PLAYER failed to place $correct_value at $position ($VALIDITY)${NC}"
          fi

          # Add a small delay between moves
          sleep 0.5

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
