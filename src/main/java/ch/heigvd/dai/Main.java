package ch.heigvd.dai;

import ch.heigvd.dai.game.*;
import io.javalin.Javalin;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class Main {
  public static final int PORT = 1236;

  public static void main(String[] args) {
    Javalin app = Javalin.create(config -> {
      config.jetty.defaultHost = "0.0.0.0";
      config.bundledPlugins.enableCors(cors -> {
        cors.addRule(it -> {
          it.allowHost("https://localhost:1236", "http://localhost:1236", "http://localhost");
        });
      });
    });

    // Add global error handler
    app.exception(Exception.class, (e, ctx) -> {
        ctx.status(500);
        ctx.json(Map.of("error", e.getMessage()));
        e.printStackTrace();
    });

    ConcurrentHashMap<String, Game> games = new ConcurrentHashMap<>();
    GameController gameController = new GameController(games);

    // CRUD routes
    app.post("/api/games", gameController::create);           // Create
    app.get("/api/games", gameController::getAll);           // Read (all)
    app.get("/api/games/{id}", gameController::getOne);      // Read (one)
    app.put("/api/games/{id}", gameController::update);      // Update
    app.delete("/api/games/{id}", gameController::delete);   // Delete

    // Multiplayer routes
    app.post("/api/games/{gameId}/join", gameController::join);           // Join game
    app.post("/api/games/{gameId}/players/{playerId}/moves", gameController::makeMove);  // Make move

    app.start(PORT);
  }
}
