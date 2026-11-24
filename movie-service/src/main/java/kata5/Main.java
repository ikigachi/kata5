package kata5;

import kata5.application.domain.model.Movie;
import kata5.infrastructure.adapters.Webservice;
import kata5.infrastructure.adapters.WebserviceConfig;

import java.util.List;

public class Main {

    public static void main(String[] args) throws Exception {
        if (args.length != 5) {
            throw new IllegalArgumentException(
                    "Usage: <id> <host> <port> <consul-url> <service-name>"
            );
        }

        WebserviceConfig config = new WebserviceConfig(
                args[0],
                args[1],
                Integer.parseInt(args[2]),
                args[3],
                args[4]
        );

        Webservice webservice = new Webservice(config, movies());
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