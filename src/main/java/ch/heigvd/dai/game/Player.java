package ch.heigvd.dai.game;

import ch.heigvd.dai.sudoku.Sudoku;
import com.fasterxml.jackson.annotation.JsonIgnore;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class Player {
    public String id;
    public String name;
    @JsonIgnore
    public Sudoku currentGame;
    public long startTime;
    public long endTime;

    public Player() {
        // Empty constructor for serialization/deserialization
    }
}