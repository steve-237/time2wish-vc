package app.time2wish.storage;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class StorageInitializer implements CommandLineRunner {

    private final StorageService storageService;

    public StorageInitializer(StorageService storageService) {
        this.storageService = storageService;
    }

    @Override
    public void run(String... args) throws Exception {
        storageService.init();
    }
}
