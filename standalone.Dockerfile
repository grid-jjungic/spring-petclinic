# syntax=docker/dockerfile:1

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

RUN groupadd -g 10001 usergroup && \
    useradd -u 10001 -g usergroup -m appuser

COPY --chown=appuser:usergroup target/spring-petclinic-*.jar app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT [ "java", "-jar", "app.jar" ]
