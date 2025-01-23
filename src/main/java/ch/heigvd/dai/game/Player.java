package ch.heigvd.dai.game;

import ch.heigvd.dai.sudoku.Sudoku;

public class Player {
    public String id;
    public String name;
    public Sudoku currentGame; // Player's current game state
    public long startTime;
    public long endTime;

    public Player() {
        // Empty constructor for serialization/deserialization
    }
}