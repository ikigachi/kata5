package kata5;

import kata5.application.domain.model.Book;
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
        Webservice webservice = new Webservice(args[0], args[1], port, args[3], args[4], books());
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
