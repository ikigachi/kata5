#!/usr/bin/env bash
set -e
docker compose up -d --wait
java -jar ../movie-service/target/movie-service-1.0.jar movie-v1-a 0.0.0.0 8081 http://localhost:8500 movie_service_v1 &
java -jar ../movie-service/target/movie-service-1.0.jar movie-v1-b 0.0.0.0 8082 http://localhost:8500 movie_service_v1 &
java -jar ../movie-service/target/movie-service-1.0.jar movie-v2-a 0.0.0.0 8083 http://localhost:8500 movie_service_v2 &
java -jar ../movie-service/target/movie-service-1.0.jar movie-v2-b 0.0.0.0 8084 http://localhost:8500 movie_service_v2 &
wait
