package kata5.infrastructure.adapters;

public record WebserviceConfig(
        String id,
        String host,
        int port,
        String consul,
        String serviceName
) {
    public WebserviceConfig {
        if (id == null || id.isBlank()
                || host == null || host.isBlank()
                || consul == null || consul.isBlank()
                || serviceName == null || serviceName.isBlank()) {
            throw new IllegalArgumentException("Arguments must not be blank");
        }

        if (port < 1 || port > 65535) {
            throw new IllegalArgumentException("Port must be between 1 and 65535");
        }
    }
}
