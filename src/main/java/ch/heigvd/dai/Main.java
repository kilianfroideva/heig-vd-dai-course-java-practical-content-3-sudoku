package ch.heigvd.dai;

import io.javalin.Javalin;

public class Main {
  public static final int PORT = 1236;

  public static void main(String[] args) {
    Javalin app = Javalin.create();

    app.get("/", ctx -> ctx.result("Hello, world!"));

    app.start(PORT);
  }
}