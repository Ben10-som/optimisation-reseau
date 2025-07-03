# Application Shiny pour l'optimisation des antennes au Sénégal
# Basée sur le mémoire d'optimisation du placement des antennes

# Chargement des bibliothèques nécessaires
library(shiny)
library(shinydashboard)
library(leaflet)
library(DT)
library(plotly)
library(dplyr)
library(sf)
library(RColorBrewer)

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

# ===============================
# INTERFACE UTILISATEUR
# ===============================

ui <- dashboardPage(
  dashboardHeader(title = "Optimisation des Antennes - Sénégal"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Tableau de Bord", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Répartition Réseau", tabName = "repartition", icon = icon("signal")),
      menuItem("Antennes Existantes", tabName = "antennes", icon = icon("broadcast-tower")),
      menuItem("Optimisation", tabName = "optimisation", icon = icon("cogs")),
      menuItem("Résultats", tabName = "resultats", icon = icon("chart-line"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
      "))
    ),
    
    tabItems(
      # TABLEAU DE BORD
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBoxOutput("total_antennes"),
                valueBoxOutput("regions_couvertes"),
                valueBoxOutput("couverture_moyenne")
              ),
              
              fluidRow(
                box(
                  title = "Carte des Régions du Sénégal", status = "primary", solidHeader = TRUE,
                  width = 8, height = 500,
                  leafletOutput("carte_regions", height = 450)
                ),
                
                box(
                  title = "Statistiques par Région", status = "info", solidHeader = TRUE,
                  width = 4, height = 500,
                  DT::dataTableOutput("stats_regions")
                )
              )
      ),
      
      # RÉPARTITION RÉSEAU
      tabItem(tabName = "repartition",
              fluidRow(
                box(
                  title = "Contrôles", status = "primary", solidHeader = TRUE, width = 3,
                  selectInput("techno_select", "Technologie:", 
                              choices = c("Toutes", "2G", "3G", "4G"), selected = "Toutes"),
                  selectInput("region_filter", "Région:", 
                              choices = c("Toutes", regions_senegal$region), selected = "Toutes")
                ),
                
                box(
                  title = "Couverture Réseau par Technologie", status = "info", 
                  solidHeader = TRUE, width = 9,
                  plotlyOutput("graphique_couverture", height = 400)
                )
              ),
              
              fluidRow(
                box(
                  title = "Répartition 2G/3G/4G", status = "success", solidHeader = TRUE, width = 6,
                  plotlyOutput("repartition_techno")
                ),
                
                box(
                  title = "Évolution par Région", status = "warning", solidHeader = TRUE, width = 6,
                  plotlyOutput("evolution_regions")
                )
              )
      ),
      
      # ANTENNES EXISTANTES
      tabItem(tabName = "antennes",
              fluidRow(
                box(
                  title = "Localisation des Antennes", status = "primary", 
                  solidHeader = TRUE, width = 8,
                  leafletOutput("carte_antennes", height = 500)
                ),
                
                box(
                  title = "Filtres", status = "info", solidHeader = TRUE, width = 4,
                  selectInput("operateur_filter", "Opérateur:", 
                              choices = c("Tous", "Orange", "Free", "Expresso")),
                  selectInput("type_antenne", "Type d'antenne:", 
                              choices = c("Tous", "2G", "3G", "4G")),
                  hr(),
                  h4("Statistiques"),
                  verbatimTextOutput("stats_antennes")
                )
              ),
              
              fluidRow(
                box(
                  title = "Liste des Antennes", status = "primary", solidHeader = TRUE, width = 12,
                  DT::dataTableOutput("table_antennes")
                )
              )
      ),
      
      # OPTIMISATION
      tabItem(tabName = "optimisation",
              fluidRow(
                box(
                  title = "Paramètres d'Optimisation", status = "primary", 
                  solidHeader = TRUE, width = 4,
                  
                  h4("Zone d'étude"),
                  selectInput("region_optim", "Région cible:", 
                              choices = regions_senegal$region, selected = "Tambacounda"),
                  
                  h4("Contraintes"),
                  numericInput("nb_antennes", "Nombre d'antennes à placer:", 
                               value = 10, min = 1, max = 50),
                  numericInput("budget_total", "Budget total (FCFA):", 
                               value = 500000000, min = 100000000, max = 2000000000, step = 50000000),
                  
                  h4("Paramètres techniques"),
                  sliderInput("seuil_sir", "Seuil SIR minimum (dB):", 
                              min = 5, max = 25, value = 15),
                  selectInput("methode_optim", "Méthode d'optimisation:", 
                              choices = c("MADS", "Recherche Tabou", "Hybride"), selected = "Hybride"),
                  
                  br(),
                  actionButton("lancer_optim", "Lancer l'Optimisation", 
                               class = "btn-success", style = "width: 100%")
                ),
                
                box(
                  title = "Progression", status = "info", solidHeader = TRUE, width = 8,
                  verbatimTextOutput("log_optimisation"),
                  
                  br(),
                  h4("Aperçu de la zone"),
                  leafletOutput("carte_zone_optim", height = 300)
                )
              )
      ),
      
      # RÉSULTATS
      tabItem(tabName = "resultats",
              fluidRow(
                valueBoxOutput("cout_optimisation"),
                valueBoxOutput("couverture_obtenue"),
                valueBoxOutput("sir_moyen")
              ),
              
              fluidRow(
                box(
                  title = "Placement Optimisé", status = "success", solidHeader = TRUE, width = 8,
                  leafletOutput("carte_resultats", height = 500)
                ),
                
                box(
                  title = "Analyse des Résultats", status = "info", solidHeader = TRUE, width = 4,
                  h4("Performances"),
                  verbatimTextOutput("analyse_resultats"),
                  
                  br(),
                  h4("Répartition des Fréquences"),
                  plotlyOutput("repartition_freq", height = 200)
                )
              ),
              
              fluidRow(
                box(
                  title = "Antennes Optimisées", status = "primary", solidHeader = TRUE, width = 12,
                  DT::dataTableOutput("table_resultats")
                )
              )
      )
    )
  )
)

# ===============================
# SERVEUR
# ===============================

server <- function(input, output, session) {
  
  # Variables réactives
  resultats_optimisation <- reactiveVal(NULL)
  
  # =================
  # TABLEAU DE BORD
  # =================
  
  output$total_antennes <- renderValueBox({
    valueBox(
      value = nrow(antennes_existantes),
      subtitle = "Antennes Installées",
      icon = icon("broadcast-tower"),
      color = "blue"
    )
  })
  
  output$regions_couvertes <- renderValueBox({
    valueBox(
      value = length(unique(antennes_existantes$region)),
      subtitle = "Régions Couvertes",
      icon = icon("map-marked-alt"),
      color = "green"
    )
  })
  
  output$couverture_moyenne <- renderValueBox({
    moy_4g <- mean(couverture_reseau$couverture_pct[couverture_reseau$technologie == "4G"])
    valueBox(
      value = paste0(round(moy_4g, 1), "%"),
      subtitle = "Couverture 4G Moyenne",
      icon = icon("signal"),
      color = "yellow"
    )
  })
  
  output$carte_regions <- renderLeaflet({
    leaflet(regions_senegal) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~lon, lat = ~lat,
        radius = ~sqrt(population/100000),
        popup = ~paste("<b>", region, "</b><br>Population:", format(population, big.mark = " ")),
        color = "red", fillOpacity = 0.7
      ) %>%
      setView(lng = -14.5, lat = 14.5, zoom = 6)
  })
  
  output$stats_regions <- DT::renderDataTable({
    antennes_par_region <- antennes_existantes %>%
      group_by(region) %>%
      summarise(
        nb_antennes = n(),
        nb_2G = sum(type == "2G"),
        nb_3G = sum(type == "3G"),
        nb_4G = sum(type == "4G")
      ) %>%
      arrange(desc(nb_antennes))
    
    DT::datatable(antennes_par_region, 
                  options = list(pageLength = 14, searching = FALSE),
                  colnames = c("Région", "Total", "2G", "3G", "4G"))
  })
  
  # ====================
  # RÉPARTITION RÉSEAU
  # ====================
  
  output$graphique_couverture <- renderPlotly({
    data_filtered <- couverture_reseau
    
    if (input$techno_select != "Toutes") {
      data_filtered <- data_filtered[data_filtered$technologie == input$techno_select, ]
    }
    
    if (input$region_filter != "Toutes") {
      data_filtered <- data_filtered[data_filtered$region == input$region_filter, ]
    }
    
    p <- ggplot(data_filtered, aes(x = region, y = couverture_pct, fill = technologie)) +
      geom_col(position = "dodge") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      labs(title = "Couverture Réseau par Région et Technologie",
           x = "Région", y = "Couverture (%)", fill = "Technologie")
    
    ggplotly(p)
  })
  
  output$repartition_techno <- renderPlotly({
    totaux <- couverture_reseau %>%
      group_by(technologie) %>%
      summarise(couverture_moyenne = mean(couverture_pct))
    
    p <- plot_ly(totaux, x = ~technologie, y = ~couverture_moyenne, type = 'bar',
                 marker = list(color = c('lightblue', 'lightgreen', 'orange'))) %>%
      layout(title = "Couverture Moyenne par Technologie",
             xaxis = list(title = "Technologie"),
             yaxis = list(title = "Couverture Moyenne (%)"))
    p
  })
  
  output$evolution_regions <- renderPlotly({
    # Simulation d'évolution temporelle
    regions_top <- couverture_reseau %>%
      filter(technologie == "4G") %>%
      arrange(desc(couverture_pct)) %>%
      head(6)
    
    p <- plot_ly(regions_top, x = ~region, y = ~couverture_pct, type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "Top 6 Régions - Couverture 4G",
             xaxis = list(title = "Région"),
             yaxis = list(title = "Couverture 4G (%)"))
    p
  })
  
  # ====================
  # ANTENNES EXISTANTES
  # ====================
  
  antennes_filtrees <- reactive({
    data <- antennes_existantes
    
    if (input$operateur_filter != "Tous") {
      data <- data[data$operateur == input$operateur_filter, ]
    }
    
    if (input$type_antenne != "Tous") {
      data <- data[data$type == input$type_antenne, ]
    }
    
    return(data)
  })
  
  output$carte_antennes <- renderLeaflet({
    data <- antennes_filtrees()
    
    # Couleurs par type
    couleurs <- c("2G" = "red", "3G" = "green", "4G" = "blue")
    
    leaflet(data) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~lon, lat = ~lat,
        color = ~couleurs[type],
        radius = ~sqrt(puissance)/3,
        popup = ~paste("<b>Antenne", id, "</b><br>",
                       "Type:", type, "<br>",
                       "Opérateur:", operateur, "<br>",
                       "Puissance:", round(puissance, 1), "W<br>",
                       "Fréquence:", frequence, "MHz"),
        fillOpacity = 0.7
      ) %>%
      setView(lng = -14.5, lat = 14.5, zoom = 6)
  })
  
  output$stats_antennes <- renderText({
    data <- antennes_filtrees()
    
    stats <- paste(
      "Nombre total:", nrow(data), "\n",
      "Puissance moyenne:", round(mean(data$puissance), 1), "W\n",
      "Coût moyen:", format(round(mean(data$cout)), big.mark = " "), "FCFA\n",
      "Fréquences utilisées:", length(unique(data$frequence))
    )
    
    return(stats)
  })
  
  output$table_antennes <- DT::renderDataTable({
    data <- antennes_filtrees() %>%
      select(id, region, type, operateur, puissance, frequence, cout) %>%
      mutate(
        puissance = round(puissance, 1),
        cout = format(cout, big.mark = " ")
      )
    
    DT::datatable(data, options = list(pageLength = 10))
  })
  
  # =================
  # OPTIMISATION
  # =================
  
  output$carte_zone_optim <- renderLeaflet({
    region_info <- regions_senegal[regions_senegal$region == input$region_optim, ]
    
    leaflet() %>%
      addTiles() %>%
      addMarkers(lng = region_info$lon, lat = region_info$lat,
                 popup = paste("Zone d'optimisation:", input$region_optim)) %>%
      setView(lng = region_info$lon, lat = region_info$lat, zoom = 8)
  })
  
  observeEvent(input$lancer_optim, {
    # Simulation du processus d'optimisation
    region_info <- regions_senegal[regions_senegal$region == input$region_optim, ]
    
    output$log_optimisation <- renderText({
      paste(
        "=== OPTIMISATION EN COURS ===\n",
        "Région cible:", input$region_optim, "\n",
        "Méthode:", input$methode_optim, "\n",
        "Nombre d'antennes:", input$nb_antennes, "\n",
        "Budget:", format(input$budget_total, big.mark = " "), "FCFA\n\n",
        "Étape 1: Initialisation du modèle...\n",
        "Étape 2: Calcul des positions optimales...\n",
        "Étape 3: Optimisation des fréquences...\n",
        "Étape 4: Validation des contraintes...\n\n",
        "OPTIMISATION TERMINÉE !"
      )
    })
    
    # Simulation des résultats
    zone_lat <- c(region_info$lat - 0.5, region_info$lat + 0.5)
    zone_lon <- c(region_info$lon - 0.5, region_info$lon + 0.5)
    
    resultats <- optimiser_placement_mads(input$nb_antennes, input$budget_total, 
                                          zone_lat, zone_lon)
    
    # Optimisation des fréquences avec recherche tabou
    if (input$methode_optim %in% c("Recherche Tabou", "Hybride")) {
      resultats$positions <- optimiser_frequences_tabou(resultats$positions)
    }
    
    resultats_optimisation(resultats)
  })
  
  # ================
  # RÉSULTATS
  # ================
  
  output$cout_optimisation <- renderValueBox({
    res <- resultats_optimisation()
    
    valueBox(
      value = if(is.null(res)) "N/A" else format(round(res$cout_total), big.mark = " "),
      subtitle = "Coût Total (FCFA)",
      icon = icon("money-bill"),
      color = "green"
    )
  })
  
  output$couverture_obtenue <- renderValueBox({
    res <- resultats_optimisation()
    
    valueBox(
      value = if(is.null(res)) "N/A" else paste0(round(res$couverture, 1), "%"),
      subtitle = "Couverture Obtenue",
      icon = icon("signal"),
      color = "blue"
    )
  })
  
  output$sir_moyen <- renderValueBox({
    res <- resultats_optimisation()
    
    valueBox(
      value = if(is.null(res)) "N/A" else paste0(round(res$sir_moyen, 1), " dB"),
      subtitle = "SIR Moyen",
      icon = icon("wave-square"),
      color = "orange"
    )
  })
  
  output$carte_resultats <- renderLeaflet({
    res <- resultats_optimisation()
    
    if (is.null(res)) {
      leaflet() %>% addTiles() %>% setView(lng = -14.5, lat = 14.5, zoom = 6)
    } else {
      # Couleurs par fréquence
      couleurs_freq <- c("900" = "red", "1800" = "green", "2100" = "blue", "2600" = "purple")
      
      leaflet(res$positions) %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~lon, lat = ~lat,
          color = ~couleurs_freq[as.character(frequence)],
          radius = ~sqrt(puissance)/2,
          popup = ~paste("<b>Antenne Optimisée</b><br>",
                         "Fréquence:", frequence, "MHz<br>",
                         "Puissance:", round(puissance, 1), "W"),
          fillOpacity = 0.8
        ) %>%
        setView(lng = mean(res$positions$lon), lat = mean(res$positions$lat), zoom = 9)
    }
  })
  
  output$analyse_resultats <- renderText({
    res <- resultats_optimisation()
    
    if (is.null(res)) {
      "Aucune optimisation lancée"
    } else {
      paste(
        "Performances obtenues:\n\n",
        "• Couverture:", round(res$couverture, 1), "%\n",
        "• SIR moyen:", round(res$sir_moyen, 1), "dB\n",
        "• Coût total:", format(round(res$cout_total), big.mark = " "), "FCFA\n",
        "• Coût par antenne:", format(round(res$cout_total/nrow(res$positions)), big.mark = " "), "FCFA\n\n",
        "Analyse:\n",
        if(res$couverture > 80) "✓ Excellente couverture" else "⚠ Couverture à améliorer", "\n",
        if(res$sir_moyen > 15) "✓ Bonne qualité signal" else "⚠ Signal faible"
      )
    }
  })
  
  output$repartition_freq <- renderPlotly({
    res <- resultats_optimisation()
    
    if (is.null(res)) {
      plot_ly() %>% layout(title = "Aucune donnée")
    } else {
      freq_count <- table(res$positions$frequence)
      
      plot_ly(x = names(freq_count), y = as.numeric(freq_count), type = 'bar') %>%
        layout(title = "Répartition des Fréquences",
               xaxis = list(title = "Fréquence (MHz)"),
               yaxis = list(title = "Nombre d'antennes"))
    }
  })
  
  output$table_resultats <- DT::renderDataTable({
    res <- resultats_optimisation()
    
    if (is.null(res)) {
      data.frame()
    } else {
      data <- res$positions %>%
        mutate(
          id = 1:nrow(.),
          lat = round(lat, 4),
          lon = round(lon, 4),
          puissance = round(puissance, 1),
          cout_estime = round(puissance * 1000 + runif(nrow(.), 30000, 60000))
        ) %>%
        select(id, lat, lon, frequence, puissance, cout_estime)
      
      DT::datatable(data, options = list(pageLength = 10),
                    colnames = c("ID", "Latitude", "Longitude", "Fréquence (MHz)", 
                                 "Puissance (W)", "Coût Estimé (FCFA)"))
    }
  })
}

# ===============================
# LANCEMENT DE L'APPLICATION
# ===============================

shinyApp(ui = ui, server = server)