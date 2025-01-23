package ch.heigvd.dai.sudoku.enums;

public enum GameType {
    SUDOKU_9X9(9),
    SUDOKU_16X16(16);

    private final int value;

    GameType(int size){
        this.value = size;
    }

    public int getSize(){
        return this.value;
    }
}