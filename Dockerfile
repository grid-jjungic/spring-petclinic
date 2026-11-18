# syntax=docker/dockerfile:1

# Builder image
FROM bellsoft/liberica-openjdk-alpine:21 AS builder
WORKDIR /build

ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar /build/jmx_prometheus_javaagent.jar

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
COPY --chown=appuser:usergroup --from=builder /build/jmx_prometheus_javaagent.jar jmx_prometheus_javaagent.jar
COPY --chown=appuser:usergroup jmx-config.yaml jmx-config.yaml

USER appuser

EXPOSE 8080 8081

ENTRYPOINT ["sh", "-c", "java -javaagent:/app/jmx_prometheus_javaagent.jar=8081:/app/jmx-config.yaml -jar app.jar | tee /app/app.log"]
