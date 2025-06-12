library(dplyr)
library(tidyverse)

data <- read.csv("data.csv")
#arrange les noms des Variables
colnames(data)
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
# Après avoir chargé vos données
colnames(data) <- noms_variables 
#enregistre les données 
write.csv(data, "data_coverage.csv", row.names = FALSE)
#je veux faire une carte pour visualiser la couverture 2G, 3G et 4G par région

library(ggplot2)
library(ggmap)
library(sf)
# Charger les données géographiques
map_data <- st_read("data/shapefile/gadm41_SEN_1.shp") # Remplacez par le chemin vers votre fichier shapefile
# Fusionner les données de couverture avec les données géographiques

library(dplyr)
library(stringr)

# 1. D'abord, vérifiez et corrigez les noms de colonnes
colnames(data) <- make.names(colnames(data), unique = TRUE)

# 2. Ensuite, appliquez votre transformation
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
      TRUE ~ as.character(Région)  # Garde la valeur originale si aucune correspondance
    )
  )

# Vérification
head(data$Région)
coverage_avg <- data %>%
  group_by(Région) %>%
  summarise(
    Couverture_2G = mean(Couverture_2G_Orange, na.rm = TRUE),
    Couverture_3G = mean(Couverture_3G_Orange, na.rm = TRUE),
    Couverture_4G = mean(Couverture_4G_Orange, na.rm = TRUE)
  )


map_data <- map_data %>%left_join(coverage_avg, by = c("NAME_1" = "Région"))
# Créer la carte
ggplot(data = map_data) +
  geom_sf(aes(fill = Couverture_2G), color = "white") +
  scale_fill_gradient(low = "yellow", high = "red", na.value = "grey50") +
  labs(title = "Couverture 2G par Région", fill = "Couverture 2G (%)") +
  theme_minimal() +
  theme(legend.position = "bottom")
# Enregistrer la carte


ggsave("carte_couverture_2G.png", width = 10, height = 8)
# Répéter pour 3G et 4G
ggplot(data = map_data) +
  geom_sf(aes(fill = Couverture_3G), color = "white") +
  scale_fill_gradient(low = "yellow", high = "red", na.value = "grey50") +
  labs(title = "Couverture 3G par Région", fill = "Couverture 3G (%)") +
  theme_minimal() +
  theme(legend.position = "bottom")
# Enregistrer la carte
ggsave("carte_couverture_3G.png", width = 10, height = 8)
ggplot(data = map_data) +
  geom_sf(aes(fill = Couverture_4G), color = "white") +
  scale_fill_gradient(low = "yellow", high = "red", na.value = "grey50") +
  labs(title = "Couverture 4G par Région", fill = "Couverture 4G (%)") +
  theme_minimal() +
  theme(legend.position = "bottom")
# Enregistrer la carte
ggsave("carte_couverture_4G.png", width = 10, height = 8)
# Pour afficher les cartes dans RStudio
library(gridExtra)
grid.arrange(
  ggplot(data = map_data) +
    geom_sf(aes(fill = Couverture_2G), color = "white") +
    scale_fill_gradient(low = "yellow", high = "red", na.value = "grey50") +
    labs(title = "Couverture 2G par Région", fill = "Couverture 2G (%)") +
    theme_minimal() +
    theme(legend.position = "bottom"),
  
  ggplot(data = map_data) +
    geom_sf(aes(fill = Couverture_3G), color = "white") +
    scale_fill_gradient(low = "yellow", high = "red", na.value = "grey50") +
    labs(title = "Couverture 3G par Région", fill = "Couverture 3G (%)") +
    theme_minimal() +
    theme(legend.position = "bottom"),
  
  ggplot(data = map_data) +
    geom_sf(aes(fill = Couverture_4G), color = "white") +
    scale_fill_gradient(low = "yellow", high = "red", na.value = "grey50") +
    labs(title = "Couverture 4G par Région", fill = "Couverture 4G (%)") +
    theme_minimal() +
    theme(legend.position = "bottom"),
  
  ncol = 1
)
# Enregistrer les cartes combinées
ggsave("carte_couverture_combined.png", width = 10, height = 24)
# Pour afficher les cartes dans RStudio



library(ggplot2)
library(tidyr)
library(dplyr)
library(viridis)

# Données actualisées
regions_data <- data.frame(
  Region = c("Tambacounda", "Kédougou", "Matam"),
  Population = c(988193, 245288, 833656),  # MISE À JOUR
  Densite = c(13, 8, 28),
  Couverture = c(45, 35, 50)
)

# Format long
regions_long <- pivot_longer(regions_data, 
                             cols = c(Population, Densite, Couverture),
                             names_to = "Indicateur",
                             values_to = "Valeur")

# Visualisation
ggplot(regions_long, aes(x = Region, y = Valeur, fill = Region)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9), width = 0.7) +
  facet_wrap(~Indicateur, scales = "free_y") +
  geom_text(aes(label = format(Valeur, big.mark = " ")), 
            position = position_dodge(width = 0.9), 
            vjust = -0.5, size = 3.5) +
  labs(title = "Indicateurs clés des régions cibles",
       subtitle = "Source : ANSD (Population), autres estimations",
       x = "Région",
       y = "Valeur") +
  scale_fill_viridis_d(option = "D") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none",
        strip.text = element_text(face = "bold", color = "#3A3A3A"))
# Enregistrer le graphique
ggsave("indicateurs_regions_cibles.png", width = 10, height = 6)