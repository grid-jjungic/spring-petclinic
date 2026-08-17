# syntax=docker/dockerfile:1

# Builder image
FROM bellsoft/liberica-openjdk-alpine:21 AS builder
WORKDIR /build

COPY --chmod=0755 mvnw mvnw
COPY .mvn/ .mvn/
COPY pom.xml .

RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw dependency:go-offline

COPY src/ src/

RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw package -DskipTests && cp target/spring-petclinic-*.jar app.jar


# Final image
FROM bellsoft/liberica-openjre-alpine:21 AS final
WORKDIR /app

RUN addgroup -g 10001 usergroup && \
    adduser -u 10001 -G usergroup -D appuser

COPY --chown=appuser:usergroup --from=builder /build/app.jar app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT [ "java", "-jar", "app.jar" ]
