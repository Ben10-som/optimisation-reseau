# Calcul de la taille estimée du fichier d'export
output$export_size_info <- renderUI({
  req(rv$clean_data)
  
  # Calculer la taille approximative en mémoire
  data_size_bytes <- as.numeric(object.size(rv$clean_data))
  
  # Estimation de la taille compressée selon le format
  compression_factor <- switch(input$export_format,
                              "csv" = 1.0,  # Pas de compression
                              "xlsx" = 0.8, # Légère compression
                              "rds" = 0.7,
                              "fst" = 0.5 * (1 - (input$compression_level/100)),
                              "parquet" = 0.4 * (1 - (input$compression_level/150)),
                              "zip" = 0.3 * (1 - (input$compression_level/120)),
                              "gz" = 0.25 * (1 - (input$compression_level/150)),
                              0.9)  # Par défaut
  
  estimated_size <- data_size_bytes * compression_factor
  
  # Convertir en unités lisibles
  size_text <- if(estimated_size < 1024) {
    paste0(round(estimated_size, 0), " B")
  } else if(estimated_size < 1024^2) {
    paste0(round(estimated_size/1024, 1), " KB")
  } else if(estimated_size < 1024^3) {
    paste0(round(estimated_size/1024^2, 1), " MB")
  } else {
    paste0(round(estimated_size/1024^3, 2), " GB")
  }
  
  # Afficher l'avertissement pour les gros fichiers
  warning_msg <- if(estimated_size > 100*1024^2) {  # Si plus de 100 MB
    tags$div(class = "alert alert-warning",
             icon("exclamation-triangle"),
             "Attention: Fichier volumineux. L'export peut prendre du temps.")
  } else {
    NULL
  }
  
  # Renvoyer l'interface
  tags$div(
    tags$div(class = "alert alert-info",
             icon("info-circle"),
             "Taille estimée du fichier: ", tags$b(size_text)),
    warning_msg
  )
})

output$download_data <- downloadHandler(
  filename = function() {
    paste(input$export_filename,
          switch(input$export_format,
                 "csv" = ".csv",
                 "xlsx" = ".xlsx",
                 "rds" = ".rds",
                 "sav" = ".sav",
                 "dta" = ".dta",
                 "feather" = ".feather",
                 "fst" = ".fst",
                 "parquet" = ".parquet",
                 "json" = ".json",
                 "zip" = ".zip",
                 "gz" = ".gz"),
          sep = "")
  },
  content = function(file) {
    req(rv$clean_data)
    
    # Affichage de l'indicateur de chargement global
    session$userData$show_loading()
    
    tryCatch({
      # Créer une copie des données pour modification
      export_data <- rv$clean_data
      
      # Nettoyer les noms de variables pour SPSS/Stata si nécessaire
      if(input$export_format %in% c("sav", "dta")) {
        # Remplacer les espaces et caractères spéciaux
        names(export_data) <- gsub("[^[:alnum:]]", "_", names(export_data))
        
        # S'assurer que les noms commencent par une lettre
        names(export_data) <- gsub("^([^[:alpha:]])", "var_\\1", names(export_data))
        
        # Tronquer les noms trop longs (SPSS max 64, Stata max 32)
        max_len <- ifelse(input$export_format == "sav", 64, 32)
        names(export_data) <- substr(names(export_data), 1, max_len)
        
        # S'assurer que les noms sont uniques
        names(export_data) <- make.unique(names(export_data), sep = "_")
      }
      
      # Pour les formats d'archive, créer d'abord un fichier temporaire CSV
      if(input$export_format %in% c("zip", "gz")) {
        # Créer un fichier CSV temporaire
        temp_csv <- tempfile(fileext = ".csv")
        write.csv(export_data, temp_csv, row.names = FALSE, fileEncoding = "UTF-8")
        
        # Compresser le fichier selon le format
        if(input$export_format == "zip") {
          # Comprimer en ZIP
          zip_file <- file
          zip::zip(zip_file, files = temp_csv, recurse = FALSE, compression_level = input$compression_level/10)
        } else if(input$export_format == "gz") {
          # Comprimer en GZ
          R.utils::gzip(temp_csv, destname = file, compression = input$compression_level/11, remove = FALSE)
        }
        
        # Supprimer le fichier temporaire
        unlink(temp_csv)
      } else {
        # Exporter selon le format avec gestion de la compression
        switch(input$export_format,
               "csv" = write.csv(export_data, file, row.names = FALSE, fileEncoding = "UTF-8", 
                                sep = input$csv_sep, col.names = input$csv_header),
               "xlsx" = writexl::write_xlsx(list("Data" = export_data), file),
               "rds" = saveRDS(export_data, file, compress = input$compression_level > 50),
               "sav" = haven::write_sav(export_data, file),
               "dta" = haven::write_dta(export_data, file),
               "feather" = arrow::write_feather(export_data, file),
               "fst" = fst::write_fst(export_data, file, compress = input$compression_level),
               "parquet" = arrow::write_parquet(export_data, file, 
                                               compression = ifelse(input$compression_level > 50, "snappy", "none"),
                                               compression_level = input$compression_level/10),
               "json" = jsonlite::write_json(export_data, file, pretty = TRUE))
      }
      
      showNotification(
        tags$span(icon("check-circle"), "Export réussi"),
        type = "message", 
        duration = 5
      )
    }, error = function(e) {
      showNotification(
        tags$span(icon("exclamation-triangle"), paste("Erreur:", e$message)),
        type = "error",
        duration = NULL
      )
    }, finally = {
      # Masquer l'indicateur de chargement global
      session$userData$hide_loading()
    })
  }
)