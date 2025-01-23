package ch.heigvd.dai.game;

import io.javalin.http.HttpStatus;
import ch.heigvd.dai.sudoku.*;
import ch.heigvd.dai.sudoku.enums.*;
import io.javalin.http.*;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class GameController {
    private final ConcurrentHashMap<String, Game> games;

    public GameController(ConcurrentHashMap<String, Game> games) {
        this.games = games;
    }

    public void create(Context ctx) {
        Game newGame = ctx.bodyAsClass(Game.class);

        try {
            // Create new Sudoku instance based on type
            int size = newGame.type == GameType.SUDOKU_9X9 ? 9 : 16;
            Sudoku sudoku = new Sudoku(size);
            String grid = sudoku.importSudoku(newGame.type);

            if (grid == null || sudoku == null) {
                ctx.status(HttpStatus.INTERNAL_SERVER_ERROR);
                return;
            }

            // Store both the initial grid and the Sudoku instance
            newGame.initialGrid = grid;
            newGame.setSudoku(sudoku);
            newGame.status = GameStatus.WAITING;
            newGame.id = UUID.randomUUID().toString();
            games.put(newGame.id, newGame);

            ctx.status(HttpStatus.CREATED);
            ctx.json(newGame);
        } catch (IOException e) {
            ctx.status(HttpStatus.INTERNAL_SERVER_ERROR);
        } catch (Exception e) {
            ctx.status(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    public void getAll(Context ctx) {
        List<Game> gamesList = new ArrayList<>(games.values());
        ctx.json(gamesList);
    }

    public void getOne(Context ctx) {
        String id = ctx.pathParam("id");
        Game game = games.get(id);
        if (game == null) {
            throw new NotFoundResponse("Game not found");
        }
        ctx.json(game);
    }

    public void update(Context ctx) {
        String id = ctx.pathParam("id");
        Game existingGame = games.get(id);
        if (existingGame == null) {
            throw new NotFoundResponse("Game not found");
        }

        Game updateData = ctx.bodyAsClass(Game.class);

        // Update only mutable fields while preserving the game state
        existingGame.status = updateData.status;
        if (updateData.players != null) {
            existingGame.players = updateData.players;
        }
        if (updateData.winnerId != null) {
            existingGame.winnerId = updateData.winnerId;
        }

        games.put(id, existingGame);
        ctx.json(existingGame);
    }

    public void delete(Context ctx) {
        String id = ctx.pathParam("id");
        if (games.remove(id) == null) {
            throw new NotFoundResponse("Game not found");
        }
        ctx.status(204);
    }

    public void join(Context ctx) {
        String gameId = ctx.pathParam("gameId");
        Player newPlayer = ctx.bodyValidator(Player.class)
                .check(obj -> obj.name != null, "Missing player name")
                .get();

        Game game = games.get(gameId);
        if (game == null) {
            throw new NotFoundResponse("Game not found");
        }

        if (game.status == GameStatus.COMPLETED) {
            throw new BadRequestResponse("Game already completed");
        }

        newPlayer.id = UUID.randomUUID().toString();
        newPlayer.currentGame = new Sudoku(game.initialGrid,
                String.valueOf(game.type == GameType.SUDOKU_9X9 ? 9 : 16));
        newPlayer.startTime = System.currentTimeMillis();

        game.players.add(newPlayer);
        if (game.status == GameStatus.WAITING) {
            game.status = GameStatus.IN_PROGRESS;
        }

        ctx.json(newPlayer);
    }

    public void makeMove(Context ctx) {
        String gameId = ctx.pathParam("gameId");
        String playerId = ctx.pathParam("playerId");
        Move move = ctx.bodyAsClass(Move.class);

        Game game = games.get(gameId);
        if (game == null) {
            throw new NotFoundResponse("Game not found");
        }

        Player player = game.players.stream()
                .filter(p -> p.id.equals(playerId))
                .findFirst()
                .orElseThrow(() -> new NotFoundResponse("Player not found"));

        if (game.status != GameStatus.IN_PROGRESS) {
            throw new BadRequestResponse("Game is not in progress");
        }

        if (player.currentGame == null) {
            player.currentGame = new Sudoku(game.initialGrid,
                String.valueOf(game.type == GameType.SUDOKU_9X9 ? 9 : 16));
        }

        // Verify and apply the move
        MoveValidity validity = player.currentGame.verifyMove(move.position, move.value);

        // Update game status if completed
        if (validity == MoveValidity.COMPLETED) {
            player.endTime = System.currentTimeMillis();
            game.status = GameStatus.COMPLETED;
            game.winnerId = player.id;
        }

        // Create a 2D array of the current grid state
        int size = player.currentGame.getSize();
        int[][] currentGrid = new int[size][size];
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                currentGrid[i][j] = player.currentGame.getValue(i, j);
            }
        }

        if (validity == MoveValidity.CORRECT_MOVE || validity == MoveValidity.COMPLETED) {
            // Record the move
            game.moves.add(move);
            // Record cell ownership
            game.cellOwners.put(move.position, playerId);
            // Update player score
            game.playerScores.merge(playerId, 1, Integer::sum);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("validity", validity);
        result.put("grid", currentGrid);
        result.put("moves", game.moves);
        result.put("cellOwners", game.cellOwners);
        result.put("playerScores", game.playerScores);

        ctx.json(result);
    }
}
