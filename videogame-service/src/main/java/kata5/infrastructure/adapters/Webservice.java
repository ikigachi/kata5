package kata5.infrastructure.adapters;

import com.google.gson.Gson;
import io.javalin.Javalin;
import io.javalin.config.JavalinConfig;
import io.javalin.http.Context;
import kata5.application.domain.model.Videogame;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;

public final class Webservice {
    private final WebserviceConfig config;
    private final List<Videogame> videogames;
    private final Gson gson = new Gson();

    public Webservice(WebserviceConfig config, List<Videogame> videogames) {
        this.config = config;
        this.videogames = List.copyOf(videogames);
    }

    public void start() throws IOException, InterruptedException {
        Javalin app = Javalin.create(this::init)
                .start(config.host(), config.port());

        try {
            register();
            System.out.println(
                    "Registered: " + config.id()
                            + " as " + config.serviceName()
                            + " at " + host() + ":" + config.port()
            );
        } catch (IOException | InterruptedException | RuntimeException failure) {
            app.stop();
            throw failure;
        }
    }

    private void init(JavalinConfig config) {
        config.routes.get("/", this::videogames);
        config.routes.get("/health", this::health);
    }

    private void health(Context context) {
        context.result("OK");
    }

    private void videogames(Context context) {
        context.header("X-Node", config.id());
        context.contentType("application/json");
        context.result(gson.toJson(videogames));
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
        return HttpRequest.newBuilder(URI.create(config.consul()).resolve("/v1/agent/service/register"))
                .timeout(Duration.ofSeconds(5))
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(json))
                .build();
    }

    private String host() {
        return isLocalHost() ? "host.docker.internal" : config.host();
    }

    private boolean isLocalHost() {
        return "localhost".equals(config.host()) ||
                "127.0.0.1".equals(config.host()) ||
                "0.0.0.0".equals(config.host());
    }

    private String healthUrl() {
        return "http://" + host() + ":" + config.port() + "/health";
    }

    private String json() {
        return gson.toJson(Map.of(
                "ID", config.id(),
                "Name", config.serviceName(),
                "Address", host(),
                "Port", config.port(),
                "Check", Map.of(
                        "HTTP", healthUrl(),
                        "Interval", "5s",
                        "Timeout", "2s",
                        "DeregisterCriticalServiceAfter", "10m"
                )
        ));
    }
}
