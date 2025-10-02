# ---- build stage (Maven) ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY . .
RUN mvn -B -DskipTests package

# ---- runtime stage ----
FROM eclipse-temurin:21-jre
WORKDIR /app

# Copy Quarkus layout if present, else copy a single JAR
# (both are produced by `mvn package`)
RUN mkdir -p /app
COPY --from=build /workspace/target/quarkus-app/ /app/quarkus-app/ 2>/dev/null || true
COPY --from=build /workspace/target/*-runner.jar /app/app.jar 2>/dev/null || true
COPY --from=build /workspace/target/*SNAPSHOT.jar /app/app.jar 2>/dev/null || true

# Simple launcher: prefer Quarkus layout if present
CMD ["/bin/sh","-lc","\
  if [ -f /app/quarkus-app/quarkus-run.jar ]; then \
    exec java ${JAVA_OPTS} -jar /app/quarkus-app/quarkus-run.jar; \
  elif [ -f /app/app.jar ]; then \
    exec java ${JAVA_OPTS} -jar /app/app.jar; \
  else \
    echo 'No runnable JAR found in /app'; exit 1; \
  \
"]
EXPOSE 8080
