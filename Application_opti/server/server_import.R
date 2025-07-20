# server/server_import.R

observeEvent(input$file_input, {
  req(input$file_input)
  
  tryCatch({
    # Afficher le loader (avec shinyjs)
    shinyjs::show("loading_page")
    session$userData$show_loading()
    
    ext <- tolower(tools::file_ext(input$file_input$name))
    path <- input$file_input$datapath
    
    # Créer un fichier temporaire FST
    fst_path <- tempfile(fileext = ".fst")
    
    # Lire et convertir en FST selon le format d'origine
    temp_data <- switch(ext,
                        # Formats texte
                        csv = readr::read_delim(path, delim = input$sep, 
                                            col_names = input$header,
                                            locale = readr::locale(decimal_mark = input$dec)),
                        tsv = readr::read_tsv(path, col_names = input$header),
                        txt = readr::read_delim(path, delim = input$sep, 
                                                col_names = input$header,
                                                locale = readr::locale(decimal_mark = input$dec)),
                        tab = readr::read_delim(path, delim = "\t", 
                                                col_names = input$header),
                        
                        # Formats Excel
                        xlsx = readxl::read_excel(path, col_names = input$header),
                        xls = readxl::read_excel(path, col_names = input$header),
                        xlsm = readxl::read_excel(path, col_names = input$header),
                        ods = rio::import(path),
                        
                        # Formats statistiques
                        sav = haven::read_spss(path),
                        dta = haven::read_stata(path),
                        sas7bdat = haven::read_sas(path),
                        
                        # Formats R
                        rds = readRDS(path),
                        rda = {
                          e <- new.env()
                          load(path, envir = e)
                          # Obtenir le premier objet dataframe du fichier RData
                          objs <- ls(envir = e)
                          df_objs <- sapply(objs, function(x) is.data.frame(e[[x]]))
                          if(any(df_objs)) {
                            e[[objs[which(df_objs)[1]]]]
                          } else {
                            stop("Aucun dataframe trouvé dans le fichier RData")
                          }
                        },
                        rdata = {
                          e <- new.env()
                          load(path, envir = e)
                          # Obtenir le premier objet dataframe du fichier RData
                          objs <- ls(envir = e)
                          df_objs <- sapply(objs, function(x) is.data.frame(e[[x]]))
                          if(any(df_objs)) {
                            e[[objs[which(df_objs)[1]]]]
                          } else {
                            stop("Aucun dataframe trouvé dans le fichier RData")
                          }
                        },
                        
                        # Formats Big Data
                        parquet = arrow::read_parquet(path),
                        feather = arrow::read_feather(path),
                        fst = fst::read_fst(path),
                        
                        # Autres formats
                        json = jsonlite::fromJSON(path, simplifyDataFrame = TRUE),
                        xml = {
                          xmldata <- xml2::read_xml(path)
                          # Tentative simple de conversion en dataframe
                          tryCatch({
                            xml2::as_list(xmldata) %>% 
                              lapply(function(x) as.data.frame(t(unlist(x)))) %>%
                              data.table::rbindlist(fill = TRUE)
                          }, error = function(e) {
                            stop(paste("Conversion XML en dataframe échouée:", e$message))
                          })
                        },
                        html = {
                          # Tenter d'extraire des tableaux HTML
                          tables <- rvest::html_table(rvest::read_html(path))
                          if(length(tables) > 0) {
                            tables[[1]]  # Prendre le premier tableau
                          } else {
                            stop("Aucun tableau trouvé dans le fichier HTML")
                          }
                        },
                        sqlite = {
                          con <- DBI::dbConnect(RSQLite::SQLite(), dbname = path)
                          tables <- DBI::dbListTables(con)
                          if(length(tables) > 0) {
                            data <- DBI::dbReadTable(con, tables[1])
                            DBI::dbDisconnect(con)
                            data
                          } else {
                            DBI::dbDisconnect(con)
                            stop("Aucune table trouvée dans la base SQLite")
                          }
                        },
                        db = {
                          con <- DBI::dbConnect(RSQLite::SQLite(), dbname = path)
                          tables <- DBI::dbListTables(con)
                          if(length(tables) > 0) {
                            data <- DBI::dbReadTable(con, tables[1])
                            DBI::dbDisconnect(con)
                            data
                          } else {
                            DBI::dbDisconnect(con)
                            stop("Aucune table trouvée dans la base de données")
                          }
                        },
                        
                        # Format par défaut - utiliser rio qui est très polyvalent
                        rio::import(path, setclass = "data.frame")
    )
    
    # Si le fichier n'était pas déjà au format FST, on le convertit
    if (ext != "fst") {
      # Assurer que le résultat est bien un data.frame
      if (!is.data.frame(temp_data)) {
        temp_data <- as.data.frame(temp_data)
      }
      fst::write_fst(temp_data, fst_path)
      rv$fst_path <- fst_path  # Stocker le chemin pour nettoyage ultérieur
    }
    
    # Lire depuis le FST (mémoire mapping)
    rv$raw_data <- fst::read_fst(fst_path, as.data.table = TRUE) %>% 
      as_tibble()
    
    # Nettoyage des données
    if (!is.data.frame(rv$raw_data)) {
      rv$raw_data <- as.data.frame(rv$raw_data)
    }
    
    rv$raw_data <- rv$raw_data %>%
      mutate(across(where(~inherits(., "haven_labelled")), haven::as_factor))
    
    rv$clean_data <- rv$raw_data
    
    # Réinitialiser l'historique
    rv$history <- list()
    rv$history_index <- 0
    
    # Sauvegarder l'état initial
    save_state()
    
    # Mise à jour des UI
    updateSelectInput(session, "plot_var", choices = names(rv$clean_data))
    updateSelectInput(session, "datetime_col", choices = names(rv$clean_data))
    updateSelectizeInput(session, "dupe_cols", choices = names(rv$clean_data))
    updateSelectizeInput(session, "tabyl_vars", choices = names(rv$clean_data))
    
    # Journaliser
    log_action(paste("Importation de", input$file_input$name, "- Format:", ext))
    
    # Signal sonore (optionnel)
    beepr::beep(10)
    
    # Afficher notification de succès
    showNotification(paste("Fichier", input$file_input$name, "importé avec succès"), type = "message")
    
  }, error = function(e) {
    showNotification(paste("Erreur lors du chargement:", e$message), type = "error")
    rv$raw_data <- data.frame()
    rv$clean_data <- data.frame()
  }, finally = {
    # Cacher le loader
    shinyjs::hide("loading_page")
    session$userData$hide_loading()
  })
})

# Ajouter les tooltips pour les formats
observeEvent(input$main_navbar, {
  if(input$main_navbar == "Importation") {
    shinyjs::runjs('
      $(document).ready(function() {
        $(".format-list .badge").tooltip({
          title: function() {
            var format = $(this).text().toLowerCase();
            switch(format) {
              case "csv": return "Fichiers de valeurs séparées par des virgules";
              case "tsv": return "Fichiers de valeurs séparées par des tabulations";
              case "txt": return "Fichiers texte avec séparateur personnalisable";
              case "excel": return "Fichiers Microsoft Excel (.xlsx, .xls, .xlsm)";
              case "ods": return "Fichiers OpenDocument Spreadsheet";
              case "sas": return "Fichiers SAS (.sas7bdat)";
              case "spss": return "Fichiers SPSS (.sav)";
              case "stata": return "Fichiers Stata (.dta)";
              case "rds": return "Fichiers R Data Serialized";
              case "rdata": return "Fichiers de données R (.rda, .rdata)";
              case "json": return "Fichiers JavaScript Object Notation";
              case "xml": return "Fichiers eXtensible Markup Language";
              case "parquet": return "Format colonnaire Apache Parquet";
              case "feather": return "Format rapide Arrow Feather";
              case "fst": return "Format de stockage ultrarapide pour R";
              case "sqlite": return "Bases de données SQLite";
              default: return "Format de fichier pris en charge";
            }
          },
          placement: "top",
          trigger: "hover"
        });
      });
    ')
  }
})

# Nettoyage des fichiers temporaires lors de la fermeture de la session
session$onSessionEnded(function() {
  if (!is.null(isolate(rv$fst_path)) && file.exists(isolate(rv$fst_path))) {
    file.remove(isolate(rv$fst_path))
  }
})

# Affichage des données brutes
output$raw_table <- renderDT({
  req(rv$raw_data)
  datatable(rv$raw_data,
            options = list(scrollX = TRUE, pageLength = 5, dom = 'Bfrtip', 
                           buttons = c('copy', 'csv', 'excel')),
            extensions = 'Buttons', rownames = FALSE)
})

# Résumé des données
output$data_summary <- renderPrint({
  req(rv$raw_data)
  cat("Dimensions:", dim(rv$raw_data)[1], "lignes x", dim(rv$raw_data)[2], "colonnes\n")
  cat("\nStructure:\n")
  str(rv$raw_data)
})

# Types de données
output$data_types <- renderPrint({
  req(rv$raw_data)
  cat("\nTypes de données:\n")
  sapply(rv$raw_data, class) %>% print()
})

# Réinitialisation des données
observeEvent(input$reset_data, {
  # Nettoyage du fichier FST temporaire
  if (!is.null(isolate(rv$fst_path)) && file.exists(isolate(rv$fst_path))) {
    file.remove(isolate(rv$fst_path))
  }
  
  # Réinitialisation des valeurs réactives
  rv$raw_data <- data.frame()
  rv$clean_data <- data.frame()
  rv$tabyl_data <- NULL
  rv$dupes_data <- NULL
  rv$comparison_data <- NULL
  rv$fst_path <- NULL
  
  # Réinitialiser l'historique
  rv$history <- list()
  rv$history_index <- 0
  
  # Réinitialisation des inputs
  reset("file_input")
  updateSelectInput(session, "plot_var", choices = character(0))
  updateSelectInput(session, "datetime_col", choices = character(0))
  updateSelectizeInput(session, "dupe_cols", choices = character(0))
  updateSelectizeInput(session, "tabyl_vars", choices = character(0))
  
  beepr::beep(10) # Signal sonore
})