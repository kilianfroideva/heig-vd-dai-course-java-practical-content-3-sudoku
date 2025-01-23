package ch.heigvd.dai.game;

public enum GameType {
    SUDOKU_9X9(9),
    SUDOKU_16X16(16);

    private final int size;

    GameType(int size) {
        this.size = size;
    }

    public int getSize() {
        return size;
    }
}
