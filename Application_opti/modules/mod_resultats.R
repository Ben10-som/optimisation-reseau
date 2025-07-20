# modules/mod_resultats.R

mod_resultats_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(4, div(class = "mb-4", valueBoxOutput(ns("cout_optimisation")))),
      column(4, div(class = "mb-4", valueBoxOutput(ns("couverture_obtenue")))),
      column(4, div(class = "mb-4", valueBoxOutput(ns("sir_moyen"))))
    ),
    fluidRow(
      column(8,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("map-location-dot", class = "me-2 text-primary"),
                    span("Placement Optimisé", style = "font-weight:600; font-size:1.1em;"))
          ),
          leafletOutput(ns("carte_resultats"), height = 500),
          br(),
          h4("Carte des zones blanches"),
          leafletOutput(ns("heatmap_zones_blanches"), height = 500)
        )
      ),
      column(4,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("chart-bar", class = "me-2 text-success"),
                    span("Analyse des Résultats", style = "font-weight:600; font-size:1.1em;"))
          ),
          h4("Performances"),
          verbatimTextOutput(ns("analyse_resultats")),
          br(),
          h4("Répartition des Fréquences"),
          plotlyOutput(ns("repartition_freq"), height = 200),
          br(),
          uiOutput(ns("download_pdf_ui")),
          tags$small("Vous pouvez télécharger le rapport PDF uniquement après avoir lancé une optimisation.")
        )
      )
    ),
    fluidRow(
      column(12,
        bslib::card(
          class = "dashboard-card",
          bslib::card_header(
            tagList(icon("table-list", class = "me-2 text-warning"),
                    span("Antennes Optimisées", style = "font-weight:600; font-size:1.1em;"))
          ),
          DT::dataTableOutput(ns("table_resultats"))
        )
      )
    )
  )
}

mod_resultats_server <- function(input, output, session, resultats_optimisation) {
  ns <- session$ns

  output$cout_optimisation <- renderValueBox({
    res <- resultats_optimisation()
    valueBox(
      value = tagList(
        tags$div(style = "display:flex; align-items:center; justify-content:center; gap:16px; width:100%;",
          icon("money-bill", class = "fa-2x", style = "min-width:32px; color:#1bbd6a;"),
          tags$div(style = "text-align:center; font-size:2em; font-weight:700;", if(is.null(res)) "N/A" else format(round(res$cout_total), big.mark = " "))
        )
      ),
      subtitle = tags$div(style = "text-align:center; width:100%;", "Coût Total (FCFA)"),
      color = "aqua"
    )
  })

  output$couverture_obtenue <- renderValueBox({
    res <- resultats_optimisation()
    valueBox(
      value = tagList(
        tags$div(style = "display:flex; align-items:center; justify-content:center; gap:16px; width:100%;",
          icon("signal", class = "fa-2x", style = "min-width:32px; color:#0072B2;"),
          tags$div(style = "text-align:center; font-size:2em; font-weight:700;", if(is.null(res)) "N/A" else paste0(round(res$couverture, 1), "%"))
        )
      ),
      subtitle = tags$div(style = "text-align:center; width:100%;", "Couverture Obtenue"),
      color = "blue"
    )
  })

  output$sir_moyen <- renderValueBox({
    res <- resultats_optimisation()
    valueBox(
      value = tagList(
        tags$div(style = "display:flex; align-items:center; justify-content:center; gap:16px; width:100%;",
          icon("wave-square", class = "fa-2x", style = "min-width:32px; color:#f7b731;"),
          tags$div(style = "text-align:center; font-size:2em; font-weight:700;", if(is.null(res)) "N/A" else paste0(round(res$sir_moyen, 1), " dB"))
        )
      ),
      subtitle = tags$div(style = "text-align:center; width:100%;", "SIR Moyen"),
      color = "yellow"
    )
  })

  output$carte_resultats <- renderLeaflet({
    res <- resultats_optimisation()
    if (is.null(res)) {
      leaflet() %>% addTiles() %>% setView(lng = -14.5, lat = 14.5, zoom = 6)
    } else {
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

  # Heatmap des zones blanches (zones non couvertes)
  output$heatmap_zones_blanches <- renderLeaflet({
    res <- resultats_optimisation()
    if (is.null(res)) {
      return(leaflet() %>% addTiles())
    }
    # Génère une grille de points autour des antennes optimisées
    lat_seq <- seq(min(res$positions$lat) - 0.2, max(res$positions$lat) + 0.2, length.out = 40)
    lon_seq <- seq(min(res$positions$lon) - 0.2, max(res$positions$lon) + 0.2, length.out = 40)
    grid <- expand.grid(lat = lat_seq, lon = lon_seq)
    # Calcule le SIR pour chaque point de la grille
    calc_sir <- function(lat, lon, positions) {
      dists <- sqrt((positions$lat - lat)^2 + (positions$lon - lon)^2)
      puissances <- positions$puissance / (dists^2.5 * (positions$frequence/1000)^2)
      signal <- max(puissances)
      interferences <- sum(puissances) - signal
      if (interferences <= 0) return(Inf)
      signal / interferences
    }
    grid$sir <- mapply(calc_sir, grid$lat, grid$lon, MoreArgs = list(positions = res$positions))
    # Zone blanche = SIR < seuil (ex: 10)
    grid$zone_blanche <- grid$sir < 10
    leaflet() %>%
      addTiles() %>%
      addCircleMarkers(
        data = grid[grid$zone_blanche, ],
        lng = ~lon, lat = ~lat,
        radius = 4, color = "red", fillOpacity = 0.5,
        label = ~paste0("SIR: ", round(sir, 1), " (zone blanche)")
      ) %>%
      addCircleMarkers(
        data = grid[!grid$zone_blanche, ],
        lng = ~lon, lat = ~lat,
        radius = 2, color = "green", fillOpacity = 0.1
      ) %>%
      addCircleMarkers(
        data = res$positions,
        lng = ~lon, lat = ~lat,
        color = "blue", radius = 6, fillOpacity = 1,
        label = ~paste("Antenne optimisée")
      ) %>%
      setView(lng = mean(res$positions$lon), lat = mean(res$positions$lat), zoom = 8)
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

  # UI dynamique pour le bouton PDF
  output$download_pdf_ui <- renderUI({
    res <- resultats_optimisation()
    if (is.null(res) || is.null(res$positions) || nrow(res$positions) == 0) {
      shinyjs::disabled(
        downloadButton(ns("download_pdf"), label = tagList(icon("file-pdf"), "Télécharger le PDF"), class = "btn btn-danger w-100 mt-2")
      )
    } else {
      downloadButton(ns("download_pdf"), label = tagList(icon("file-pdf"), "Télécharger le PDF"), class = "btn btn-danger w-100 mt-2")
    }
  })

  # Rapport PDF dynamique
  output$download_pdf <- downloadHandler(
    filename = function() {
      paste0("rapport_optimisation_", Sys.Date(), ".pdf")
    },
    content = function(file) {
      resultats <- resultats_optimisation()
      if (is.null(resultats) || is.null(resultats$positions) || nrow(resultats$positions) == 0) {
        stop("Aucun résultat d'optimisation à exporter.")
      }
      rmarkdown::render(
        input = "report_template.Rmd",
        output_file = file,
        params = list(resultats = resultats),
        envir = new.env(parent = globalenv())
      )
    }
  )
} 