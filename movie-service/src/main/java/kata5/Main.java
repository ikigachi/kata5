package kata5;

import kata5.application.domain.model.Movie;
import kata5.infrastructure.adapters.Webservice;

import java.util.List;

public class Main {

    public static void main(String[] args) throws Exception {
        if (args.length != 5) {
            throw new IllegalArgumentException("Usage: <id> <host> <port> <consul-url> <service-name>");
        }
        for (String argument : args) {
            if (argument.isBlank()) {
                throw new IllegalArgumentException("Arguments must not be blank");
            }
        }
        int port = Integer.parseInt(args[2]);
        if (port < 1 || port > 65535) {
            throw new IllegalArgumentException("Port must be between 1 and 65535");
        }
        Webservice webservice = new Webservice(args[0], args[1], port, args[3], args[4], movies());
        webservice.start();
    }

    private static List<Movie> movies() {
        return List.of(
                new Movie(1, "The Matrix", 1999),
                new Movie(2, "Inception", 2010),
                new Movie(3, "Interstellar", 2014)
        );
    }
}
