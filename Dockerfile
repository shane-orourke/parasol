# ---- build stage ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY . .
RUN mvn -B -DskipTests package

# ---- runtime stage ----
FROM eclipse-temurin:21-jre
WORKDIR /app

# Copy the whole target then normalize (handles Quarkus fast-jar OR a single JAR)
COPY --from=build /workspace/target/ /app/target/

RUN set -eux; \
    # If Quarkus fast-jar exists, move it into place
    if [ -d /app/target/quarkus-app ]; then \
      mv /app/target/quarkus-app /app/quarkus-app; \
    fi; \
    # If there's a runner JAR or a regular JAR, move it
    if compgen -G "/app/target/*-runner.jar" > /dev/null; then \
      mv /app/target/*-runner.jar /app/app.jar; \
    elif compgen -G "/app/target/*.jar" > /dev/null; then \
      # pick the first jar as app.jar
      mv "$(ls -1 /app/target/*.jar | head -n1)" /app/app.jar; \
    fi; \
    rm -rf /app/target

EXPOSE 8080
CMD ["/bin/sh","-lc","\
  if [ -f /app/quarkus-app/quarkus-run.jar ]; then \
    exec java ${JAVA_OPTS} -jar /app/quarkus-app/quarkus-run.jar; \
  elif [ -f /app/app.jar ]; then \
    exec java ${JAVA_OPTS} -jar /app/app.jar; \
  else \
    echo 'No runnable JAR found in /app'; exit 1; \
  fi \
"]
