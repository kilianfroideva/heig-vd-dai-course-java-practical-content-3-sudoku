package ch.heigvd.dai.game;

import ch.heigvd.dai.sudoku.Sudoku;
import ch.heigvd.dai.sudoku.enums.GameType;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.*;

public class Game {
    public String id;

    @JsonProperty("type")
    public GameType type;

    @JsonProperty("difficulty")
    public Difficulty difficulty;

    @JsonProperty("status")
    public GameStatus status;

    public String initialGrid;
    public String solutionGrid;
    public List<Player> players = new ArrayList<>();
    public String winnerId;
    public List<Move> moves = new ArrayList<>();
    public Map<String, String> cellOwners = new HashMap<>();
    public Map<String, Integer> playerScores = new HashMap<>();

    @JsonIgnore
    private Sudoku sudoku;

    // Default constructor for Jackson
    public Game() {}

    // Getters and setters
    public GameType getType() {
        return type;
    }

    public void setType(GameType type) {
        this.type = type;
    }

    public Difficulty getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(Difficulty difficulty) {
        this.difficulty = difficulty;
    }

    @JsonIgnore
    public Sudoku getSudoku() {
        return sudoku;
    }

    @JsonIgnore
    public void setSudoku(Sudoku sudoku) {
        this.sudoku = sudoku;
    }
}
