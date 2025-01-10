package ch.heigvd.dai.game;

import ch.heigvd.dai.sudoku.Sudoku;
import ch.heigvd.dai.sudoku.enums.Difficulty;
import ch.heigvd.dai.sudoku.enums.GameType;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class Game {
    public String id;
    public GameType type;
    public GameStatus status;
    public Difficulty difficulty;
    public String initialGrid; // Store as string representation
    public List<Player> players;
    public String winnerId;
    public Sudoku sudoku; // Reference to the Sudoku implementation

    public Game() {
        this.id = UUID.randomUUID().toString();
        this.players = new ArrayList<>();
        this.status = GameStatus.WAITING;
    }
}