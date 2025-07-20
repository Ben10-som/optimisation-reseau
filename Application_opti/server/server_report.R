# server/server_report.R

# Obtenir le chemin du logo personnalisé ou utiliser le logo par défaut
get_logo_path <- function() {
  if (!is.null(input$report_logo)) {
    # Créer un dossier temporaire pour les images
    tmp_dir <- tempdir()
    logo_path <- file.path(tmp_dir, input$report_logo$name)
    
    # Copier le fichier téléchargé vers le dossier temporaire
    file.copy(input$report_logo$datapath, logo_path, overwrite = TRUE)
    
    return(logo_path)
  } else {
    # Utiliser le logo par défaut
    return("www/images/janitor.png")
  }
}

# Aperçu du rapport sélectionné
output$report_preview <- renderUI({
  # Créer des aperçus fictifs pour chaque type de template
  preview_content <- switch(input$report_template,
    standard = div(
      class = "report-preview",
      style = "border: 1px solid #ddd; padding: 15px; background-color: white;",
      h3(style = "text-align: center;", "Aperçu du modèle Standard"),
      hr(),
      div(class = "row", 
          div(class = "col-md-12", h4("Résumé des opérations")),
          div(class = "col-md-12", tags$ul(
            tags$li("Import des données"),
            tags$li("Nettoyage des noms de colonnes"),
            tags$li("Suppression des valeurs manquantes")
          ))
      ),
      div(class = "row", 
          div(class = "col-md-12", h4("Statistiques descriptives")),
          div(class = "col-md-12", div(style = "background: #f8f9fa; padding: 10px; border-radius: 4px;", "Tableau de statistiques"))
      )
    ),
    detailed = div(
      class = "report-preview",
      style = "border: 1px solid #ddd; padding: 15px; background-color: white;",
      h3(style = "text-align: center;", "Aperçu du modèle Détaillé"),
      hr(),
      div(class = "row", 
          div(class = "col-md-12", h4("Analyse détaillée")),
          div(class = "col-md-12", tags$ul(
            tags$li("Analyse complète des distributions"),
            tags$li("Tests statistiques approfondis"),
            tags$li("Visualisations avancées")
          ))
      ),
      div(class = "row", 
          div(class = "col-md-12", h4("Code R généré")),
          div(class = "col-md-12", div(style = "font-family: monospace; background: #f0f0f0; padding: 10px; border-radius: 4px;", "data %>% clean_names() %>% remove_empty()"))
      )
    ),
    minimal = div(
      class = "report-preview",
      style = "border: 1px solid #ddd; padding: 15px; background-color: white;",
      h3(style = "text-align: center;", "Aperçu du modèle Minimal"),
      hr(),
      div(class = "row", 
          div(class = "col-md-12", h4("Résumé concis")),
          div(class = "col-md-12", p("Format épuré présentant uniquement les informations essentielles."))
      ),
      div(class = "row", 
          div(class = "col-md-12", div(style = "background: #f8f9fa; padding: 10px; border-radius: 4px;", "Tableau simplifié"))
      )
    ),
    presentation = div(
      class = "report-preview",
      style = "border: 1px solid #ddd; padding: 15px; background-color: white;",
      h3(style = "text-align: center;", "Aperçu du modèle Présentation"),
      hr(),
      div(class = "row", 
          div(class = "col-md-12", h4("Format diaporama")),
          div(class = "col-md-12", p("Optimisé pour les présentations avec puces et visuels."))
      ),
      div(class = "row", 
          div(class = "col-md-12", div(style = "background: #f8f9fa; padding: 10px; border-radius: 4px; text-align: center;", "Graphique principal"))
      )
    ),
    # Valeur par défaut
    div(
      class = "report-preview",
      style = "border: 1px solid #ddd; padding: 15px; background-color: white;",
      h3(style = "text-align: center;", "Aperçu du modèle Standard"),
      hr(),
      p("Sélectionnez un modèle pour voir l'aperçu")
    )
  )
  
  tagList(
    preview_content,
    br(),
    div(class = paste0("alert alert-info template-", input$report_template),
        icon("info-circle"),
        strong("À propos de ce modèle: "),
        switch(input$report_template,
               standard = "Format standard avec sections bien organisées.",
               detailed = "Format détaillé avec analyses approfondies et statistiques avancées.",
               minimal = "Format minimal, concis et direct.",
               presentation = "Format adapté pour les présentations et diaporamas.",
               "Format standard avec sections bien organisées.")
    )
  )
})

# Gestionnaire de téléchargement
output$download_report <- downloadHandler(
  filename = function() {
    # Extensions selon le format
    ext <- switch(input$report_format,
                 "html" = ".html",
                 "pdf" = ".pdf",
                 "docx" = ".docx")
    
    paste0("rapport-", gsub(" ", "_", tolower(input$report_title)), "-", Sys.Date(), ext)
  },
  content = function(file) {
    # Affichage de l'indicateur de chargement global
    session$userData$show_loading()
    
    tryCatch({
      # Utiliser le modèle de rapport existant, peu importe le type sélectionné
      template_file <- "rmd/rapport.Rmd"
      
      # Options pour chaque format de sortie
      output_format <- switch(input$report_format,
                             "html" = "html_document",
                             "pdf" = paste0("pdf_document"),
                             "docx" = "word_document")
      
      # Options PDF spécifiques
      pdf_options <- NULL
      if (input$report_format == "pdf") {
        pdf_options <- list(
          latex_engine = "xelatex",
          papersize = input$report_paper
        )
      }
      
      # Créer les paramètres pour le rapport - simplifié pour correspondre au YAML
      params <- list(
        logs = rv$logs,
        date = Sys.Date(),
        title = input$report_title,
        author = input$report_author,
        elements = input$report_elements,
        logo = get_logo_path(),
        notes = input$report_notes
      )
      
      # Si des données sont disponibles, ajouter un échantillon
      if (!is.null(rv$clean_data)) {
        params$data_sample <- head(rv$clean_data, 10)
        
        # Ajouter des visualisations si demandé (uniquement si le paramètre est déclaré dans YAML)
        if ("plots" %in% input$report_elements && !is.null(rv$tabyl_data)) {
          params$tabyl_data <- rv$tabyl_data
        }
      }
      
      # Générer le rapport
      rmarkdown::render(
        input = template_file,
        output_format = output_format,
        output_file = file,
        params = params,
        envir = new.env(),
        output_options = pdf_options
      )
      
      showNotification("Rapport généré avec succès", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Erreur lors de la génération du rapport:", e$message), 
                      type = "error")
    }, finally = {
      # Masquer l'indicateur de chargement global
      session$userData$hide_loading()
    })
  }
)
