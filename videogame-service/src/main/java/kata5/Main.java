package kata5;

import kata5.application.domain.model.Videogame;
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

        Webservice webservice = new Webservice(config, videogames());
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
