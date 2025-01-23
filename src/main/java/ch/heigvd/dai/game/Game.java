package ch.heigvd.dai.game;
import ch.heigvd.dai.sudoku.enums.GameType;
import com.fasterxml.jackson.annotation.JsonIgnore;

import ch.heigvd.dai.sudoku.Sudoku;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class Game {
    // Track all moves made in the game
    private List<Move> moves;
    // Track which cells are filled by which player
    private Map<String, String> cellOwners; // Format: "A1" -> "playerId"

    // Track player scores (number of correct moves)
    private Map<String, Integer> playerScores;
    @JsonProperty("type")
    public GameType type;

    @JsonProperty("difficulty")
    public Boolean difficulty;

    @JsonIgnore
    private transient Sudoku sudoku;
    public GameStatus status;
    public String id;

    // Get grid data directly for serialization
    public int[][] getGrid() {
        int size = sudoku.getSize();
        int[][] gridData = new int[size][size];
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                gridData[i][j] = sudoku.getValue(i, j);
            }
        }
        return gridData;
    }

    public String initialGrid; // Store as string representation
    public List<Player> players;
    public String winnerId;


    // Serializable game state that represents the current sudoku grid
    public String getCurrentGridState() {
        if (sudoku == null) return initialGrid;
        StringBuilder state = new StringBuilder();
        int size = sudoku.getSize();
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                state.append(sudoku.intToHex(sudoku.getValue(i, j)));
            }
        }
        return state.toString();
    }

    public Game() {
        this.id = UUID.randomUUID().toString();
        this.players = new ArrayList<>();
        this.status = GameStatus.WAITING;
        this.moves = new ArrayList<>();
        this.cellOwners = new HashMap<>();
        this.playerScores = new HashMap<>();
    }

    public void setSudoku(Sudoku sudoku) {
        this.sudoku = sudoku;
    }
}
