
library(ggplot2)
library(dplyr)
library(sf)
library(patchwork)
library(viridis)

getwd()

# Corrigé avec des barres obliques normales
setwd("C:/Users/USER/Desktop/ise math/s2/convexité et optimisation/optimisation-reseau/optimisation")

getwd()



# Charger les données
data <- read.csv("data.csv")

# Définir les noms des colonnes
noms_variables <- c(
  "Région",
  "Couverture_2G_Orange",
  "Couverture_2G_Free",
  "Couverture_2G_Expresso",
  "Couverture_3G_Orange",
  "Couverture_3G_Free",
  "Couverture_3G_Expresso",
  "Couverture_4G_Orange",
  "Couverture_4G_Free"
)
colnames(data) <- noms_variables

# Corriger les noms des régions pour correspondre au shapefile
data <- data %>%
  mutate(
    Région = case_when(
      Région == "DAKAR" ~ "Dakar",
      Région == "DIOURBEL" ~ "Diourbel",
      Région == "FATICK" ~ "Fatick",
      Région == "KAFFRINE" ~ "Kaffrine",
      Région == "KAOLACK" ~ "Kaolack",
      Région == "KEDOUGOU" ~ "Kédougou",
      Région == "KOLDA" ~ "Kolda",
      Région == "LOUGA" ~ "Louga",
      Région == "MATAM" ~ "Matam",
      Région == "SAINT-LOUIS" ~ "Saint-Louis",
      Région == "SEDHIOU" ~ "Sédhiou",
      Région == "TAMBACOUNDA" ~ "Tambacounda",
      Région == "THIES" ~ "Thiès",
      Région == "ZIGUINCHOR" ~ "Ziguinchor",
      TRUE ~ as.character(Région)
    )
  )

# Enregistrer les données
write.csv(data, "data_coverage.csv", row.names = FALSE)

# Calculer la couverture moyenne par opérateur pour chaque technologie
coverage_avg <- data %>%
  group_by(Région) %>%
  summarise(
    Couverture_2G = mean(c(Couverture_2G_Orange, Couverture_2G_Free, Couverture_2G_Expresso), na.rm = TRUE),
    Couverture_3G = mean(c(Couverture_3G_Orange, Couverture_3G_Free, Couverture_3G_Expresso), na.rm = TRUE),
    Couverture_4G = mean(c(Couverture_4G_Orange, Couverture_4G_Free), na.rm = TRUE)
  )

# Charger le shapefile du Sénégal
map_data <- st_read("data/shapefile/gadm41_SEN_1.shp")

# Fusionner les données avec le shapefile
map_data <- map_data %>% left_join(coverage_avg, by = c("NAME_1" = "Région"))

# Carte pour 2G
map_2g <- ggplot(data = map_data) +
  geom_sf(aes(fill = Couverture_2G), color = "white", linewidth = 0.5) +
  geom_sf_text(aes(label = ifelse(NAME_1 %in% c("Tambacounda", "Kédougou", "Matam"), NAME_1, "")), 
               size = 3, fontface = "bold", color = "black") +
  scale_fill_viridis_c(option = "plasma", limits = c(0, 100), labels = function(x) paste0(x, "%"), 
                       name = "Couverture 2G (%)") +
  labs(title = "Couverture Réseau 2G Moyenne par Région",
       caption = "Source : Données simulées, 2024") +
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    legend.position = "bottom",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    plot.caption = element_text(size = 8, hjust = 1),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank()
  )

# Afficher la carte
map_2g

# Enregistrer
ggsave("carte_couverture_2G.png", plot = map_2g, width = 8, height = 6)

# Carte pour 3G
map_3g <- ggplot(data = map_data) +
  geom_sf(aes(fill = Couverture_3G), color = "white", linewidth = 0.5) +
  geom_sf_text(aes(label = ifelse(NAME_1 %in% c("Tambacounda", "Kédougou", "Matam"), NAME_1, "")), 
               size = 3, fontface = "bold", color = "black") +
  scale_fill_viridis_c(option = "plasma", limits = c(0, 100), labels = function(x) paste0(x, "%"), 
                       name = "Couverture 3G (%)") +
  labs(title = "Couverture Réseau 3G Moyenne par Région",
       caption = "Source : Données simulées, 2024") +
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    legend.position = "bottom",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    plot.caption = element_text(size = 8, hjust = 1),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank()
  )

# Afficher la carte
map_3g

# Enregistrer
ggsave("carte_couverture_3G.png", plot = map_3g, width = 8, height = 6)

# Carte pour 4G
map_4g <- ggplot(data = map_data) +
  geom_sf(aes(fill = Couverture_4G), color = "white", linewidth = 0.5) +
  geom_sf_text(aes(label = ifelse(NAME_1 %in% c("Tambacounda", "Kédougou", "Matam"), NAME_1, "")), 
               size = 3, fontface = "bold", color = "black") +
  scale_fill_viridis_c(option = "plasma", limits = c(0, 100), labels = function(x) paste0(x, "%"), 
                       name = "Couverture 4G (%)") +
  labs(title = "Couverture Réseau 4G Moyenne par Région",
       caption = "Source : Données simulées, 2024") +
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    legend.position = "bottom",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    plot.caption = element_text(size = 8, hjust = 1),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank()
  )

# Afficher la carte
map_4g

# Enregistrer
ggsave("carte_couverture_4G.png", plot = map_4g, width = 8, height = 6)

# Carte combinée avec patchwork
combined_maps <- map_2g / map_3g / map_4g

# Afficher la carte combinée
combined_maps

# Enregistrer
ggsave("carte_couverture_combined.png", plot = combined_maps, width = 8, height = 12)


# Données actualisées
regions_data <- data.frame(
  Region = c("Tambacounda", "Kédougou", "Matam"),
  Population = c(988193, 245288, 833656),
  Densite = c(13, 8, 28),
  Couverture = c(45, 35, 50)
)

# Format long
regions_long <- pivot_longer(regions_data, 
                             cols = c(Population, Densite, Couverture),
                             names_to = "Indicateur",
                             values_to = "Valeur") %>%
  mutate(
    Indicateur = factor(Indicateur, levels = c("Population", "Densite", "Couverture"),
                        labels = c("Population", "Densité (hab/km²)", "Couverture (%)")),
    Label = case_when(
      Indicateur == "Population" ~ format(Valeur, big.mark = " ", scientific = FALSE),
      Indicateur == "Densité (hab/km²)" ~ as.character(round(Valeur, 1)),
      Indicateur == "Couverture (%)" ~ paste0(round(Valeur, 1), "%")
    )
  )

# Visualisation
ggplot(regions_long, aes(x = Region, y = Valeur, fill = Region)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.3), width = 0.7) +
  geom_text(aes(label = Label), 
            position = position_dodge(width = 0.3), 
            vjust = -0.5, size = 3.5, fontface = "bold") +
  facet_wrap(~ Indicateur, scales = "free_y", ncol = 3) +
  scale_fill_viridis_d(option = "D", begin = 0.2, end = 0.8) +
  labs(title = "Indicateurs Clés des Régions Cibles",
       subtitle = "Source : ANSD (Population), estimations (Densité, Couverture), 2024",
       x = "Région",
       y = "Valeur",
       caption = "Note : Couverture basée sur la moyenne des opérateurs") +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    plot.caption = element_text(size = 8, hjust = 1),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 11, face = "bold"),
    strip.text = element_text(size = 10, face = "bold", color = "#3A3A3A"),
    strip.background = element_rect(fill = "grey95", color = "grey80"),
    legend.position = "none"
  )

# Enregistrer le graphique
ggsave("indicateurs_regions_cibles.png", width = 8, height = 5)


