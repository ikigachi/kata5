#!/usr/bin/env bash
set -e
docker compose up -d --wait
java -jar ../book-service/target/book-service-1.0.jar book-v1-a 0.0.0.0 8081 http://localhost:8500 book_service_v1 &
java -jar ../book-service/target/book-service-1.0.jar book-v1-b 0.0.0.0 8082 http://localhost:8500 book_service_v1 &
java -jar ../book-service/target/book-service-1.0.jar book-v2-a 0.0.0.0 8083 http://localhost:8500 book_service_v2 &
java -jar ../book-service/target/book-service-1.0.jar book-v2-b 0.0.0.0 8084 http://localhost:8500 book_service_v2 &
wait
