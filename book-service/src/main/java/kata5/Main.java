package kata5;

import kata5.application.domain.model.Book;
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

        Webservice webservice = new Webservice(config, books());
        webservice.start();
    }

    private static List<Book> books() {
        return List.of(
                new Book(1, "The Hobbit", "J. R. R. Tolkien"),
                new Book(2, "1984", "George Orwell"),
                new Book(3, "Dune", "Frank Herbert")
        );
    }
}
