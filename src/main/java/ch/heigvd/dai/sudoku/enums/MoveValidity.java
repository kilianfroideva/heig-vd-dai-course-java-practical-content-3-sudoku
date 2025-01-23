package ch.heigvd.dai.sudoku.enums;

import com.fasterxml.jackson.annotation.JsonFormat;

@JsonFormat(shape = JsonFormat.Shape.STRING)
public enum MoveValidity {
    CORRECT_MOVE,
    WRONG_MOVE,
    ALREADY_PLACED,
    OUT_OF_BOUNDS,
    INVALID_FORMAT,
    COMPLETED
}
