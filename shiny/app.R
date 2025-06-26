# Application Shiny - Optimisation du placement des antennes au Sénégal
# Basée sur les régions de Kédougou, Tambacounda et Matam

library(shiny)
library(leaflet)
library(DT)
library(plotly)
library(dplyr)
library(shinydashboard)
library(shinythemes)

# Interface utilisateur
ui <- navbarPage(
  "Optimisation Antennes Télécommunication - Sénégal",
  theme = shinythemes::shinytheme("flatly"),
  
  # Onglet principal - Simulation
  tabPanel("Simulation Couverture",
           fluidRow(
             column(4,
                    wellPanel(
                      h4("Paramètres de Simulation"),
                      
                      # Sélection de la région
                      selectInput("region", "Région d'étude:",
                                  choices = c("Kédougou" = "kedougou", 
                                              "Tambacounda" = "tambacounda", 
                                              "Matam" = "matam"),
                                  selected = "kedougou"),
                      
                      # Nombre d'antennes
                      sliderInput("nb_antennes", "Nombre d'antennes:",
                                  min = 1, max = 20, value = 5),
                      
                      # Puissance d'émission
                      sliderInput("puissance", "Puissance émission (W):",
                                  min = 10, max = 100, value = 50),
                      
                      # Fréquence
                      selectInput("frequence", "Fréquence (MHz):",
                                  choices = c("900" = 900, "1800" = 1800, "2100" = 2100),
                                  selected = 900),
                      
                      # Seuil SIR
                      sliderInput("seuil_sir", "Seuil SIR minimum (dB):",
                                  min = 5, max = 20, value = 10),
                      
                      # Budget
                      numericInput("budget", "Budget (millions FCFA):",
                                   value = 500, min = 100, max = 2000),
                      
                      # Boutons d'action
                      div(style = "text-align: center;",
                          actionButton("generer", "Générer Positions", 
                                       class = "btn-primary", style = "margin: 5px;"),
                          actionButton("optimiser", "Optimiser MADS", 
                                       class = "btn-success", style = "margin: 5px;"),
                          actionButton("tabou", "Recherche Tabou", 
                                       class = "btn-warning", style = "margin: 5px;")
                      )
                    )
             ),
             
             column(8,
                    tabsetPanel(
                      tabPanel("Carte Couverture", 
                               leafletOutput("carte_couverture", height = "500px")),
                      tabPanel("Analyse SIR", 
                               plotlyOutput("plot_sir", height = "500px")),
                      tabPanel("Métriques", 
                               div(style = "padding: 20px;",
                                   fluidRow(
                                     column(6, 
                                            div(class = "info-box",
                                                h4(textOutput("couverture_pct"), style = "color: #3c8dbc;"),
                                                p("Couverture population"))),
                                     column(6, 
                                            div(class = "info-box",
                                                h4(textOutput("cout_total"), style = "color: #00a65a;"),
                                                p("Coût total (FCFA)")))
                                   ),
                                   fluidRow(
                                     column(6, 
                                            div(class = "info-box",
                                                h4(textOutput("nb_interferences"), style = "color: #f39c12;"),
                                                p("Interférences détectées"))),
                                     column(6, 
                                            div(class = "info-box",
                                                h4(textOutput("efficacite"), style = "color: #605ca8;"),
                                                p("Efficacité (couv./coût)")))
                                   )
                               ))
                    )
             )
           )
  ),
  
  # Onglet données techniques
  tabPanel("Données Techniques",
           fluidRow(
             column(6,
                    h4("Modèle de Propagation (Friis)"),
                    withMathJax(),
                    div("$$P_r(d) = \\frac{P_t G_t G_r \\lambda^2}{(4\\pi d)^2 L}$$"),
                    p("Où:"),
                    tags$ul(
                      tags$li("P_r(d): puissance reçue à distance d"),
                      tags$li("P_t: puissance transmise"),
                      tags$li("G_t, G_r: gains antennes émettrice/réceptrice"),
                      tags$li("λ: longueur d'onde"),
                      tags$li("L: pertes système")
                    )
             ),
             column(6,
                    h4("Paramètres par Région"),
                    DT::dataTableOutput("table_regions")
             )
           ),
           br(),
           fluidRow(
             column(12,
                    h4("Positions des Antennes Optimisées"),
                    DT::dataTableOutput("table_antennes")
             )
           )
  )
)

# Serveur
server <- function(input, output, session) {
  
  # Données des régions
  regions_data <- reactive({
    data.frame(
      Region = c("Kédougou", "Tambacounda", "Matam"),
      Superficie_km2 = c(16896, 42364, 29445),
      Population = c(201235, 682455, 690821),
      Couverture_actuelle = c("35%", "42%", "38%"),
      Densite_pop = c(11.9, 16.1, 23.5),
      Cout_installation = c(85, 75, 70),
      stringsAsFactors = FALSE
    )
  })
  
  # Coordonnées des régions (approximatives)
  region_coords <- list(
    kedougou = list(lat = 12.557, lng = -12.184, zoom = 8),
    tambacounda = list(lat = 13.771, lng = -13.668, zoom = 8),
    matam = list(lat = 15.655, lng = -13.255, zoom = 8)
  )
  
  # Variables réactives pour stocker les positions d'antennes
  antennes_positions <- reactiveVal(data.frame())
  metriques_reseau <- reactiveVal(list(couverture = 0, cout = 0, interferences = 0))
  
  # Fonction de calcul de la puissance reçue (modèle Friis simplifié)
  calculer_puissance_recue <- function(distance_km, puissance_w, freq_mhz) {
    lambda <- 3e8 / (freq_mhz * 1e6)  # longueur d'onde
    distance_m <- distance_km * 1000
    if(distance_m == 0) distance_m <- 1  # éviter division par zéro
    
    # Formule Friis simplifiée (gains antennes = 1, pertes = 1)
    pr <- puissance_w * (lambda / (4 * pi * distance_m))^2
    return(10 * log10(pr * 1000))  # conversion en dBm
  }
  
  # Génération aléatoire des positions d'antennes
  observeEvent(input$generer, {
    coords <- region_coords[[input$region]]
    
    # Génération de positions aléatoires dans la région
    n <- input$nb_antennes
    lat_range <- c(coords$lat - 0.5, coords$lat + 0.5)
    lng_range <- c(coords$lng - 0.5, coords$lng + 0.5)
    
    positions <- data.frame(
      id = 1:n,
      lat = runif(n, lat_range[1], lat_range[2]),
      lng = runif(n, lng_range[1], lng_range[2]),
      puissance = rep(input$puissance, n),
      frequence = rep(as.numeric(input$frequence), n),
      cout = runif(n, 50, 100)  # coût en millions FCFA
    )
    
    antennes_positions(positions)
    
    # Calcul des métriques
    calculer_metriques()
  })
  
  # Simulation d'optimisation MADS
  observeEvent(input$optimiser, {
    positions <- antennes_positions()
    if(nrow(positions) > 0) {
      # Simulation d'amélioration par MADS (déplacement léger des positions)
      positions$lat <- positions$lat + rnorm(nrow(positions), 0, 0.05)
      positions$lng <- positions$lng + rnorm(nrow(positions), 0, 0.05)
      
      antennes_positions(positions)
      calculer_metriques()
      
      showNotification("Optimisation MADS terminée!", type = "success")
    }
  })
  
  # Simulation de recherche tabou
  observeEvent(input$tabou, {
    positions <- antennes_positions()
    if(nrow(positions) > 0) {
      # Simulation d'optimisation fréquences/puissances
      freq_options <- c(900, 1800, 2100)
      positions$frequence <- sample(freq_options, nrow(positions), replace = TRUE)
      positions$puissance <- pmax(10, positions$puissance + rnorm(nrow(positions), 0, 10))
      
      antennes_positions(positions)
      calculer_metriques()
      
      showNotification("Recherche Tabou terminée!", type = "success")
    }
  })
  
  # Calcul des métriques du réseau
  calculer_metriques <- function() {
    positions <- antennes_positions()
    if(nrow(positions) == 0) return()
    
    # Simulation de calculs de couverture et d'interférences
    couverture <- min(95, 30 + nrow(positions) * 8 + runif(1, -5, 10))
    cout_total <- sum(positions$cout)
    nb_interf <- sum(duplicated(positions$frequence))
    efficacite <- couverture / cout_total * 100
    
    metriques_reseau(list(
      couverture = round(couverture, 1),
      cout = round(cout_total, 1),
      interferences = nb_interf,
      efficacite = round(efficacite, 2)
    ))
  }
  
  # Rendu de la carte
  output$carte_couverture <- renderLeaflet({
    coords <- region_coords[[input$region]]
    
    m <- leaflet() %>%
      addTiles() %>%
      setView(lng = coords$lng, lat = coords$lat, zoom = coords$zoom)
    
    positions <- antennes_positions()
    if(nrow(positions) > 0) {
      # Ajout des antennes
      m <- m %>%
        addCircleMarkers(
          data = positions,
          lng = ~lng, lat = ~lat,
          radius = ~sqrt(puissance/5),
          color = ~ifelse(frequence == 900, "blue", 
                          ifelse(frequence == 1800, "green", "red")),
          popup = ~paste("Antenne", id, "<br>",
                         "Puissance:", puissance, "W<br>",
                         "Fréquence:", frequence, "MHz<br>",
                         "Coût:", round(cout, 1), "M FCFA"),
          fillOpacity = 0.7
        )
      
      # Ajout des zones de couverture (cercles approximatifs)
      for(i in 1:nrow(positions)) {
        rayon_km <- sqrt(positions$puissance[i]) / 5  # rayon approximatif
        m <- m %>%
          addCircles(
            lng = positions$lng[i], lat = positions$lat[i],
            radius = rayon_km * 1000,  # conversion en mètres
            color = "blue", fillOpacity = 0.1, weight = 1
          )
      }
    }
    
    m
  })
  
  # Graphique d'analyse SIR
  output$plot_sir <- renderPlotly({
    positions <- antennes_positions()
    if(nrow(positions) == 0) {
      return(plot_ly() %>% layout(title = "Générez d'abord des positions d'antennes"))
    }
    
    # Simulation de données SIR en fonction de la distance
    distances <- seq(0.1, 20, 0.5)
    sir_values <- sapply(distances, function(d) {
      pr <- calculer_puissance_recue(d, input$puissance, as.numeric(input$frequence))
      sir <- pr - (-90)  # bruit de fond approximatif à -90 dBm
      return(sir)
    })
    
    p <- plot_ly(x = ~distances, y = ~sir_values, type = "scatter", mode = "lines",
                 name = "SIR calculé") %>%
      add_hline(y = input$seuil_sir, line = list(color = "red", dash = "dash"),
                name = "Seuil minimum") %>%
      layout(
        title = "Évolution du SIR en fonction de la distance",
        xaxis = list(title = "Distance (km)"),
        yaxis = list(title = "SIR (dB)"),
        showlegend = TRUE
      )
    
    p
  })
  
  # Métriques simplifiées
  output$couverture_pct <- renderText({
    metriques <- metriques_reseau()
    paste0(metriques$couverture, "%")
  })
  
  output$cout_total <- renderText({
    metriques <- metriques_reseau()
    paste0(metriques$cout, "M FCFA")
  })
  
  output$nb_interferences <- renderText({
    metriques <- metriques_reseau()
    as.character(metriques$interferences)
  })
  
  output$efficacite <- renderText({
    metriques <- metriques_reseau()
    as.character(metriques$efficacite)
  })
  
  # Tables de données
  output$table_regions <- DT::renderDataTable({
    regions_data()
  }, options = list(pageLength = 5, dom = 't'))
  
  output$table_antennes <- DT::renderDataTable({
    positions <- antennes_positions()
    if(nrow(positions) > 0) {
      positions %>%
        mutate(
          Latitude = round(lat, 4),
          Longitude = round(lng, 4),
          `Puissance (W)` = puissance,
          `Fréquence (MHz)` = frequence,
          `Coût (M FCFA)` = round(cout, 1)
        ) %>%
        select(ID = id, Latitude, Longitude, `Puissance (W)`, `Fréquence (MHz)`, `Coût (M FCFA)`)
    } else {
      data.frame(Message = "Aucune antenne générée")
    }
  }, options = list(pageLength = 10))
}

# Lancement de l'application
shinyApp(ui = ui, server = server)