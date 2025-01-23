package ch.heigvd.dai.game;

import ch.heigvd.dai.sudoku.Sudoku;
import ch.heigvd.dai.sudoku.enums.GameType;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.util.*;

public class Game {
    public int size;
    public String id;
    public Difficulty difficulty;
    public GameStatus status;
    public String initialGrid;
    public List<Player> players = new ArrayList<>();
    public String winnerId;
    public List<Move> moves = new ArrayList<>();
    public Map<String, String> cellOwners = new HashMap<>();
    public Map<String, Integer> playerScores = new HashMap<>();
    public GameType type;

    @JsonIgnore
    private Sudoku sudoku;

    // Constructor
    public Game() {}

    public Game(int size, Difficulty difficulty) {
        this.size = size;
        this.difficulty = difficulty;
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
