package app.time2wish.service;

import app.time2wish.model.AppSetting;
import app.time2wish.repository.AppSettingRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class SettingService {
    
    private final AppSettingRepository appSettingRepository;
    
    public static final String MAINTENANCE_MODE = "MAINTENANCE_MODE";
    public static final String ALLOW_REGISTRATION = "ALLOW_REGISTRATION";
    public static final String FREE_WISH_LIMIT = "FREE_WISH_LIMIT";
    public static final String MODULE_CHAT_ENABLED = "MODULE_CHAT_ENABLED";
    public static final String MODULE_AI_ENABLED = "MODULE_AI_ENABLED";
    public static final String MODULE_CAGNOTTE_ENABLED = "MODULE_CAGNOTTE_ENABLED";
    public static final String AMAZON_AFFILIATE_TAG = "AMAZON_AFFILIATE_TAG";

    public SettingService(AppSettingRepository appSettingRepository) {
        this.appSettingRepository = appSettingRepository;
    }

    @PostConstruct
    public void initDefaultSettings() {
        initSetting(MAINTENANCE_MODE, "false", "Activer le mode maintenance (Seuls les admins peuvent se connecter)", "BOOLEAN");
        initSetting(ALLOW_REGISTRATION, "true", "Autoriser l'inscription de nouveaux utilisateurs", "BOOLEAN");
        initSetting(FREE_WISH_LIMIT, "5", "Nombre d'essais gratuits pour la génération d'IA (par défaut)", "INTEGER");
        initSetting(MODULE_CHAT_ENABLED, "true", "Activer la fonctionnalité de Chat en temps réel (WebSockets)", "BOOLEAN");
        initSetting(MODULE_AI_ENABLED, "true", "Activer la génération de textes et d'images par IA", "BOOLEAN");
        initSetting(MODULE_CAGNOTTE_ENABLED, "true", "Activer le système de cagnottes et promesses de dons", "BOOLEAN");
        initSetting(AMAZON_AFFILIATE_TAG, "time2wish-21", "Tag d'affiliation Amazon pour la monétisation des cadeaux", "STRING");
    }

    private void initSetting(String key, String defaultValue, String description, String type) {
        if (!appSettingRepository.existsById(key)) {
            AppSetting setting = AppSetting.builder()
                    .key(key)
                    .value(defaultValue)
                    .description(description)
                    .type(type)
                    .build();
            appSettingRepository.save(setting);
        }
    }

    public List<AppSetting> getAllSettings() {
        return appSettingRepository.findAll();
    }

    public AppSetting getSetting(String key) {
        return appSettingRepository.findById(key).orElse(null);
    }
    
    public boolean getBooleanSetting(String key) {
        AppSetting setting = getSetting(key);
        return setting != null && "true".equalsIgnoreCase(setting.getValue());
    }
    
    public int getIntSetting(String key, int defaultValue) {
        AppSetting setting = getSetting(key);
        if (setting == null) return defaultValue;
        try {
            return Integer.parseInt(setting.getValue());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    public AppSetting updateSetting(String key, String value) {
        Optional<AppSetting> settingOpt = appSettingRepository.findById(key);
        if (settingOpt.isPresent()) {
            AppSetting setting = settingOpt.get();
            setting.setValue(value);
            return appSettingRepository.save(setting);
        }
        throw new IllegalArgumentException("Paramètre introuvable: " + key);
    }
}
