package app.time2wish.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "app_settings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppSetting {
    
    @Id
    @Column(name = "setting_key", nullable = false, length = 100)
    private String key;
    
    @Column(name = "setting_value", nullable = false, length = 255)
    private String value;
    
    @Column(name = "description", length = 255)
    private String description;
    
    @Column(name = "type", nullable = false, length = 50)
    private String type; // BOOLEAN, INTEGER, STRING
}
