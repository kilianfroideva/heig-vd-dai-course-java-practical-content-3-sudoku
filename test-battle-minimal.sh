#!/bin/bash

echo "=== POST Game ==="
echo "Creating new game..."
GAME_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games" -H "Content-Type: application/json" -d '{"type":"SUDOKU_9X9","difficulty":"MEDIUM","status":"WAITING"}')

GAME_ID=$(echo $GAME_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo "Game created with ID: $GAME_ID"
echo "$GAME_RESPONSE"
echo

echo "=== POST Player 1 ==="
PLAYER1_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" -H "Content-Type: application/json" -d '{"name":"Player1"}')

PLAYER1_ID=$(echo $PLAYER1_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo "Player1 ID: $PLAYER1_ID"
echo "$PLAYER1_RESPONSE"
echo

echo "=== POST Player 2 ==="
PLAYER2_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" -H "Content-Type: application/json" -d '{"name":"Player2"}')

PLAYER2_ID=$(echo $PLAYER2_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo "Player2 ID: $PLAYER2_ID"
echo "$PLAYER2_RESPONSE"
echo

echo "=== POST Move Player 1 ==="
echo "Player 1 tries position A1 with value 5"
MOVE1_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER1_ID/moves" -H "Content-Type: application/json" -d '{"position":"A1","value":"5"}')
echo "$MOVE1_RESPONSE"
echo

echo "=== POST Move Player 2 ==="
echo "Player 2 tries position B2 with value 3"
MOVE2_RESPONSE=$(curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER2_ID/moves" -H "Content-Type: application/json" -d '{"position":"B2","value":"3"}')
echo "$MOVE2_RESPONSE"
echo

echo "=== GET Game State ==="
GAME_STATE=$(curl -s "http://localhost:1236/api/games/$GAME_ID")
echo "$GAME_STATE"
echo

echo "=== DELETE Game ==="
DELETE_RESPONSE=$(curl -s -X DELETE "http://localhost:1236/api/games/$GAME_ID")
echo "Game deleted with response code: $?"
