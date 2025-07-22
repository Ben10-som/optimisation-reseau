# global.R

# Chargement des bibliothèques nécessaires
library(shiny)
library(shinydashboard)
library(leaflet)
library(DT)
library(plotly)
library(dplyr)
library(sf)
library(RColorBrewer)

# Source des modules
source("modules/mod_dashboard.R")
source("modules/mod_repartition.R")
source("modules/mod_antennes.R")
source("modules/mod_optimisation.R")
source("modules/mod_resultats.R")

# ===============================
# DONNÉES SIMULÉES DU SÉNÉGAL
# ===============================

# Régions du Sénégal avec coordonnées approximatives
regions_senegal <- data.frame(
  region = c("Dakar", "Thiès", "Diourbel", "Fatick", "Kaolack", "Kaffrine", 
             "Louga", "Saint-Louis", "Matam", "Tambacounda", "Kédougou", 
             "Kolda", "Sédhiou", "Ziguinchor"),
  lat = c(14.7167, 14.7886, 14.6544, 14.3344, 14.1372, 14.1069,
          15.6181, 16.0469, 15.6550, 13.7706, 12.5569,
          12.8939, 12.7089, 12.5681),
  lon = c(-17.4677, -16.9363, -16.2294, -16.1764, -16.0728, -15.5503,
          -15.6509, -16.4896, -13.2558, -13.6681, -12.1786,
          -14.9444, -15.5564, -16.2681),
  population = c(3732000, 2016000, 1498000, 714000, 960000, 566000,
                 896000, 908000, 563000, 681000, 197000,
                 447000, 452000, 549000)
)

# Données de couverture réseau par région (simulées)
couverture_reseau <- data.frame(
  region = rep(regions_senegal$region, 3),
  technologie = rep(c("2G", "3G", "4G"), each = 14),
  couverture_pct = c(
    # 2G (généralement plus étendu)
    95, 92, 88, 85, 87, 82, 80, 85, 65, 70, 60, 75, 72, 78,
    # 3G 
    85, 80, 75, 70, 72, 68, 65, 70, 45, 50, 40, 55, 52, 58,
    # 4G (plus concentré dans les zones urbaines)
    75, 70, 60, 55, 58, 50, 45, 55, 25, 30, 20, 35, 32, 38
  )
)

# Antennes existantes (données simulées)
set.seed(123)
antennes_existantes <- data.frame(
  id = 1:150,
  region = sample(regions_senegal$region, 150, replace = TRUE, 
                  prob = regions_senegal$population/sum(regions_senegal$population)),
  lat = runif(150, 12, 16.5),
  lon = runif(150, -17.5, -11.5),
  type = sample(c("2G", "3G", "4G"), 150, replace = TRUE),
  puissance = runif(150, 10, 100),
  frequence = sample(c(900, 1800, 2100, 2600), 150, replace = TRUE),
  cout = runif(150, 50000, 200000),
  operateur = sample(c("Orange", "Free", "Expresso"), 150, replace = TRUE)
)

# ===============================
# FONCTIONS D'OPTIMISATION
# ===============================

# Modèle de propagation de Friis simplifié
calculer_puissance_recue <- function(puissance_emise, distance, frequence, alpha = 2.5) {
  if (distance == 0) return(puissance_emise)
  # Formule simplifiée : Pr = Pt / (d^alpha * f^2)
  return(puissance_emise / (distance^alpha * (frequence/1000)^2))
}

# Calcul du SIR (Signal to Interference Ratio)
calculer_sir <- function(signal, interferences) {
  if (length(interferences) == 0 || sum(interferences) == 0) {
    return(Inf)
  }
  return(signal / sum(interferences))
}

# Fonction d'optimisation MADS simplifiée
optimiser_placement_mads <- function(n_antennes, budget, zone_lat, zone_lon) {
  # Simulation d'optimisation MADS
  positions <- data.frame(
    lat = runif(n_antennes, min(zone_lat), max(zone_lat)),
    lon = runif(n_antennes, min(zone_lon), max(zone_lon)),
    puissance = runif(n_antennes, 20, 80),
    frequence = sample(c(900, 1800, 2100), n_antennes, replace = TRUE)
  )
  
  # Calcul du coût total
  cout_total <- sum(positions$puissance * 1000 + runif(n_antennes, 30000, 60000))
  
  # Calcul de la couverture (simulé)
  couverture_pct <- min(95, 40 + n_antennes * 2)
  
  list(
    positions = positions,
    cout_total = cout_total,
    couverture = couverture_pct,
    sir_moyen = runif(1, 10, 25)
  )
}

# Recherche tabou pour l'optimisation des fréquences
optimiser_frequences_tabou <- function(positions, iterations = 50) {
  n <- nrow(positions)
  frequences_disponibles <- c(900, 1800, 2100, 2600)
  
  # Simulation de la recherche tabou
  for (i in 1:iterations) {
    # Sélection aléatoire d'une antenne à modifier
    antenne_idx <- sample(1:n, 1)
    # Changement de fréquence
    positions$frequence[antenne_idx] <- sample(frequences_disponibles, 1)
  }
  
  return(positions)
}

