#!/bin/bash

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: This script requires Python 3 to be installed"
    exit 1
fi

echo "Testing Multiplayer Sudoku Game..."

# 1. Create a new game
echo -e "\n${GREEN}1. Creating new 9x9 game...${NC}"
CREATE_RESPONSE=$(curl -s -X POST http://localhost:1236/api/games \
  -H "Content-Type: application/json" \
  -d '{"type": "SUDOKU_9X9", "difficulty": true}')
GAME_ID=$(echo $CREATE_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -z "$GAME_ID" ]; then
    echo -e "${RED}Failed to create game${NC}"
    exit 1
else
    echo "Created game with ID: $GAME_ID"
    # Extract and display initial grid empty positions
    echo -e "\nAnalyzing initial grid..."
    INITIAL_GRID=$(echo $CREATE_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['initialGrid'])")
    echo "Initial grid: $INITIAL_GRID"
    echo "Empty positions (0's) are available for moves"
    echo "Solution shows A1=1, A2=5 (these are valid moves)"
fi

# 2. Player 1 joins
echo -e "\n${GREEN}2. Player 1 joining the game...${NC}"
PLAYER1_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" \
  -H "Content-Type: application/json" \
  -d '{"name": "Player 1"}')
echo $PLAYER1_RESPONSE | python3 -m json.tool

# 3. Player 2 joins
echo -e "\n${GREEN}3. Player 2 joining the game...${NC}"
PLAYER2_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" \
  -H "Content-Type: application/json" \
  -d '{"name": "Player 2"}')
echo $PLAYER2_RESPONSE | python3 -m json.tool

# 4. Check game status after players joined
echo -e "\n${GREEN}4. Checking game status...${NC}"
curl -s -X GET "http://localhost:1236/api/games/$GAME_ID" | python3 -m json.tool

# Get Player 1's ID from the response
PLAYER1_ID=$(echo $PLAYER1_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")

# 5. Player 1 makes a move
echo -e "\n${GREEN}5. Player 1 making a move...${NC}"
echo -e "\n${GREEN}5. Player 1 making a move to position A1 with value 1...${NC}"
curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER1_ID/moves" \
  -H "Content-Type: application/json" \
  -d '{"position": "A1", "value": "1"}' | python3 -m json.tool  -d '{"position": "A1", "value": "1"}' | python3 -m json.tool

  # Get Player 2's ID from the response
  PLAYER2_ID=$(echo $PLAYER2_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")

  # 6. Player 2 makes a move
  echo -e "\n${GREEN}6. Player 2 making a move...${NC}"
  echo -e "\n${GREEN}6. Player 2 making a move to position A2 with value 5...${NC}"
  curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER2_ID/moves" \
    -H "Content-Type: application/json" \
    -d '{"position": "A2", "value": "5"}' | python3 -m json.tool

# 7. Final game status
echo -e "\n${GREEN}7. Final game status...${NC}"
curl -s -X GET "http://localhost:1236/api/games/$GAME_ID" | python3 -m json.tool

echo -e "\n${GREEN}Test complete!${NC}"
