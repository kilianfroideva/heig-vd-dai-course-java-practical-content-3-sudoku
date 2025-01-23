FROM maven:3.9.6-eclipse-temurin-21-jammy AS build
WORKDIR /app
COPY . .
RUN mvn clean package
 
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/target/sudoku-1.0-SNAPSHOT.jar app.jar
EXPOSE 1236
CMD ["java", "-jar", "app.jar"]