package ch.heigvd.dai.game;

public class Move {
    public String position; // e.g., "A1", "B2"
    public String value;    // The value to place

    public Move() {
        // Empty constructor for serialization/deserialization
    }
}
