package kata5;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class Main {
    private static final String address = "http://localhost:8080";

    public static void main(String[] args) throws InterruptedException {
        try (HttpClient client = client()) {
            while (true) {
                for (int version = 1; version <= 2; version++) {
                    HttpRequest request = request(version);
                    try {
                        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                        showResponse(response);
                    } catch (IOException failure) {
                        System.out.println("Route: " + request.uri().getPath() + " | Request failed: " + failure.getClass().getSimpleName());
                    }
                    Thread.sleep(100);
                }
            }
        }
    }

    private static void showResponse(HttpResponse<String> response) {
        String route = response.uri().getPath();
        if (response.statusCode() / 100 != 2) {
            System.out.println("Route: " + route + " | NGINX response " + response.statusCode());
        } else {
            String node = response.headers().firstValue("X-Node").orElse("unknown");
            System.out.println("Route: " + route + " | Node: " + node + " | Body: " + response.body());
        }
    }

    private static HttpRequest request(int version) {
        return HttpRequest.newBuilder(URI.create(address).resolve("/api/v" + version + "/videogames/"))
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();
    }

    private static HttpClient client() {
        return HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build();
    }
}
