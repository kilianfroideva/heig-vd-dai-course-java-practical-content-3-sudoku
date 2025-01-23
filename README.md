# Sudoku Game

## Auteurs
Kilian Froidevaux & Nicolas Bovard
## Overview

The Sudoku Game enables multiplayer Sudoku gameplay over a TCP network connection, supporting dynamic grid sizes and concurrent client interactions.

## Installing and configure Virtual Machine

### Install and configure SSH (and SCP)

In this section, you will install and configure SSH on your operating system.
This will automatically install SCP as well.

#### Install the SSH client

The SSH client is available on most operating systems.

You certainly already have it installed on your operating system as you used it
in the
[Git, GitHub and Markdown](https://github.com/heig-vd-dai-course/heig-vd-dai-course/tree/main/03-git-github-and-markdown)
chapter.

If not, follow the instructions below to install it:

```sh
# Install the SSH client
sudo apt install openssh-client
```

### Acquire a virtual machine on a cloud provider

Acquire a virtual machine on a cloud provider, here we show how to install the Azure VM:
[Microsoft Azure](https://azure.microsoft.com).

- Create an account or login
- Create a virtual machine
- Access with SSH and configure the virtual machine

```sh
# Connect to the virtual machine with SSH
ssh ubuntu@<vm public ip>
```


### Update and secure the virtual machine

Once connected to the virtual machine, you can update the packages with the
following command:

```sh
# Update the available packages
sudo apt update

# Upgrade the packages
sudo apt upgrade
```

You can then reboot the virtual machine with the following command to apply all
the updates:

```sh
# Reboot the virtual machine
sudo reboot
```
## DNS Configuration

- Domaine principal: https://supersudoku.duckdns.org
- Port: 1236

### Domain and Server
- Connect on Duckdns.org
- Add your sub domain (ex : https://your-sudoku.duckdns.org)
- configure server to respond with this domain
- Open port 1236


## Docker Usage

Pull and run the container:

```bash
# Pull the image
docker pull ghcr.io/kilianfroideva/sudoku/sudoku-app:1.0.0

# Run the container
docker run -p 1236:1236 ghcr.io/kilianfroideva/sudoku/sudoku-app:1.0.0
```
### Docker Compose 

## Get the game on your computer

1. Clone the repository:

    ```bash
    git clone https://github.com/kilianfroideva/heig-vd-dai-course-java-practical-content-3-sudoku
    ```

2. Navigate to the project directory:

    ```bash
    cd .../heig-vd-dai-course-java-tcp-programming-practical-content-sudoku
    ```

3. Build the project using Maven:

    ```bash
    mvn clean install
    ```
   
4.Build the game :
```bash
docker build -t sudoku-app
```

5.
 - To run as client on localhost the command is :
```bash
docker run -it --network="host" sudoku-app client --host=127.0.0.1
```
 - To run as server: 
```bash
docker run -p 1236:1236 sudoku-app server
```

6. Publish to Docker hub :
```bash
docker tag sudoku-app username/sudoku-app
docker push username/sudoku-app
```

## API configurations

- POST /games : Create a new game
- POST /games/gameId/join : join a lobby
- PUT /games/gamesId/players/playersId : Make a move
- GET /games/gameId : get the actual state of the game
- app.get("/games", gameController::getAll); GET /games : get all the lobbies
-


### Game Commands curl

### 1. Start Game
```bash
curl -s -X POST http://localhost:1236/api/games \
  -H "Content-Type: application/json" \
  -d '{"type": "SUDOKU_9X9", "difficulty": MEDIUM}')
```

### 2. Make Move
```bash
curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER1_ID/moves" \
  -H "Content-Type: application/json" \
  -d '{"position": "A1", "value": "1"}' | python3 -m json.tool  -d '{"position": "A1", "value": "1"}' | python3 -m json.tool

```

### Join lobby 
```bash
curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/join" \
-H "Content-Type: application/json" \
-d '{"name": "Player 1"}')
```
### Get all lobbys:
````bash
curl -s -X GET http://localhost:1236/api/games | python3 -m json.tool
````

### Get a specific game 
````bash
curl -s -X GET "http://localhost:1236/api/games/$GAME_ID" | python3 -m json.tool
````

### get Status
````bash
curl -s -X GET "http://localhost:1236/api/games/$GAME_ID" | python3 -m json.tool
````
`
## Game Flow

1. Connect to server
2. Request grid size with the size and the difficulty
3. Make moves using the position and the value
4. Receive move validation
5. Complete game when all cells are correctly filled, the first to finish in the lobby wins


## Example Interaction

```bash
[Client] curl -s -X POST http://localhost:1236/api/games \
  -H "Content-Type: application/json" \
  -d '{"type": "SUDOKU_9X9", "difficulty": MEDIUM}')
[Server] 201 CREATED

     1 2 3   4 5 6   7 8 9
    ----------------------
A  |   7   | 8     | 2    
B  | 2     | 6     |      
C  |   3 4 |     5 |      
    ----------------------
D  |       |     7 |   2  
E  |   2 5 |       | 1 6  
F  |   9   | 5     |      
    ----------------------
G  |       | 9     | 8 3  
H  |       |     6 |     7
I  |     8 |     1 |   4 2

[Client] curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER1_ID/moves" \
  -H "Content-Type: application/json" \
  -d '{"position": "A1", "value": "1"}' | python3 -m json.tool  -d '{"position": "A1", "value": "1"}' | python3 -m json.tool
[Server] 200 OK
     1 2 3   4 5 6   7 8 9
    ----------------------
A  | 1 7   | 8     | 2    
B  | 2     | 6     |      
C  |   3 4 |     5 |      
    ----------------------
D  |       |     7 |   2  
E  |   2 5 |       | 1 6  
F  |   9   | 5     |      
    ----------------------
G  |       | 9     | 8 3  
H  |       |     6 |     7
I  |     8 |     1 |   4 2

[Client] curl -s -X POST "http://localhost:1236/api/games/$GAME_ID/players/$PLAYER1_ID/moves" \
  -H "Content-Type: application/json" \
  -d '{"position": "C1", "value": "1"}' | python3 -m json.tool  -d '{"position": "C1", "value": "1"}' | python3 -m json.tool
[Server] 400 BAD REQUEST

     1 2 3   4 5 6   7 8 9
    ----------------------
A  | 1 7   | 8     | 2    
B  | 2     | 6     |      
C  |   3 4 |     5 |      
    ----------------------
D  |       |     7 |   2  
E  |   2 5 |       | 1 6  
F  |   9   | 5     |      
    ----------------------
G  |       | 9     | 8 3  
H  |       |     6 |     7
I  |     8 |     1 |   4 2

```

## Multiplayer Support

- Concurrent game sessions
- Independent game states
- Thread-safe move validation

## Requirements

- **TCP/IP** network
- **UTF-8** compatible client
- **Java Development Kit (JDK) 8+**
- **Maven** (for building the project)
- **Git** (for cloning the repository)
