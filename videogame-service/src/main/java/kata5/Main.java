package kata5;

import kata5.application.domain.model.Videogame;
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
        Webservice webservice = new Webservice(args[0], args[1], port, args[3], args[4], videogames());
        webservice.start();
    }

    private static List<Videogame> videogames() {
        return List.of(
                new Videogame(1, "Portal 2", 2011),
                new Videogame(2, "Hollow Knight", 2017),
                new Videogame(3, "Stardew Valley", 2016)
        );
    }
}
