# modules/mod_repartition.R

mod_repartition_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(3,
        bslib::card(
          class = "dashboard-card",
          style = "height: 400px; overflow: hidden;",
          # aucun style de hauteur ou overflow
          bslib::card_header(
            tagList(icon("sliders-h", class = "me-2 text-info"),
                    span("Contrôles", style = "font-weight:600; font-size:1.1em;"))
          ),
          selectInput(ns("techno_select"), "Technologie:", 
                      choices = c("Toutes", "2G", "3G", "4G"), selected = "Toutes"),
          selectInput(ns("region_filter"), "Région:", 
                      choices = c("Toutes", regions_senegal$region), selected = "Toutes", selectize = TRUE, width = "100%")
        )
      ),
      column(9,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("chart-bar", class = "me-2 text-primary"),
                    span("Couverture Réseau par Technologie", style = "font-weight:600; font-size:1.1em;"))
          ),
          plotlyOutput(ns("graphique_couverture"), height = 400)
        )
      )
    ),
    fluidRow(
      column(6,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("chart-pie", class = "me-2 text-success"),
                    span("Répartition 2G/3G/4G", style = "font-weight:600; font-size:1.1em;"))
          ),
          plotlyOutput(ns("repartition_techno"))
        )
      ),
      column(6,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("chart-line", class = "me-2 text-warning"),
                    span("Évolution par Région", style = "font-weight:600; font-size:1.1em;"))
          ),
          plotlyOutput(ns("evolution_regions"))
        )
      )
    )
  )
}

mod_repartition_server <- function(input, output, session) {
  ns <- session$ns

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
      geom_text(aes(label = couverture_pct), position = position_dodge(width = 0.9), vjust = -0.3, size = 3.5, fontface = "bold") +
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
                 marker = list(color = c('lightblue', 'lightgreen', 'orange')))
    p <- p %>%
      add_text(text = ~round(couverture_moyenne, 1), textposition = 'outside',
               textfont = list(size = 14, color = '#222', family = 'Arial', weight = 'bold')) %>%
      layout(title = "Couverture Moyenne par Technologie",
             xaxis = list(title = "Technologie"),
             yaxis = list(title = "Couverture Moyenne (%)"))
    p
  })

  output$evolution_regions <- renderPlotly({
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
} 