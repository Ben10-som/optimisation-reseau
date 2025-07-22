# server/server_analysis.R

# Server
# Mettre à jour les choix de variables lorsque les données changent
observe({
  # Vérifier que clean_data existe, est un dataframe et a au moins une colonne
  req(rv$clean_data)
  req(is.data.frame(rv$clean_data))
  req(ncol(rv$clean_data) > 0)
  
  # Liste de variables pour les tableaux
  updateSelectizeInput(session, "tabyl_vars", 
                      choices = names(rv$clean_data), 
                      selected = NULL)
  
  # Liste de variables pour la stratification
  updateSelectizeInput(session, "strat_var", 
                     choices = c("Aucune" = "", names(rv$clean_data)), 
                     selected = "")
  
  # Liste de variables pour la pondération (uniquement les variables numériques)
  numeric_vars <- names(rv$clean_data)[sapply(rv$clean_data, is.numeric)]
  updateSelectizeInput(session, "weight_var", 
                     choices = c("Aucune" = "", numeric_vars), 
                     selected = "")
  
  # Variable pour le graphique - sélectionner la première variable automatiquement
  first_var <- names(rv$clean_data)[1]
  updateSelectInput(session, "vis_var", 
                   choices = names(rv$clean_data),
                   selected = first_var)
})

# Création de tableaux avec gtsummary
observeEvent(input$create_tabyl, {
  req(rv$clean_data, input$tabyl_vars)
  
  # Sauvegarde des données pour la comparaison avant/après
  # Stocker les données originales avant de créer un nouveau tableau
  if (input$enable_comparison && is.null(rv$original_data)) {
    rv$original_data <- rv$clean_data
    showNotification("Données originales sauvegardées pour comparaison", type = "message")
  }
  
  # Affichage de l'indicateur de chargement global
  session$userData$show_loading()
  
  # Cacher le tableau précédent
  shinyjs::hide("gtsummary_table")
  
  tryCatch({
    # Vérifications préalables
    if(length(input$tabyl_vars) == 0) {
      stop("Veuillez sélectionner au moins une variable")
    }
    
    # Vérifier si on utilise une variable de stratification
    has_strat <- !is.null(input$strat_var) && input$strat_var != ""
    
    # Vérifier si on utilise une variable de pondération
    has_weights <- !is.null(input$weight_var) && input$weight_var != ""
    
    # Code R généré pour être enregistré dans les logs
    r_code <- NULL
    
    # Vérifier que le package est disponible
    if(!requireNamespace("gtsummary", quietly = TRUE)) {
      stop("Package gtsummary non disponible. Veuillez l'installer avec install.packages('gtsummary')")
    }
    
    # Préparation des données
    data_to_use <- rv$clean_data
    
    # Début du code R pour le log
    r_code <- paste0(
      "library(gtsummary)\n",
      "library(gt)\n\n",
      "# Créer le tableau récapitulatif\n",
      "data %>%\n"
    )
    
    # Ajout de la sélection des variables
    r_code <- paste0(r_code, "  select(", 
                    paste(c(input$tabyl_vars, 
                          if(has_strat) input$strat_var else NULL,
                          if(has_weights) input$weight_var else NULL), 
                          collapse = ", "), 
                    ") %>%\n")
    
    # Construire le tableau - approche simplifiée sans personnalisation des statistiques
    # qui pourrait causer des erreurs selon la version de gtsummary
    if(has_strat) {
      # Avec stratification
      gtsumm <- data_to_use %>%
        dplyr::select(all_of(c(input$tabyl_vars, input$strat_var))) %>%
        gtsummary::tbl_summary(
          by = as.name(input$strat_var),
          missing = "no"
        ) %>%
        gtsummary::add_n() %>%
        gtsummary::add_p() %>%
        gtsummary::modify_header(label = "**Variable**")
      
      # Compléter le code R
      r_code <- paste0(r_code, "  tbl_summary(\n",
                      "    by = ", input$strat_var, ",\n",
                      "    missing = \"no\"\n",
                      "  ) %>%\n",
                      "  add_n() %>%\n  add_p() %>%\n  modify_header(label = \"**Variable**\")")
    } else {
      # Sans stratification
      gtsumm <- data_to_use %>%
        dplyr::select(all_of(input$tabyl_vars)) %>%
        gtsummary::tbl_summary(
          missing = "no"
        ) %>%
        gtsummary::add_n() %>%
        gtsummary::modify_header(label = "**Variable**")
      
      # Compléter le code R
      r_code <- paste0(r_code, "  tbl_summary(\n",
                      "    missing = \"no\"\n",
                      "  ) %>%\n",
                      "  add_n() %>%\n  modify_header(label = \"**Variable**\")")
    }
    
    # Convertir en tableau GT pour appliquer les styles
    gt_table <- gtsumm %>% gtsummary::as_gt()
    r_code <- paste0(r_code, " %>%\n  as_gt()")
    
    # Appliquer les options de style
    r_code <- paste0(r_code, " %>%\n  tab_options(\n    table.font.size = px(14),")
    
    # Appliquer les couleurs alternées si l'option est sélectionnée
    if(input$striped_rows) {
      r_code <- paste0(r_code, "\n    row.striping.include_table_body = TRUE,")
      gt_table <- gt_table %>% gt::tab_options(row.striping.include_table_body = TRUE)
    } else {
      r_code <- paste0(r_code, "\n    row.striping.include_table_body = FALSE,")
    }
    
    # Fermer les options et ajouter les styles de base
    r_code <- paste0(r_code, "\n    heading.title.font.size = px(18),\n    column_labels.font.weight = \"bold\")")
    
    # Appliquer les styles de base
    gt_table <- gt_table %>%
      gt::tab_options(
        table.font.size = gt::px(14),
        heading.title.font.size = gt::px(18),
        column_labels.font.weight = "bold",
        table.width = gt::pct(100)
      )
    
    # Créer le tableau HTML
    rv$gtsumm_table <- gt_table
    
    # Ajouter l'opération au journal avec le code R
    log_message <- if(has_strat) {
      paste0("Création d'un tableau croisé avec les variables ", 
            paste(input$tabyl_vars, collapse = ", "), 
            " stratifié par ", input$strat_var)
    } else {
      paste0("Création d'un tableau descriptif avec les variables ", 
            paste(input$tabyl_vars, collapse = ", "))
    }
    
    log_action(
      message = log_message,
      r_code = r_code
    )
    
    # Afficher le tableau HTML directement
    output$gtsummary_table <- function() {
      gt_table %>% gt::as_raw_html()
    }
    
    # Convertir en dataframe pour l'exportation
    rv$tabyl_data <- gtsumm %>% gtsummary::as_tibble()
    
    # Afficher le tableau gtsummary
    shinyjs::show("gtsummary_table")
    
    # Si la comparaison est activée, mettre à jour automatiquement
    if (input$enable_comparison && !is.null(rv$original_data)) {
      # Déclencher la mise à jour de la comparaison après un court délai
      shinyjs::delay(300, {
        session$sendCustomMessage(type = "triggerButtonClick", message = "refresh_comparison")
      })
    }
    
    # Notification sonore et visuelle
    beepr::beep(10)
    showNotification("Tableau généré avec succès", type = "message")
    
  }, error = function(e) {
    showNotification(paste("Erreur:", e$message), type = "error")
    beepr::beep(10)  # Son d'erreur
  }, finally = {
    # Masquer l'indicateur de chargement global
    session$userData$hide_loading()
  })
})

# Fonction auxiliaire pour personnaliser l'affichage des statistiques
custom_stat_display <- function(labels) {
  function(x) {
    stats_to_display <- names(labels) 
    result <- NULL
    
    for (stat in stats_to_display) {
      if (stat %in% names(x)) {
        template <- labels[[stat]]
        # Remplacer {stat} par la valeur
        display_value <- gsub(paste0("\\{", stat, "\\}"), x[[stat]], template)
        result <- c(result, display_value)
      }
    }
    
    paste(result, collapse = ", ")
  }
}

# SYSTÈME D'INTELLIGENCE ARTIFICIELLE POUR VISUALISATION (AI-VIZ)
#------------------------------------------------------------

# Fonction pour créer des visualisations intelligentes basées sur l'analyse des données
output$smart_viz <- renderUI({
  req(rv$clean_data, input$vis_var)
  
  # Variables locales
  var_name <- input$vis_var
  var_data <- rv$clean_data[[var_name]]
  
  # Analyser le type de données
  is_numeric <- is.numeric(var_data)
  is_date <- inherits(var_data, c("Date", "POSIXct", "POSIXlt"))
  is_categorical <- is.factor(var_data) || is.character(var_data)
  
  # Calculer statistiques de base
  stats <- list(
    missing = sum(is.na(var_data)),
    missing_pct = mean(is.na(var_data)) * 100,
    n_unique = length(unique(var_data[!is.na(var_data)]))
  )
  
  # Ajouter des statistiques spécifiques au type
  if (is_numeric) {
    stats$mean <- mean(var_data, na.rm = TRUE)
    stats$median <- median(var_data, na.rm = TRUE)
    stats$sd <- sd(var_data, na.rm = TRUE)
    stats$min <- min(var_data, na.rm = TRUE)
    stats$max <- max(var_data, na.rm = TRUE)
  } else if (is_categorical) {
    freq_table <- sort(table(var_data), decreasing = TRUE)
    stats$mode <- names(freq_table)[1]
    stats$mode_freq <- freq_table[1]
    stats$mode_pct <- freq_table[1] / sum(freq_table) * 100
  } else if (is_date) {
    stats$min_date <- min(var_data, na.rm = TRUE)
    stats$max_date <- max(var_data, na.rm = TRUE)
    stats$range_days <- as.numeric(difftime(max(var_data, na.rm = TRUE), 
                                          min(var_data, na.rm = TRUE), 
                                          units = "days"))
  }
  
  # Sélectionner les meilleures visualisations
  viz_recommendations <- list()
  
  if (is_numeric) {
    # Pour les données numériques
    viz_recommendations <- list(
      primary = list(
        type = "histogram",
        title = "Distribution (Histogramme)",
        description = "Montre la fréquence des valeurs dans différents intervalles."
      ),
      secondary = list(
        type = "boxplot",
        title = "Boîte à moustaches",
        description = "Affiche médianes, quartiles et valeurs aberrantes."
      ),
      tertiary = list(
        type = "density",
        title = "Courbe de densité",
        description = "Estimation continue de la distribution des données."
      )
    )
  } else if (is_categorical) {
    # Pour les données catégorielles
    viz_recommendations <- list(
      primary = list(
        type = "bar",
        title = "Diagramme à barres",
        description = "Affiche la fréquence de chaque catégorie."
      ),
      secondary = list(
        type = if(stats$n_unique <= 7) "pie" else "treemap",
        title = if(stats$n_unique <= 7) "Diagramme circulaire" else "Treemap",
        description = if(stats$n_unique <= 7) 
                    "Représentation proportionnelle du total." else
                    "Visualisation hiérarchique des proportions."
      ),
      tertiary = list(
        type = "waffle",
        title = "Diagramme Waffle",
        description = "Représentation sous forme de grille de proportions."
      )
    )
  } else if (is_date) {
    # Pour les données temporelles
    viz_recommendations <- list(
      primary = list(
        type = "timeline",
        title = "Ligne temporelle",
        description = "Montre la distribution des événements dans le temps."
      ),
      secondary = list(
        type = "calendar",
        title = "Calendrier Heat Map",
        description = "Visualise les fréquences par jour dans un format calendrier."
      ),
      tertiary = list(
        type = "periodicity",
        title = "Analyse de périodicité",
        description = "Révèle les tendances cycliques (hebdomadaires, mensuelles, etc.)."
      )
    )
  }
  
  # Créer l'UI avec les visualisations et les insights
  tagList(
    # En-tête avec statistiques et insights
    div(class = "row mb-4",
        div(class = "col-md-12",
            div(class = "card bg-light",
                div(class = "card-header bg-primary text-white",
                    h4("AI-Viz: Analyse intelligente de ", strong(var_name))
                ),
                div(class = "card-body",
                    div(class = "row",
                        # Statistiques
                        div(class = "col-md-4",
                            h5("Statistiques clés"),
                            render_smart_stats(stats, is_numeric, is_categorical, is_date)
                        ),
                        # Insights
                        div(class = "col-md-4",
                            h5("Insights automatiques"),
                            generate_smart_insights(var_data, stats, is_numeric, is_categorical, is_date)
                        ),
                        # Recommandations
                        div(class = "col-md-4",
                            h5("Recommandations"),
                            generate_recommendations(var_data, stats, is_numeric, is_categorical, is_date)
                        )
                    )
                )
            )
        )
    ),
    
    # Visualisations principales
    div(class = "row mb-4",
        # Visualisation primaire (grande)
        div(class = "col-md-8",
            div(class = "card h-100",
                div(class = "card-header d-flex justify-content-between",
                    h5(viz_recommendations$primary$title),
                    div(
                        downloadButton(paste0("download_", viz_recommendations$primary$type),
                                     "Télécharger", class = "btn-sm btn-outline-primary")
                    )
                ),
                div(class = "card-body viz-container",
                    p(class = "text-muted small", viz_recommendations$primary$description),
                    uiOutput(paste0("smart_viz_", viz_recommendations$primary$type))
                )
            )
        ),
        # Visualisations secondaires (petites)
        div(class = "col-md-4",
            div(class = "row",
                div(class = "col-md-12 mb-3",
                    div(class = "card h-100",
                        div(class = "card-header",
                            h6(viz_recommendations$secondary$title)
                        ),
                        div(class = "card-body viz-container-sm",
                            uiOutput(paste0("smart_viz_", viz_recommendations$secondary$type))
                        )
                    )
                ),
                div(class = "col-md-12",
                    div(class = "card h-100",
                        div(class = "card-header",
                            h6(viz_recommendations$tertiary$title)
                        ),
                        div(class = "card-body viz-container-sm",
                            uiOutput(paste0("smart_viz_", viz_recommendations$tertiary$type))
                        )
                    )
                )
            )
        )
    ),
    
    # Options de personnalisation
    div(class = "row mb-3",
        div(class = "col-md-12",
            div(class = "card",
                div(class = "card-header",
                    h5("Options de personnalisation")
                ),
                div(class = "card-body",
                    div(class = "row",
                        div(class = "col-md-3",
                            colourInput("viz_color", "Couleur principale:", 
                                       value = "#3498db", allowTransparent = TRUE)
                        ),
                        div(class = "col-md-3",
                            sliderInput("viz_alpha", "Transparence:",
                                       min = 0, max = 1, value = 0.7, step = 0.1)
                        ),
                        div(class = "col-md-3",
                            selectInput("viz_theme", "Thème:",
                                       choices = c("Minimaliste" = "minimal", 
                                                  "Classique" = "classic",
                                                  "Sombre" = "dark",
                                                  "Clair" = "light"),
                                       selected = "minimal")
                        ),
                        div(class = "col-md-3",
                            div(class = "d-flex align-items-end h-100 mb-3",
                                actionButton("refresh_viz", "Actualiser", class = "btn-primary")
                            )
                        )
                    )
                )
            )
        )
    ),
    
    # Téléchargement de toutes les visualisations
    div(class = "row",
        div(class = "col-md-12 text-center",
            downloadButton("download_all_viz", "Télécharger toutes les visualisations (ZIP)")
        )
    )
  )
})

# Fonctions auxiliaires pour l'UI
render_smart_stats <- function(stats, is_numeric, is_categorical, is_date) {
  if (is_numeric) {
    tags$ul(
      tags$li(strong("Moyenne:"), round(stats$mean, 2)),
      tags$li(strong("Médiane:"), round(stats$median, 2)),
      tags$li(strong("Écart-type:"), round(stats$sd, 2)),
      tags$li(strong("Min:"), round(stats$min, 2)),
      tags$li(strong("Max:"), round(stats$max, 2)),
      tags$li(strong("Valeurs manquantes:"), 
             paste0(stats$missing, " (", round(stats$missing_pct, 1), "%)"))
    )
  } else if (is_categorical) {
    tags$ul(
      tags$li(strong("Catégories uniques:"), stats$n_unique),
      tags$li(strong("Mode:"), stats$mode),
      tags$li(strong("Fréquence du mode:"), 
             paste0(stats$mode_freq, " (", round(stats$mode_pct, 1), "%)")),
      tags$li(strong("Valeurs manquantes:"), 
             paste0(stats$missing, " (", round(stats$missing_pct, 1), "%)"))
    )
  } else if (is_date) {
    tags$ul(
      tags$li(strong("Date min:"), as.character(stats$min_date)),
      tags$li(strong("Date max:"), as.character(stats$max_date)),
      tags$li(strong("Étendue:"), paste(round(stats$range_days), "jours")),
      tags$li(strong("Valeurs manquantes:"), 
             paste0(stats$missing, " (", round(stats$missing_pct, 1), "%)"))
    )
  } else {
    tags$p("Statistiques non disponibles pour ce type de variable.")
  }
}

generate_smart_insights <- function(var_data, stats, is_numeric, is_categorical, is_date) {
  insights <- tags$ul()
  
  if (is_numeric) {
    # Insights pour données numériques
    insights <- tags$ul(
      tags$li(if(stats$mean > stats$median) 
             "Distribution asymétrique positive (tirée vers la droite)" else
             "Distribution asymétrique négative (tirée vers la gauche)"),
      tags$li(if(stats$sd / abs(stats$mean) > 0.5) 
             "Forte variabilité relative" else
             "Faible variabilité relative"),
      tags$li(if(length(boxplot(var_data, plot = FALSE)$out) > 0) 
             "Présence de valeurs aberrantes détectées" else
             "Pas de valeurs aberrantes significatives")
    )
  } else if (is_categorical) {
    # Insights pour données catégorielles
    insights <- tags$ul(
      tags$li(if(stats$mode_pct > 50) 
             "Une catégorie dominante (>50%)" else
             "Distribution sans catégorie dominante"),
      tags$li(if(stats$n_unique > 10) 
             "Variable avec beaucoup de catégories" else
             "Variable avec peu de catégories"),
      tags$li(if(stats$missing_pct > 5) 
             "Attention: nombre important de valeurs manquantes" else
             "Peu de valeurs manquantes")
    )
  } else if (is_date) {
    # Insights pour données temporelles
    insights <- tags$ul(
      tags$li(if(stats$range_days > 365) 
             "Données couvrant plusieurs années" else
             "Données sur moins d'un an"),
      tags$li(if(as.Date(stats$max_date) >= Sys.Date() - 30) 
             "Données récentes (dernier mois)" else
             "Données potentiellement anciennes"),
      tags$li("Recommandation: analyser la périodicité et tendances")
    )
  }
  
  return(insights)
}

generate_recommendations <- function(var_data, stats, is_numeric, is_categorical, is_date) {
  if (is_numeric) {
    tags$ul(
      tags$li("Comparer avec d'autres variables numériques (corrélation)"),
      tags$li("Standardiser si nécessaire pour comparer les échelles"),
      tags$li(if(stats$missing_pct > 0) 
             "Considérer l'imputation des valeurs manquantes" else
             "Les données sont complètes")
    )
  } else if (is_categorical) {
    tags$ul(
      tags$li(if(stats$n_unique > 15) 
             "Regrouper les catégories les moins fréquentes" else
             "Bon niveau de détail catégoriel"),
      tags$li("Analyser la relation avec variables cibles"),
      tags$li(if(stats$missing_pct > 0) 
             "Évaluer si les données manquantes suivent un pattern" else
             "Les données sont complètes")
    )
  } else if (is_date) {
    tags$ul(
      tags$li("Extraire année/mois/jour pour analyses spécifiques"),
      tags$li("Examiner la saisonnalité et les tendances"),
      tags$li("Créer des variables relatives (jours depuis...)"),
      tags$li(if(as.Date(stats$max_date) < Sys.Date() - 180) 
             "Vérifier si données nécessitent mise à jour" else
             "Données temporellement pertinentes")
    )
  } else {
    tags$p("Recommandations non disponibles pour ce type de variable.")
  }
}

# Fonction pour créer les visualisations basiques avec highcharter
create_smart_viz_outputs <- function() {
  # Générer des outputs pour différentes visualisations
  
  # Histogramme
  output$smart_viz_histogram <- renderUI({
    req(rv$clean_data, input$vis_var)
    var_data <- rv$clean_data[[input$vis_var]]
    
    if (!is.numeric(var_data)) {
      return(tags$div("Type de données incompatible avec cette visualisation"))
    }
    
    # Créer avec plotly
    p <- renderPlotly({
      # Filtrer les valeurs NA
      data_clean <- var_data[!is.na(var_data)]
      
      # Créer l'histogramme
      plot_ly(x = data_clean, type = "histogram", 
             marker = list(color = input$viz_color, 
                          opacity = input$viz_alpha)) %>%
        layout(title = paste("Distribution de", input$vis_var),
               xaxis = list(title = input$vis_var),
               yaxis = list(title = "Fréquence"))
    })
    
    # Encapsuler dans un div
    div(
      plotlyOutput(p, height = "300px")
    )
  })
  
  # Plus de visualisations seraient implémentées ici de manière similaire...
}

# Initialiser les outputs de visualisation
create_smart_viz_outputs()

# Fonction pour l'export de toutes les visualisations
output$download_all_viz <- downloadHandler(
  filename = function() {
    paste0("visualisations_", input$vis_var, "_", format(Sys.time(), "%Y%m%d%H%M%S"), ".zip")
  },
  content = function(file) {
    # Créer un dossier temporaire
    temp_dir <- tempdir()
    viz_dir <- file.path(temp_dir, "visualizations")
    if (!dir.exists(viz_dir)) dir.create(viz_dir)
    
    # Sauvegarder les visualisations principales
    # (Implémentation à compléter)
    
    # Créer un zip avec toutes les visualisations
    zip(file, viz_dir)
    
    # Nettoyer
    unlink(viz_dir, recursive = TRUE)
  }
)

# Gestionnaire pour l'exportation du tableau
output$export_table <- downloadHandler(
  filename = function() {
    # Créer un nom de fichier avec la date et l'heure
    base_name <- "tableau_statistique"
    date_str <- format(Sys.time(), "%Y%m%d_%H%M%S")
    
    # Extension selon le format choisi
    ext <- switch(input$export_format,
                 "xlsx" = ".xlsx",
                 "csv" = ".csv",
                 "html" = ".html",
                 "pdf" = ".pdf",
                 ".xlsx") # Par défaut
    
    paste0(base_name, "_", date_str, ext)
  },
  content = function(file) {
    # Vérifier qu'il y a un tableau à exporter
    if (is.null(rv$gtsumm_table)) {
      showNotification("Aucun tableau à exporter. Veuillez d'abord créer un tableau.",
                      type = "error")
      return()
    }
    
    # Afficher l'indicateur de chargement
    session$userData$show_loading()
    
    tryCatch({
      # Exportation selon le format choisi
      if (input$export_format == "xlsx") {
        # Récupérer les données tabulaires
        export_data <- rv$tabyl_data
        
        # Vérifier que des données sont disponibles
        if (is.null(export_data) || nrow(export_data) == 0) {
          export_data <- data.frame(Message = "Aucune donnée disponible")
        }
        
        # Exporter en Excel
        writexl::write_xlsx(export_data, path = file)
        
      } else if (input$export_format == "csv") {
        # Récupérer les données tabulaires
        export_data <- rv$tabyl_data
        
        # Vérifier que des données sont disponibles
        if (is.null(export_data) || nrow(export_data) == 0) {
          export_data <- data.frame(Message = "Aucune donnée disponible")
        }
        
        # Exporter en CSV
        write.csv(export_data, file = file, row.names = FALSE)
        
      } else if (input$export_format == "html") {
        # Exporter le tableau GT en HTML
        gt_table <- rv$gtsumm_table
        
        # Écrire le HTML dans un fichier
        html_content <- gt::as_raw_html(gt_table)
        write(html_content, file)
        
      } else if (input$export_format == "pdf") {
        # Pour le PDF, on utilise le package webshot pour capturer le HTML
        # Vérifier que le package est installé
        if (!requireNamespace("webshot", quietly = TRUE)) {
          stop("Le package 'webshot' est nécessaire pour l'export en PDF. Installez-le avec 'install.packages(\"webshot\")'")
        }
        
        # Créer un fichier HTML temporaire
        temp_html <- tempfile(fileext = ".html")
        gt_table <- rv$gtsumm_table
        html_content <- gt::as_raw_html(gt_table)
        write(html_content, temp_html)
        
        # Convertir HTML en PDF
        webshot::webshot(temp_html, file = file, delay = 0.5)
        
        # Nettoyer
        unlink(temp_html)
      }
      
      # Notification de succès
      showNotification(paste("Tableau exporté avec succès en format", toupper(input$export_format)),
                      type = "message")
      
    }, error = function(e) {
      # En cas d'erreur
      showNotification(paste("Erreur lors de l'exportation:", e$message),
                      type = "error")
    }, finally = {
      # Masquer l'indicateur de chargement
      session$userData$hide_loading()
    })
  }
)

# Fonction pour créer un tableau de comparaison avant/après
generate_comparison_table <- function(data_original, data_cleaned, selected_vars) {
  # Vérifier que les données existent
  if (is.null(data_original) || is.null(data_cleaned) || length(selected_vars) == 0) {
    return(NULL)
  }
  
  # Initialiser les résultats
  comparison_results <- list()
  
  # Pour chaque variable sélectionnée
  for (var in selected_vars) {
    # Vérifier que la variable existe dans les deux jeux de données
    if (!(var %in% names(data_original)) || !(var %in% names(data_cleaned))) {
      next
    }
    
    # Extraire les données pour cette variable
    original_data <- data_original[[var]]
    cleaned_data <- data_cleaned[[var]]
    
    # Calculer les statistiques en fonction du type de variable
    if (is.numeric(cleaned_data)) {
      # Pour les variables numériques
      stats <- data.frame(
        Métrique = c("N", "Manquants", "Moyenne", "Médiane", "Écart-type", "Min", "Max"),
        Original = c(
          length(original_data),
          sum(is.na(original_data)),
          round(mean(original_data, na.rm = TRUE), 2),
          round(median(original_data, na.rm = TRUE), 2),
          round(sd(original_data, na.rm = TRUE), 2),
          round(min(original_data, na.rm = TRUE), 2),
          round(max(original_data, na.rm = TRUE), 2)
        ),
        Nettoyé = c(
          length(cleaned_data),
          sum(is.na(cleaned_data)),
          round(mean(cleaned_data, na.rm = TRUE), 2),
          round(median(cleaned_data, na.rm = TRUE), 2),
          round(sd(cleaned_data, na.rm = TRUE), 2),
          round(min(cleaned_data, na.rm = TRUE), 2),
          round(max(cleaned_data, na.rm = TRUE), 2)
        )
      )
    } else {
      # Pour les variables catégorielles
      original_freq <- table(original_data, useNA = "always")
      cleaned_freq <- table(cleaned_data, useNA = "always")
      
      # Gestion du cas où aucun niveau n'est disponible
      if (length(original_freq) == 0 || all(is.na(names(original_freq)))) {
        original_mode <- "N/A"
      } else {
        original_mode <- names(which.max(original_freq[!is.na(names(original_freq))]))
        if (length(original_mode) == 0) original_mode <- "N/A"
      }
      
      if (length(cleaned_freq) == 0 || all(is.na(names(cleaned_freq)))) {
        cleaned_mode <- "N/A"
      } else {
        cleaned_mode <- names(which.max(cleaned_freq[!is.na(names(cleaned_freq))]))
        if (length(cleaned_mode) == 0) cleaned_mode <- "N/A"
      }
      
      stats <- data.frame(
        Métrique = c("N", "Manquants", "Niveaux", "Mode"),
        Original = c(
          length(original_data),
          sum(is.na(original_data)),
          length(unique(original_data[!is.na(original_data)])),
          original_mode
        ),
        Nettoyé = c(
          length(cleaned_data),
          sum(is.na(cleaned_data)),
          length(unique(cleaned_data[!is.na(cleaned_data)])),
          cleaned_mode
        )
      )
    }
    
    # Ajouter au résultat
    comparison_results[[var]] <- stats
  }
  
  return(comparison_results)
}

# Fonction pour créer un HTML à partir des résultats de comparaison
comparison_to_html <- function(comparison_results, is_original = TRUE) {
  if (is.null(comparison_results) || length(comparison_results) == 0) {
    return("<div class='alert alert-warning'>Aucune donnée disponible pour la comparaison</div>")
  }
  
  # Créer le HTML pour chaque variable
  html_parts <- lapply(names(comparison_results), function(var_name) {
    stats <- comparison_results[[var_name]]
    
    # Sélectionner la colonne appropriée (Original ou Nettoyé)
    col_idx <- if (is_original) 2 else 3
    
    # Créer le tableau HTML
    table_html <- paste0(
      "<div class='panel panel-default'>",
      "<div class='panel-heading'><h5>", var_name, "</h5></div>",
      "<div class='panel-body'>",
      "<table class='table table-striped table-bordered'>",
      "<thead><tr><th>Métrique</th><th>Valeur</th></tr></thead>",
      "<tbody>"
    )
    
    # Ajouter chaque ligne
    for (i in 1:nrow(stats)) {
      table_html <- paste0(
        table_html,
        "<tr><td>", stats$Métrique[i], "</td><td>", stats[i, col_idx], "</td></tr>"
      )
    }
    
    # Fermer le tableau
    table_html <- paste0(
      table_html,
      "</tbody></table></div></div>"
    )
    
    return(table_html)
  })
  
  # Combiner toutes les parties
  final_html <- paste(html_parts, collapse = "<br>")
  
  return(final_html)
}

# Observer pour générer la comparaison
observeEvent(input$refresh_comparison, {
  # Afficher un message d'initialisation
  output$comparison_original <- renderUI({
    HTML("<div class='alert alert-info'>Chargement de la comparaison...</div>")
  })
  
  output$comparison_cleaned <- renderUI({
    HTML("<div class='alert alert-info'>Chargement de la comparaison...</div>")
  })
  
  # Vérifier que les données nécessaires sont disponibles
  if (is.null(rv$original_data)) {
    showNotification("Données originales non disponibles. Veuillez d'abord activer la comparaison.", type = "error")
    
    output$comparison_original <- renderUI({
      HTML("<div class='alert alert-danger'>Données originales non disponibles</div>")
    })
    return()
  }
  
  if (is.null(rv$clean_data)) {
    showNotification("Données nettoyées non disponibles.", type = "error")
    
    output$comparison_cleaned <- renderUI({
      HTML("<div class='alert alert-danger'>Données nettoyées non disponibles</div>")
    })
    return()
  }
  
  if (length(input$tabyl_vars) == 0) {
    showNotification("Aucune variable sélectionnée pour la comparaison.", type = "warning")
    
    output$comparison_original <- renderUI({
      HTML("<div class='alert alert-warning'>Sélectionnez au moins une variable à comparer</div>")
    })
    
    output$comparison_cleaned <- renderUI({
      HTML("<div class='alert alert-warning'>Sélectionnez au moins une variable à comparer</div>")
    })
    return()
  }
  
  # Afficher l'indicateur de chargement
  session$userData$show_loading()
  
  tryCatch({
    # Générer les résultats de comparaison
    comparison_results <- generate_comparison_table(
      rv$original_data, 
      rv$clean_data, 
      input$tabyl_vars
    )
    
    # Vérifier si des résultats ont été générés
    if (is.null(comparison_results) || length(comparison_results) == 0) {
      showNotification("Aucun résultat de comparaison généré.", type = "warning")
      
      output$comparison_original <- renderUI({
        HTML("<div class='alert alert-warning'>Aucun résultat disponible pour la comparaison</div>")
      })
      
      output$comparison_cleaned <- renderUI({
        HTML("<div class='alert alert-warning'>Aucun résultat disponible pour la comparaison</div>")
      })
      return()
    }
    
    # Mettre à jour les sorties HTML
    output$comparison_original <- renderUI({
      HTML(comparison_to_html(comparison_results, is_original = TRUE))
    })
    
    output$comparison_cleaned <- renderUI({
      HTML(comparison_to_html(comparison_results, is_original = FALSE))
    })
    
    showNotification("Comparaison mise à jour", type = "message")
    
  }, error = function(e) {
    showNotification(paste("Erreur lors de la comparaison:", e$message), type = "error")
    cat("Erreur dans la comparaison:", e$message, "\n")
    
    output$comparison_original <- renderUI({
      HTML(paste0("<div class='alert alert-danger'>Erreur: ", e$message, "</div>"))
    })
    
    output$comparison_cleaned <- renderUI({
      HTML(paste0("<div class='alert alert-danger'>Erreur: ", e$message, "</div>"))
    })
  }, finally = {
    # Masquer l'indicateur de chargement
    session$userData$hide_loading()
  })
})

# Observer quand la case à cocher de comparaison est activée
observeEvent(input$enable_comparison, {
  if (input$enable_comparison) {
    # Vérifier si les données originales sont disponibles
    if (is.null(rv$original_data)) {
      # Stocker les données actuelles comme données originales
      rv$original_data <- rv$clean_data
      showNotification("Les données actuelles ont été définies comme référence pour la comparaison", 
                      type = "message")
    }
    
    # Déclencher la mise à jour de la comparaison
    if (!is.null(rv$original_data) && !is.null(rv$clean_data) && length(input$tabyl_vars) > 0) {
      shinyjs::delay(300, {
        session$sendCustomMessage(type = "triggerButtonClick", message = "refresh_comparison")
      })
    }
  }
})
