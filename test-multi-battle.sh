#!/bin/bash

# Text colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Player colors array
COLORS=($GREEN $BLUE $YELLOW $PURPLE $CYAN)

# Get number of players from command line argument, default to 3
NUM_PLAYERS=${1:-3}

if [ $NUM_PLAYERS -lt 2 ]; then
    echo -e "${RED}Need at least 2 players${NC}"
    exit 1
fi

if [ $NUM_PLAYERS -gt 5 ]; then
    echo -e "${RED}Maximum 5 players supported${NC}"
    exit 1
fi

# Function to print Sudoku board with multiple player colors
print_board() {
    local grid=$1
    local cell_owners=$2

    echo "   1 2 3   4 5 6   7 8 9"
    echo "  ─────────────────────────"

    for ((row=0; row<9; row++)); do
        local row_letter=$(printf "\\$(printf '%03o' $((65 + row)))")
        printf "$row_letter │"

        for ((col=0; col<9; col++)); do
            local index=$((row * 9 + col))
            local value=${grid:$index:1}

            # Print the value with player color if owned
            if [ "$value" == "0" ]; then
                printf " ·"
            else
                local position="${row_letter}$((col + 1))"
                local found=0
                for ((p=1; p<=$NUM_PLAYERS; p++)); do
                    if [[ $cell_owners == *"$position:P$p"* ]]; then
                        printf "${COLORS[$p-1]} $value${NC}"
                        found=1
                        break
                    fi
                done
                if [ $found -eq 0 ]; then
                    printf " $value"
                fi
            fi

            if [ $((col % 3)) -eq 2 ] && [ $col -lt 8 ]; then
                printf " │"
            fi
        done
        printf " │\n"

        if [ $((row % 3)) -eq 2 ] && [ $row -lt 8 ]; then
            echo "  ├───────┼───────┼───────┤"
        fi
    done
    echo "  ─────────────────────────"
}
echo -e "${BLUE}Starting $NUM_PLAYERS-player Sudoku Battle...${NC}"

# 1. Create game
echo -e "\n${GREEN}1. Creating new game...${NC}"
CREATE_RESPONSE=$(curl -s -X POST http://localhost:1236/api/games \
  -H "Content-Type: application/json" \
  -d '{"type": "SUDOKU_9X9", "difficulty": true}')

GAME_ID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
INITIAL_GRID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['initialGrid'])")
SOLUTION_GRID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['currentGridState'])")

echo "Game ID: $GAME_ID"
echo "Initial grid: $INITIAL_GRID"
echo -e "\n${BLUE}Initial Board:${NC}"
print_board "$INITIAL_GRID" ""

# 2. Players join
echo -e "\n${GREEN}2. Players joining...${NC}"
declare -A PLAYER_IDS
declare -A PLAYER_SCORES
declare -A PLAYER_NAMES

for ((i=1; i<=$NUM_PLAYERS; i++)); do
    PLAYER_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"Player $i\"}")

    PLAYER_ID=$(echo $PLAYER_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
    PLAYER_IDS[$i]=$PLAYER_ID
    PLAYER_SCORES[$i]=0
    PLAYER_NAMES[$i]="Player $i"

    echo -e "${COLORS[$i-1]}Player $i joined with ID: $PLAYER_ID${NC}"
done

# Function to get empty positions
get_empty_positions() {
    local initial_grid=$1
    local solution_grid=$2
    local positions=()

    for ((i=0; i<${#initial_grid}; i++)); do
        if [ "${initial_grid:$i:1}" == "0" ]; then
            row=$((i / 9))
            col=$((i % 9))
            row_letter=$(printf "\\$(printf '%03o' $((65 + row)))")
            position="${row_letter}$((col + 1))"
            solution="${solution_grid:$i:1}"
            positions+=("$position:$solution")
        fi
    done
    echo "${positions[@]}"
}

# Get empty positions and their solutions
EMPTY_POSITIONS=($(get_empty_positions "$INITIAL_GRID" "$SOLUTION_GRID"))
TOTAL_MOVES=${#EMPTY_POSITIONS[@]}

echo -e "\n${BLUE}Starting $NUM_PLAYERS-player battle with $TOTAL_MOVES possible moves${NC}"

# 3. Battle simulation
for position in "${EMPTY_POSITIONS[@]}"; do
    pos=${position%:*}
    val=${position#*:}

    # Randomly choose player
    CURRENT_PLAYER=$((RANDOM % NUM_PLAYERS + 1))
    PLAYER_ID=${PLAYER_IDS[$CURRENT_PLAYER]}
    COLOR=${COLORS[$CURRENT_PLAYER-1]}

    echo -e "\n${COLOR}Player $CURRENT_PLAYER trying position $pos with value $val${NC}"

    RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER_ID/moves" \
      -H "Content-Type: application/json" \
      -d "{\"position\": \"$pos\", \"value\": \"$val\"}")

    VALIDITY=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['validity'])")

    if [ "$VALIDITY" == "WRONG_MOVE" ] || [ "$VALIDITY" == "ALREADY_PLACED" ]; then
        echo -e "${RED}✗ MISS! Player $CURRENT_PLAYER failed to place $val at $pos${NC}"
    fi

    if [ "$VALIDITY" == "CORRECT_MOVE" ]; then
        echo -e "${COLOR}✓ HIT! Player $CURRENT_PLAYER correctly placed $val at $pos${NC}"
        # Update cell owners tracking
        CELL_OWNERS="$CELL_OWNERS$pos:P$CURRENT_PLAYER,"
        # Get and display updated board
        CURRENT_GRID=$(echo $RESPONSE | python3 -c "import sys, json; print(''.join(str(x) for row in json.load(sys.stdin)['grid'] for x in row))")
        print_board "$CURRENT_GRID" "$CELL_OWNERS"
        ((PLAYER_SCORES[$CURRENT_PLAYER]++))
    elif [ "$VALIDITY" == "COMPLETED" ]; then
        echo -e "${COLOR}🏆 Player $CURRENT_PLAYER completed the puzzle!${NC}"
        ((PLAYER_SCORES[$CURRENT_PLAYER]++))
        break
    fi

    # Display current scores
    echo -e "\nCurrent Scores:"
    for ((i=1; i<=$NUM_PLAYERS; i++)); do
        echo -e "${COLORS[$i-1]}Player $i: ${PLAYER_SCORES[$i]}${NC}"
    done

    sleep 0.5
done

echo -e "\n${BLUE}Final Board State:${NC}"
print_board "$CURRENT_GRID" "$CELL_OWNERS"
# 4. Final scores and winner determination
echo -e "\n${GREEN}Final Scores:${NC}"
MAX_SCORE=0
WINNER=0

for ((i=1; i<=$NUM_PLAYERS; i++)); do
    echo -e "${COLORS[$i-1]}Player $i: ${PLAYER_SCORES[$i]}${NC}"
    if [ ${PLAYER_SCORES[$i]} -gt $MAX_SCORE ]; then
        MAX_SCORE=${PLAYER_SCORES[$i]}
        WINNER=$i
    fi
done

echo -e "\n${COLORS[$WINNER-1]}🏆 Player $WINNER wins with $MAX_SCORE points!${NC}"
echo -e "\n${GREEN}Battle complete!${NC}"
