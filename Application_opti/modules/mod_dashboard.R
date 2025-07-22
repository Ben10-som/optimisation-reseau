# modules/mod_dashboard.R

mod_dashboard_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(4, div(class = "mb-4", valueBoxOutput(ns("total_antennes")))),
      column(4, div(class = "mb-4", valueBoxOutput(ns("regions_couvertes")))),
      column(4, div(class = "mb-4", valueBoxOutput(ns("couverture_moyenne"))))
    ),
    fluidRow(
      column(8,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("map", class = "me-2 text-primary"),
                    span("Carte des Régions du Sénégal", style = "font-weight:600; font-size:1.15em;"))
          ),
          leafletOutput(ns("carte_regions"), height = 450)
        )
      ),
      column(4,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("table", class = "me-2 text-success"),
                    span("Statistiques par Région", style = "font-weight:600; font-size:1.15em;"))
          ),
          DT::dataTableOutput(ns("stats_regions"))
        )
      )
    )
  )
}

mod_dashboard_server <- function(input, output, session) {
  ns <- session$ns

  output$total_antennes <- renderValueBox({
    valueBox(
      value = tagList(
        tags$div(style = "display:flex; align-items:center; justify-content:center; gap:16px; width:100%;",
          icon("broadcast-tower", class = "fa-2x", style = "min-width:32px; color:#0072B2;"),
          tags$div(style = "text-align:center; font-size:2em; font-weight:700;", nrow(antennes_existantes))
        )
      ),
      subtitle = tags$div(style = "text-align:center; width:100%;", "Antennes Installées"),
      color = "blue"
    )
  })

  output$regions_couvertes <- renderValueBox({
    valueBox(
      value = tagList(
        tags$div(style = "display:flex; align-items:center; justify-content:center; gap:16px; width:100%;",
          icon("map-marked-alt", class = "fa-2x", style = "min-width:32px; color:#1bbd6a;"),
          tags$div(style = "text-align:center; font-size:2em; font-weight:700;", length(unique(antennes_existantes$region)))
        )
      ),
      subtitle = tags$div(style = "text-align:center; width:100%;", "Régions Couvertes"),
      color = "aqua"
    )
  })

  output$couverture_moyenne <- renderValueBox({
    moy_4g <- mean(couverture_reseau$couverture_pct[couverture_reseau$technologie == "4G"])
    valueBox(
      value = tagList(
        tags$div(style = "display:flex; align-items:center; justify-content:center; gap:16px; width:100%;",
          icon("signal", class = "fa-2x", style = "min-width:32px; color:#f7b731;"),
          tags$div(style = "text-align:center; font-size:2em; font-weight:700;", paste0(round(moy_4g, 1), "%"))
        )
      ),
      subtitle = tags$div(style = "text-align:center; width:100%;", "Couverture 4G Moyenne"),
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
        color = "#0072B2", fillOpacity = 0.7
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
} 