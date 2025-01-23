package ch.heigvd.dai.game;

import ch.heigvd.dai.sudoku.*;
import ch.heigvd.dai.sudoku.enums.GameType;
import ch.heigvd.dai.sudoku.enums.MoveValidity;
import io.javalin.http.*;

import io.javalin.http.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public class GameController {
    private final ConcurrentHashMap<String, Game> games;

    public GameController(ConcurrentHashMap<String, Game> games) {
        this.games = games;
    }

    public void create(Context ctx) {
        Game newGame = ctx.bodyValidator(Game.class)
                .check(obj -> obj.type != null, "Missing game type")
                .check(obj -> obj.difficulty != null, "Missing difficulty")
                .get();

        try {
            // Create new Sudoku instance based on type
            int size = newGame.type == GameType.SUDOKU_9X9 ? 9 : 16;
            Sudoku sudoku = new Sudoku(size);
            sudoku.importSudoku(newGame.type);

            newGame.sudoku = sudoku;
            games.put(newGame.id, newGame);

            ctx.status(HttpStatus.CREATED);
            ctx.json(newGame);
        } catch (Exception e) {
            throw new BadRequestResponse("Failed to create game: " + e.getMessage());
        }
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

        MoveValidity validity = player.currentGame.verifyMove(move.position, move.value);

        if (validity == MoveValidity.COMPLETED) {
            player.endTime = System.currentTimeMillis();
            game.status = GameStatus.COMPLETED;
            game.winnerId = player.id;
        }

        ctx.json(new MoveResult(validity));
    }

    public void getState(Context ctx) {
        String gameId = ctx.pathParam("gameId");

        Game game = games.get(gameId);
        if (game == null) {
            throw new NotFoundResponse("Game not found");
        }

        ctx.json(game);
    }

    public void getAll(Context ctx) {
        List<Game> gamesList = new ArrayList<>(games.values());
        ctx.json(gamesList);
    }

    // Helper class for move results
    private static class MoveResult {
        public MoveValidity validity;

        public MoveResult(MoveValidity validity) {
            this.validity = validity;
        }
    }
}