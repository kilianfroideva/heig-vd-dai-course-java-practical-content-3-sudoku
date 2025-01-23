#!/bin/bash
# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: This script requires Python 3 to be installed"
    exit 1
fi

# Text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Testing Sudoku API..."

# 1. Create a new game (9x9)
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
fi

# 2. Get all games
echo -e "\n${GREEN}2. Getting all games...${NC}"
curl -s -X GET http://localhost:1236/api/games | python3 -m json.tool

# 3. Get specific game
echo -e "\n${GREEN}3. Getting game with ID: $GAME_ID${NC}"
curl -s -X GET "http://localhost:1236/api/games/$GAME_ID" | python3 -m json.tool

# 4. Update game
echo -e "\n${GREEN}4. Updating game status...${NC}"
curl -s -X PUT "http://localhost:1236/api/games/$GAME_ID" \
  -H "Content-Type: application/json" \
  -d "{\"status\":\"IN_PROGRESS\"}" | python3 -m json.tool

# 5. Delete game
echo -e "\n${GREEN}5. Deleting game...${NC}"
curl -s -X DELETE "http://localhost:1236/api/games/$GAME_ID" -w "\nStatus code: %{http_code}\n"

# 6. Verify deletion
echo -e "\n${GREEN}6. Verifying game was deleted...${NC}"
curl -s -X GET "http://localhost:1236/api/games/$GAME_ID" -w "\nStatus code: %{http_code}\n"

echo -e "\n${GREEN}Test complete!${NC}"