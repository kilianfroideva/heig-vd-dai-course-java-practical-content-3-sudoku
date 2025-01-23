package ch.heigvd.dai.sudoku.fileManagers;
import ch.heigvd.dai.sudoku.enums.Difficulty;

import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.Random;

public class Sudoku9x9FileManager {

    public String getRandomPuzzle(Difficulty difficulty) throws IOException {
        // Define the base path for the dataset
        String basePath = "dataset/sudoku-exchange-puzzle-bank/" + switch (difficulty) {
            case EASY -> "easy.txt";
            case MEDIUM -> "medium.txt";
            case HARD -> "hard.txt";
            case DIABOLICAL -> "diabolical.txt";
        };

        try (RandomAccessFile file = new RandomAccessFile(basePath, "r")) {
            // Get the length of the file
            long fileLength = file.length();

            // Generate a random position in the file
            Random random = new Random();
            long randomPosition = (long) (random.nextDouble() * fileLength);

            // Seek to the random position
            file.seek(randomPosition);

            // Ensure we start reading from the beginning of a line
            if (randomPosition != 0) {
                file.readLine(); // Skip the current partial line
            }

            // Read the next full line
            String randomLine = file.readLine();

            // Close the file
            file.close();
            if (randomLine == null) {
                throw new IOException("Could not read puzzle from file");
            }
            if (randomLine == null) {
                throw new IOException("Could not read puzzle from file");
            }
            return randomLine.substring(13, 13+81);
        } catch (IOException e) {
            throw new IOException("Error reading puzzle: " + e.getMessage(), e);
        }
    }
}
