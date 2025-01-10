package ch.heigvd.dai;

import ch.heigvd.dai.game.*;
import io.javalin.Javalin;
import java.util.concurrent.ConcurrentHashMap;

public class Main {
  public static final int PORT = 1236;

  public static void main(String[] args) {
    Javalin app = Javalin.create();

    ConcurrentHashMap<String, Game> games = new ConcurrentHashMap<>();

    // Controllers
    GameController gameController = new GameController(games);

    // Game routes
    app.post("/games", gameController::create);
    app.post("/games/{gameId}/join", gameController::join);
    app.put("/games/{gameId}/players/{playerId}", gameController::makeMove);
    app.get("/games/{gameId}", gameController::getState);
    app.get("/games", gameController::getAll);

    app.start(PORT);
  }
}