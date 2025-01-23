package ch.heigvd.dai.game;

public class Move {
    public String position; // e.g., "A1", "B2"
    public String value;    // The value to place (as string to support both 9x9 and 16x16)

    public Move() {
        // Empty constructor for serialization/deserialization
    }

    // Add getters and setters for better JSON handling
    public String getPosition() { return position; }
    public void setPosition(String position) { this.position = position; }
    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }
}
