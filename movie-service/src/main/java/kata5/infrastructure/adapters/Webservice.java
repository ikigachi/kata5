package kata5.infrastructure.adapters;

import com.google.gson.Gson;
import io.javalin.Javalin;
import io.javalin.config.JavalinConfig;
import io.javalin.http.Context;
import kata5.application.domain.model.Movie;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;

public final class Webservice {
    private final String id;
    private final String host;
    private final int port;
    private final String consul;
    private final String serviceName;
    private final List<Movie> movies;
    private final Gson gson = new Gson();

    public Webservice(String id, String host, int port, String consul, String serviceName, List<Movie> movies) {
        this.id = id;
        this.host = host;
        this.port = port;
        this.consul = consul;
        this.serviceName = serviceName;
        this.movies = List.copyOf(movies);
    }

    public void start() throws IOException, InterruptedException {
        Javalin app = Javalin.create(this::init).start(host, port);
        try {
            register();
            System.out.println("Registered: " + id + " as " + serviceName + " at " + host() + ":" + port);
        } catch (IOException | InterruptedException | RuntimeException failure) {
            app.stop();
            throw failure;
        }
    }

    private void init(JavalinConfig config) {
        config.routes.get("/", this::movies);
        config.routes.get("/health", this::health);
    }

    private void health(Context context) {
        context.result("OK");
    }

    private void movies(Context context) {
        context.header("X-Node", id);
        context.contentType("application/json");
        context.result(gson.toJson(movies));
    }

    private void register() throws IOException, InterruptedException {
        try (HttpClient client = client()) {
            HttpResponse<String> response = client.send(requestWith(json()), HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() / 100 != 2) {
                throw new IOException("Consul rejected registration (HTTP " + response.statusCode() + "): " + response.body());
            }
        }
    }

    private static HttpClient client() {
        return HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(3))
                .build();
    }

    private HttpRequest requestWith(String json) {
        return HttpRequest.newBuilder(URI.create(consul).resolve("/v1/agent/service/register"))
                .timeout(Duration.ofSeconds(5))
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(json))
                .build();
    }

    private String host() {
        return isLocalHost() ? "host.docker.internal" : host;
    }

    private boolean isLocalHost() {
        return "localhost".equals(host) ||
                "127.0.0.1".equals(host) ||
                "0.0.0.0".equals(host);
    }

    private String healthUrl() {
        return "http://" + host() + ":" + port + "/health";
    }

    private String json() {
        return gson.toJson(Map.of(
                "ID", id,
                "Name", serviceName,
                "Address", host(),
                "Port", port,
                "Check", Map.of(
                        "HTTP", healthUrl(),
                        "Interval", "5s",
                        "Timeout", "2s",
                        "DeregisterCriticalServiceAfter", "10m"
                )
        ));
    }
}
