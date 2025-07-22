# modules/mod_antennes.R

mod_antennes_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(8,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("broadcast-tower", class = "me-2 text-primary"),
                    span("Localisation des Antennes", style = "font-weight:600; font-size:1.1em;"))
          ),
          leafletOutput(ns("carte_antennes"), height = 500)
        )
      ),
      column(4,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("filter", class = "me-2 text-info"),
                    span("Filtres", style = "font-weight:600; font-size:1.1em;"))
          ),
          selectInput(ns("operateur_filter"), "Opérateur:", 
                      choices = c("Tous", "Orange", "Free", "Expresso")),
          selectInput(ns("type_antenne"), "Type d'antenne:", 
                      choices = c("Tous", "2G", "3G", "4G")),
          hr(),
          h4("Statistiques"),
          verbatimTextOutput(ns("stats_antennes"))
        )
      )
    ),
    fluidRow(
      column(12,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("table-list", class = "me-2 text-success"),
                    span("Liste des Antennes", style = "font-weight:600; font-size:1.1em;"))
          ),
          DT::dataTableOutput(ns("table_antennes"))
        )
      )
    )
  )
}

mod_antennes_server <- function(input, output, session) {
  ns <- session$ns

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
} 