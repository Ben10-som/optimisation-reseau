# modules/mod_optimisation.R

mod_optimisation_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(4,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("cogs", class = "me-2 text-success"),
                    span("Paramètres d'Optimisation", style = "font-weight:600; font-size:1.1em;"))
          ),
          h4("Zone d'étude"),
          selectInput(ns("region_optim"), "Région cible:", 
                      choices = regions_senegal$region, selected = "Tambacounda"),
          h4("Contraintes"),
          numericInput(ns("nb_antennes"), "Nombre d'antennes à placer:", 
                       value = 10, min = 1, max = 50),
          numericInput(ns("budget_total"), "Budget total (FCFA):", 
                       value = 500000000, min = 100000000, max = 2000000000, step = 50000000),
          h4("Paramètres techniques"),
          sliderInput(ns("seuil_sir"), "Seuil SIR minimum (dB):", 
                      min = 5, max = 25, value = 15),
          selectInput(ns("methode_optim"), "Méthode d'optimisation:", 
                      choices = c("MADS", "Recherche Tabou", "Hybride"), selected = "Hybride"),
          br(),
          actionButton(ns("lancer_optim"), "Lancer l'Optimisation", 
                       class = "btn-success w-100")
        )
      ),
      column(8,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("spinner", class = "me-2 text-info"),
                    span("Progression", style = "font-weight:600; font-size:1.1em;"))
          ),
          verbatimTextOutput(ns("log_optimisation")),
          br(),
          h4("Aperçu de la zone"),
          leafletOutput(ns("carte_zone_optim"), height = 450)
        )
      )
    )
  )
}

mod_optimisation_server <- function(input, output, session, resultats_optimisation) {
  ns <- session$ns

  output$carte_zone_optim <- renderLeaflet({
    region_info <- regions_senegal[regions_senegal$region == input$region_optim, ]
    leaflet() %>%
      addTiles() %>%
      addMarkers(lng = region_info$lon, lat = region_info$lat,
                 popup = paste("Zone d'optimisation:", input$region_optim)) %>%
      setView(lng = region_info$lon, lat = region_info$lat, zoom = 8)
  })

  observeEvent(input$lancer_optim, {
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
    zone_lat <- c(region_info$lat - 0.5, region_info$lat + 0.5)
    zone_lon <- c(region_info$lon - 0.5, region_info$lon + 0.5)
    resultats <- optimiser_placement_mads(input$nb_antennes, input$budget_total, 
                                          zone_lat, zone_lon)
    if (input$methode_optim %in% c("Recherche Tabou", "Hybride")) {
      resultats$positions <- optimiser_frequences_tabou(resultats$positions)
    }
    resultats_optimisation(resultats)
  })
} 