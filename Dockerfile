# syntax=docker/dockerfile:1

# --- Stage 1: extract the tar.gz to get the JAR ---
FROM busybox:1.36.1 AS extract
WORKDIR /work

# Path to your tar.gz inside the build context (override at build with --build-arg)
ARG TAR_FILE=target/*.tar.gz

# Copy and extract
COPY ${TAR_FILE} /work/app.tar.gz
RUN mkdir /work/unpack \
 && tar -xzf /work/app.tar.gz -C /work/unpack \
 && JAR_PATH="$(find /work/unpack -type f -name '*.jar' | head -n 1)" \
 && [ -n "$JAR_PATH" ] \
 && mkdir -p /out \
 && cp "$JAR_PATH" /out/app.jar

# --- Stage 2: minimal runtime (no shell), runs as non-root ---
FROM gcr.io/distroless/java17-debian12:nonroot
WORKDIR /app

COPY --from=extract /out/app.jar /app/app.jar

ENV SPRING_PROFILES_ACTIVE=default \
    SERVER_PORT=8080
EXPOSE 8080

ENTRYPOINT ["java","-jar","/app/app.jar"]