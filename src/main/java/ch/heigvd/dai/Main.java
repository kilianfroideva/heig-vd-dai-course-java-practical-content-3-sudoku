package ch.heigvd.dai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import ch.heigvd.dai.game.*;
import io.javalin.Javalin;
import java.util.concurrent.ConcurrentHashMap;

public class Main {
  public static final int PORT = 1236;

  public static void main(String[] args) {
    ObjectMapper objectMapper = new ObjectMapper()
        .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS);

    Javalin app = Javalin.create();

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
