FROM maven:3.9.6-eclipse-temurin-21-jammy AS build
WORKDIR /build
COPY pom.xml .
COPY dataset ./dataset
COPY src ./src
RUN mvn clean package

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /build/target/sudoku-1.0-SNAPSHOT.jar ./app.jar
COPY --from=build /build/dataset ./dataset

EXPOSE 1236
CMD ["java", "-jar", "app.jar"]
