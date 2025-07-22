# server/server_batch.R

# Initialisation des valeurs réactives pour le traitement par lots
batch_rv <- reactiveValues(
  files = list(),              # Liste des fichiers importés
  processed_data = list(),     # Données après traitement
  current_preview = NULL,      # Fichier actuellement prévisualisé
  logs = character(0),         # Journal des opérations
  recipes = list(),            # Recettes de nettoyage enregistrées
  progress = 0                 # Progression du traitement
)

# Fonction pour ajouter des entrées au journal
log_batch <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  entry <- paste0("[", timestamp, "] ", message)
  batch_rv$logs <- c(entry, batch_rv$logs)
}

# Gestion de l'importation des fichiers par lots - Améliorée pour fiabilité
observeEvent(input$batch_files, {
  req(input$batch_files)
  
  # Réinitialiser les données précédentes
  batch_rv$files <- list()
  batch_rv$processed_data <- list()
  batch_rv$logs <- character(0)
  
  # Journaliser le début de l'importation
  nfiles <- if(is.data.frame(input$batch_files)) nrow(input$batch_files) else 1
  log_batch(paste("Importation de", nfiles, "fichiers"))
  
  # Enregistrer les informations sur les fichiers
  if(is.data.frame(input$batch_files)) {
    # Plusieurs fichiers
    for (i in 1:nrow(input$batch_files)) {
      file_info <- list(
        name = input$batch_files$name[i],
        path = input$batch_files$datapath[i],
        size = input$batch_files$size[i],
        type = tolower(tools::file_ext(input$batch_files$name[i]))
      )
      batch_rv$files[[i]] <- file_info
      log_batch(paste("Fichier importé:", file_info$name, "(", round(file_info$size/1024), "Ko )"))
    }
  } else {
    # Un seul fichier
    file_info <- list(
      name = input$batch_files$name,
      path = input$batch_files$datapath,
      size = input$batch_files$size,
      type = tolower(tools::file_ext(input$batch_files$name))
    )
    batch_rv$files[[1]] <- file_info
    log_batch(paste("Fichier importé:", file_info$name, "(", round(file_info$size/1024), "Ko )"))
  }
})

# Résumé des fichiers importés
output$batch_summary <- renderPrint({
  req(batch_rv$files)
  
  cat("Résumé du traitement par lots\n")
  cat("----------------------------\n")
  cat("Nombre de fichiers:", length(batch_rv$files), "\n\n")
  
  if (length(batch_rv$files) > 0) {
    for (i in 1:length(batch_rv$files)) {
      file <- batch_rv$files[[i]]
      cat(paste0(i, ". ", file$name, " (", file$type, ", ", round(file$size/1024), " Ko)\n"))
    }
  }
  
  if (length(input$batch_operations) > 0) {
    cat("\nOpérations sélectionnées:\n")
    for (op in input$batch_operations) {
      cat(paste0("- ", op, "\n"))
    }
  } else {
    cat("\nAucune opération sélectionnée.")
  }
})

# Journal des opérations
output$batch_logs <- renderPrint({
  req(batch_rv$logs)
  cat(paste(batch_rv$logs, collapse = "\n"))
})

# Fonction pour collecter toutes les opérations sélectionnées
get_all_operations <- function() {
  basic_ops <- if (!is.null(input$batch_operations_basic)) input$batch_operations_basic else c()
  filter_ops <- if (!is.null(input$batch_operations_filter)) input$batch_operations_filter else c()
  transform_ops <- if (!is.null(input$batch_operations_transform)) input$batch_operations_transform else c()
  advanced_ops <- if (!is.null(input$batch_operations_advanced)) input$batch_operations_advanced else c()
  
  c(basic_ops, filter_ops, transform_ops, advanced_ops)
}

# Fonction pour traiter un seul fichier
process_file <- function(file_info) {
  # Import du fichier selon son type
  tryCatch({
    data <- switch(file_info$type,
                 # Formats texte
                 csv = readr::read_delim(file_info$path, 
                                        delim = input$batch_sep, 
                                        col_names = input$batch_header,
                                        locale = readr::locale(decimal_mark = input$batch_dec)),
                 tsv = readr::read_tsv(file_info$path, col_names = input$batch_header),
                 txt = readr::read_delim(file_info$path, 
                                        delim = input$batch_sep, 
                                        col_names = input$batch_header,
                                        locale = readr::locale(decimal_mark = input$batch_dec)),
                 tab = readr::read_delim(file_info$path, 
                                        delim = "\t", 
                                        col_names = input$batch_header),
                 # Formats Excel
                 xlsx = readxl::read_excel(file_info$path, col_names = input$batch_header),
                 xls = readxl::read_excel(file_info$path, col_names = input$batch_header),
                 xlsm = readxl::read_excel(file_info$path, col_names = input$batch_header),
                 ods = rio::import(file_info$path),
                 # Formats statistiques
                 sas7bdat = haven::read_sas(file_info$path),
                 sav = haven::read_spss(file_info$path),
                 dta = haven::read_stata(file_info$path),
                 # Formats R
                 rds = readRDS(file_info$path),
                 rda = {
                   e <- new.env()
                   load(file_info$path, envir = e)
                   # Obtenir le premier objet dataframe du fichier RData
                   objs <- ls(envir = e)
                   df_objs <- sapply(objs, function(x) is.data.frame(e[[x]]))
                   if(any(df_objs)) {
                     e[[objs[which(df_objs)[1]]]]
                   } else {
                     NULL
                   }
                 },
                 rdata = {
                   e <- new.env()
                   load(file_info$path, envir = e)
                   # Obtenir le premier objet dataframe du fichier RData
                   objs <- ls(envir = e)
                   df_objs <- sapply(objs, function(x) is.data.frame(e[[x]]))
                   if(any(df_objs)) {
                     e[[objs[which(df_objs)[1]]]]
                   } else {
                     NULL
                   }
                 },
                 # Formats Big Data
                 parquet = arrow::read_parquet(file_info$path),
                 feather = arrow::read_feather(file_info$path),
                 fst = fst::read_fst(file_info$path),
                 # Autres formats
                 json = jsonlite::fromJSON(file_info$path, simplifyDataFrame = TRUE),
                 xml = {
                   xmldata <- xml2::read_xml(file_info$path)
                   # Tentative simple de conversion en dataframe
                   tryCatch({
                     xml2::as_list(xmldata) %>% 
                       lapply(function(x) as.data.frame(t(unlist(x)))) %>%
                       data.table::rbindlist(fill = TRUE)
                   }, error = function(e) {
                     log_batch(paste("Conversion XML en dataframe simplifiée:", e$message))
                     NULL
                   })
                 },
                 sqlite = {
                   con <- DBI::dbConnect(RSQLite::SQLite(), dbname = file_info$path)
                   tables <- DBI::dbListTables(con)
                   if(length(tables) > 0) {
                     data <- DBI::dbReadTable(con, tables[1])
                     DBI::dbDisconnect(con)
                     data
                   } else {
                     DBI::dbDisconnect(con)
                     NULL
                   }
                 },
                 db = {
                   con <- DBI::dbConnect(RSQLite::SQLite(), dbname = file_info$path)
                   tables <- DBI::dbListTables(con)
                   if(length(tables) > 0) {
                     data <- DBI::dbReadTable(con, tables[1])
                     DBI::dbDisconnect(con)
                     data
                   } else {
                     DBI::dbDisconnect(con)
                     NULL
                   }
                 },
                 # Valeur par défaut - utiliser rio qui est très polyvalent
                 rio::import(file_info$path, setclass = "data.frame")
    )
    
    # Vérifier si l'import a réussi
    if (is.null(data)) {
      log_batch(paste("Échec d'importation pour", file_info$name))
      return(NULL)
    }
    
    # Assurer que le résultat est bien un data.frame
    if (!is.data.frame(data)) {
      data <- as.data.frame(data)
    }
    
    # Récupérer toutes les opérations sélectionnées
    all_operations <- get_all_operations()
    
    # Appliquer les opérations sélectionnées
    for (op in all_operations) {
      tryCatch({
        data <- switch(op,
                      # Opérations basiques
                      clean_names = janitor::clean_names(data),
                      remove_empty = janitor::remove_empty(data, c("rows", "cols")),
                      remove_constant = janitor::remove_constant(data),
                      convert_na = {
                        if (!is.null(input$batch_na_strings) && nchar(input$batch_na_strings) > 0) {
                          na_strings <- strsplit(input$batch_na_strings, ",\\s*")[[1]] %>% trimws()
                          data %>% dplyr::mutate(across(everything(), ~replace(., . %in% na_strings, NA)))
                        } else {
                          data
                        }
                      },
                      remove_na_cols = {
                        threshold <- input$batch_na_threshold / 100
                        col_missing_pct <- colMeans(is.na(data))
                        data[, col_missing_pct < threshold]
                      },
                      recode_categorical = {
                        # Détection automatique des colonnes catégorielles
                        cat_cols <- sapply(data, function(x) is.character(x) || is.factor(x))
                        if(any(cat_cols)) {
                          data_recoded <- data
                          for(col in names(data)[cat_cols]) {
                            if(length(unique(data[[col]])) <= 20) { # Pour les catégorielles avec peu de niveaux
                              data_recoded[[col]] <- factor(data[[col]])
                            }
                          }
                          data_recoded
                        } else {
                          data
                        }
                      },
                      
                      # Opérations de filtrage
                      remove_duplicates = dplyr::distinct(data),
                      filter_condition = {
                        if(!is.null(input$batch_filter_condition) && nchar(input$batch_filter_condition) > 0) {
                          condition <- paste0("data %>% dplyr::filter(", input$batch_filter_condition, ")")
                          tryCatch({
                            eval(parse(text = condition))
                          }, error = function(e) {
                            log_batch(paste("Erreur dans la condition de filtrage:", e$message))
                            data
                          })
                        } else {
                          data
                        }
                      },
                      select_columns = {
                        if(!is.null(input$batch_column_selection) && nchar(input$batch_column_selection) > 0) {
                          cols <- strsplit(input$batch_column_selection, ",\\s*")[[1]] %>% trimws()
                          cols <- cols[cols %in% names(data)]
                          if(length(cols) > 0) {
                            data[, cols, drop = FALSE]
                          } else {
                            data
                          }
                        } else {
                          data
                        }
                      },
                      exclude_columns = {
                        if(!is.null(input$batch_column_selection) && nchar(input$batch_column_selection) > 0) {
                          cols <- strsplit(input$batch_column_selection, ",\\s*")[[1]] %>% trimws()
                          cols <- cols[cols %in% names(data)]
                          if(length(cols) > 0) {
                            data[, !(names(data) %in% cols), drop = FALSE]
                          } else {
                            data
                          }
                        } else {
                          data
                        }
                      },
                      
                      # Opérations de transformation
                      to_lowercase = {
                        char_cols <- sapply(data, is.character)
                        if(any(char_cols)) {
                          for(col in names(data)[char_cols]) {
                            data[[col]] <- tolower(data[[col]])
                          }
                        }
                        data
                      },
                      to_uppercase = {
                        char_cols <- sapply(data, is.character)
                        if(any(char_cols)) {
                          for(col in names(data)[char_cols]) {
                            data[[col]] <- toupper(data[[col]])
                          }
                        }
                        data
                      },
                      round_numeric = {
                        num_cols <- sapply(data, is.numeric)
                        if(any(num_cols)) {
                          digits <- input$batch_round_digits
                          for(col in names(data)[num_cols]) {
                            data[[col]] <- round(data[[col]], digits)
                          }
                        }
                        data
                      },
                      standardize = {
                        num_cols <- sapply(data, is.numeric)
                        if(any(num_cols)) {
                          for(col in names(data)[num_cols]) {
                            data[[col]] <- scale(data[[col]])
                          }
                        }
                        data
                      },
                      to_factor = {
                        char_cols <- sapply(data, function(x) is.character(x) && length(unique(x)) <= 50)
                        if(any(char_cols)) {
                          for(col in names(data)[char_cols]) {
                            data[[col]] <- factor(data[[col]])
                          }
                        }
                        data
                      },
                      convert_dates = {
                        # Tentative de détection automatique des colonnes de dates
                        for(col in names(data)) {
                          if(is.character(data[[col]])) {
                            # Tester différents formats de date
                            possible_date <- tryCatch({
                              as.Date(data[[col]], format = "%Y-%m-%d")
                            }, error = function(e) NA)
                            
                            if(!all(is.na(possible_date))) {
                              data[[col]] <- possible_date
                            } else {
                              # Essayer d'autres formats
                              formats <- c("%d/%m/%Y", "%m/%d/%Y", "%Y/%m/%d", "%d-%m-%Y", "%m-%d-%Y")
                              for(fmt in formats) {
                                possible_date <- tryCatch({
                                  as.Date(data[[col]], format = fmt)
                                }, error = function(e) NA)
                                
                                if(!all(is.na(possible_date))) {
                                  data[[col]] <- possible_date
                                  break
                                }
                              }
                            }
                          }
                        }
                        data
                      },
                      
                      # Opérations avancées
                      impute_missing = {
                        # Imputation des valeurs manquantes par colonne
                        method <- input$batch_impute_method
                        
                        for(col in names(data)) {
                          if(any(is.na(data[[col]]))) {
                            if(is.numeric(data[[col]])) {
                              if(method == "mean") {
                                data[[col]][is.na(data[[col]])] <- mean(data[[col]], na.rm = TRUE)
                              } else if(method == "median") {
                                data[[col]][is.na(data[[col]])] <- median(data[[col]], na.rm = TRUE)
                              } else if(method == "mode") {
                                # Mode pour valeurs numériques (approximation en utilisant des bins)
                                hist_result <- hist(data[[col]], breaks = 30, plot = FALSE)
                                mode_val <- hist_result$mids[which.max(hist_result$counts)]
                                data[[col]][is.na(data[[col]])] <- mode_val
                              } else if(method == "value") {
                                impute_val <- as.numeric(input$batch_impute_value)
                                if(!is.na(impute_val)) {
                                  data[[col]][is.na(data[[col]])] <- impute_val
                                }
                              }
                            } else if(is.character(data[[col]]) || is.factor(data[[col]])) {
                              if(method == "mode") {
                                # Mode pour valeurs catégorielles
                                tab <- table(data[[col]])
                                if(length(tab) > 0) {
                                  mode_val <- names(tab)[which.max(tab)]
                                  data[[col]][is.na(data[[col]])] <- mode_val
                                }
                              } else if(method == "value") {
                                data[[col]][is.na(data[[col]])] <- input$batch_impute_value
                              }
                            }
                          }
                        }
                        data
                      },
                      handle_outliers = {
                        # Détection et traitement des valeurs aberrantes (méthode IQR)
                        num_cols <- sapply(data, is.numeric)
                        for(col in names(data)[num_cols]) {
                          q1 <- quantile(data[[col]], 0.25, na.rm = TRUE)
                          q3 <- quantile(data[[col]], 0.75, na.rm = TRUE)
                          iqr <- q3 - q1
                          lower_bound <- q1 - 1.5 * iqr
                          upper_bound <- q3 + 1.5 * iqr
                          
                          # Remplacer les outliers par NA ou par les bornes
                          outliers <- data[[col]] < lower_bound | data[[col]] > upper_bound
                          data[[col]][outliers] <- NA
                        }
                        data
                      },
                      group_values = {
                        # Regrouper les valeurs peu fréquentes dans les variables catégorielles
                        cat_cols <- sapply(data, function(x) is.character(x) || is.factor(x))
                        threshold <- 0.05  # Valeurs représentant moins de 5% des données
                        
                        for(col in names(data)[cat_cols]) {
                          if(length(unique(data[[col]])) > 5) {  # Au moins 5 catégories
                            tab <- table(data[[col]])
                            prop_tab <- prop.table(tab)
                            rare_values <- names(tab)[prop_tab < threshold]
                            
                            if(length(rare_values) > 0) {
                              data[[col]] <- as.character(data[[col]])
                              data[[col]][data[[col]] %in% rare_values] <- "Autres"
                              data[[col]] <- factor(data[[col]])
                            }
                          }
                        }
                        data
                      },
                      calculate_stats = {
                        # Calculer des statistiques simples sur les colonnes numériques
                        num_cols <- sapply(data, is.numeric)
                        if(any(num_cols)) {
                          # Ajouter des colonnes avec statistiques
                          numeric_data <- data[, num_cols, drop = FALSE]
                          if(ncol(numeric_data) >= 2) {  # Au moins 2 colonnes numériques pour calculer des stats
                            data$row_mean <- rowMeans(numeric_data, na.rm = TRUE)
                            data$row_sum <- rowSums(numeric_data, na.rm = TRUE)
                            data$row_sd <- apply(numeric_data, 1, sd, na.rm = TRUE)
                          }
                        }
                        data
                      },
                      create_variables = {
                        # Générer des variables calculées (interaction entre variables numériques)
                        num_cols <- names(data)[sapply(data, is.numeric)]
                        if(length(num_cols) >= 2) {
                          # Prendre les 2 premières colonnes numériques et calculer des interactions
                          col1 <- num_cols[1]
                          col2 <- num_cols[2]
                          if(!is.null(data[[col1]]) && !is.null(data[[col2]])) {
                            data[[paste0(col1, "_x_", col2)]] <- data[[col1]] * data[[col2]]
                            data[[paste0(col1, "_div_", col2)]] <- data[[col1]] / ifelse(data[[col2]] == 0, 1, data[[col2]])
                            data[[paste0(col1, "_plus_", col2)]] <- data[[col1]] + data[[col2]]
                            data[[paste0(col1, "_minus_", col2)]] <- data[[col1]] - data[[col2]]
                          }
                        }
                        data
                      },
                      
                      # Valeur par défaut
                      data  # Par défaut, retourner les données non modifiées
        )
        log_batch(paste("Opération", op, "appliquée sur", file_info$name))
      }, error = function(e) {
        log_batch(paste("Erreur lors de l'application de", op, "sur", file_info$name, ":", e$message))
      })
    }
    
    return(data)
  }, error = function(e) {
    log_batch(paste("Erreur lors de l'importation de", file_info$name, ":", e$message))
    return(NULL)
  })
}

# Traitement par lots
observeEvent(input$process_batch, {
  req(batch_rv$files)
  
  # Vérifier qu'au moins une opération est sélectionnée
  all_operations <- get_all_operations()
  if(length(all_operations) == 0) {
    showNotification("Veuillez sélectionner au moins une opération à appliquer.", type = "warning")
    return()
  }
  
  # Réinitialiser les données traitées et les journaux
  batch_rv$processed_data <- list()
  batch_rv$progress <- 0
  
  # Afficher la barre de progression
  shinyjs::show("batch_progress_container")
  
  # Nombre total de fichiers
  total_files <- length(batch_rv$files)
  
  # S'assurer que le nombre de fichiers est correct
  if (total_files == 0) {
    log_batch("Aucun fichier à traiter. Veuillez importer des fichiers.")
    shinyjs::hide("batch_progress_container")
    return()
  }
  
  # Traiter chaque fichier
  withProgress(message = 'Traitement par lots', value = 0, {
    for (i in 1:total_files) {
      # Mise à jour de la progression
      incProgress(1/total_files, detail = paste("Fichier", i, "sur", total_files))
      batch_rv$progress <- (i / total_files) * 100
      
      # Mise à jour de la barre de progression
      shinyjs::runjs(paste0("document.querySelector('#batch_progress_bar .progress-bar').style.width = '", 
                            batch_rv$progress, "%';"))
      
      # Traiter le fichier
      file_info <- batch_rv$files[[i]]
      log_batch(paste("Traitement de", file_info$name))
      
      # Processus de traitement
      result <- process_file(file_info)
      
      # Sauvegarder le résultat
      if (!is.null(result)) {
        batch_rv$processed_data[[file_info$name]] <- result
        log_batch(paste("Traitement de", file_info$name, "terminé avec succès"))
      } else {
        log_batch(paste("Échec du traitement pour", file_info$name))
      }
    }
  })
  
  # Définir le premier fichier traité comme aperçu par défaut
  if (length(batch_rv$processed_data) > 0) {
    batch_rv$current_preview <- names(batch_rv$processed_data)[1]
  }
  
  # Journaliser la fin du traitement
  log_batch(paste("Traitement par lots terminé :", length(batch_rv$processed_data), 
                 "fichiers traités sur", total_files))
})

# JavaScript pour assurer le bon fonctionnement de la sélection multiple
observeEvent(session$clientData$url_search, {
  # Envoyer le JavaScript une fois que l'application est chargée
  shinyjs::runjs('
    // Assurer que la sélection multiple fonctionne correctement
    $(document).ready(function() {
      // Fonction pour vérifier et corriger l\'attribut multiple
      function checkMultipleAttribute() {
        var batchInput = document.getElementById("batch_files");
        if (batchInput) {
          if (!batchInput.hasAttribute("multiple") || batchInput.getAttribute("multiple") !== "multiple") {
            console.log("Fixing multiple attribute");
            batchInput.setAttribute("multiple", "multiple");
          }
        }
      }
      
      // Vérifier immédiatement
      checkMultipleAttribute();
      
      // Vérifier à nouveau après un court délai
      setTimeout(checkMultipleAttribute, 1000);
      
      // Vérifier lors du chargement de l\'onglet de traitement par lots
      $(document).on("shiny:inputchanged", function(event) {
        if (event.name === "main_navbar" && event.value === "Traitement par lots") {
          setTimeout(checkMultipleAttribute, 500);
        }
      });
    });
  ')
}, once = TRUE)

# Aperçu des fichiers traités
output$batch_preview <- renderDT({
  req(batch_rv$processed_data, batch_rv$current_preview)
  
  data <- batch_rv$processed_data[[batch_rv$current_preview]]
  
  if (!is.null(data)) {
    datatable(data,
              options = list(
                scrollX = TRUE,
                pageLength = 5,
                dom = 'Bfrtip',
                buttons = c('copy', 'csv', 'excel')
              ),
              extensions = 'Buttons',
              rownames = FALSE,
              caption = HTML(paste("<strong>Aperçu de:</strong>", batch_rv$current_preview))
    )
  }
})

# Test d'une recette sur un échantillon de données
observeEvent(input$test_recipe, {
  req(batch_rv$files)
  
  # Vérifier qu'au moins une opération est sélectionnée
  all_operations <- get_all_operations()
  if(length(all_operations) == 0) {
    showNotification("Veuillez sélectionner au moins une opération à appliquer.", type = "warning")
    return()
  }
  
  # Prendre le premier fichier comme exemple
  if(length(batch_rv$files) > 0) {
    file_info <- batch_rv$files[[1]]
    
    # Afficher une notification de début de test
    showNotification(paste("Test de la recette sur", file_info$name), type = "message")
    log_batch(paste("Test de la recette sur", file_info$name))
    
    # Traiter le fichier
    result <- process_file(file_info)
    
    # Afficher l'aperçu du résultat
    if(!is.null(result)) {
      batch_rv$processed_data[[file_info$name]] <- result
      batch_rv$current_preview <- file_info$name
      
      # Calculer et afficher des statistiques sur l'effet de la recette
      stats <- list(
        "Nombre de lignes" = nrow(result),
        "Nombre de colonnes" = ncol(result),
        "Nombre de valeurs manquantes" = sum(is.na(result)),
        "Proportion de valeurs manquantes" = round(sum(is.na(result)) / (nrow(result) * ncol(result)) * 100, 2)
      )
      
      # Afficher les statistiques dans une boîte de dialogue
      showModal(modalDialog(
        title = "Résultat du test de recette",
        h4("Fichier test:", file_info$name),
        tags$table(class = "table table-bordered",
                  tags$thead(
                    tags$tr(
                      tags$th("Métrique"),
                      tags$th("Valeur")
                    )
                  ),
                  tags$tbody(
                    lapply(names(stats), function(name) {
                      tags$tr(
                        tags$td(name),
                        tags$td(stats[[name]])
                      )
                    })
                  )
        ),
        size = "l",
        easyClose = TRUE,
        footer = tagList(
          modalButton("Fermer"),
          actionButton("apply_to_all", "Appliquer à tous", class = "btn-success")
        )
      ))
      
      log_batch(paste("Test réussi sur", file_info$name, "- Lignes:", nrow(result), "Colonnes:", ncol(result)))
    } else {
      showNotification(paste("Échec du test pour", file_info$name), type = "error")
      log_batch(paste("Test échoué pour", file_info$name))
    }
  } else {
    showNotification("Veuillez importer au moins un fichier pour tester la recette.", type = "warning")
  }
})

# Appliquer la recette testée à tous les fichiers
observeEvent(input$apply_to_all, {
  removeModal()
  # Déclencher le traitement par lots
  click("process_batch")
})

# Enregistrer une recette
observeEvent(input$save_recipe, {
  # Vérifier qu'au moins une opération est sélectionnée
  all_operations <- get_all_operations()
  if(length(all_operations) == 0) {
    showNotification("Veuillez sélectionner au moins une opération à enregistrer.", type = "warning")
    return()
  }
  
  # Demander un nom pour la recette
  showModal(modalDialog(
    title = "Enregistrer la recette",
    textInput("recipe_name", "Nom de la recette", value = paste0("Recette_", length(batch_rv$recipes) + 1)),
    textAreaInput("recipe_description", "Description (optionnelle):", ""),
    footer = tagList(
      modalButton("Annuler"),
      actionButton("confirm_save_recipe", "Enregistrer", class = "btn-primary")
    )
  ))
})

# Confirmer l'enregistrement de la recette
observeEvent(input$confirm_save_recipe, {
  req(input$recipe_name)
  
  # Collecter toutes les opérations et paramètres
  all_operations <- get_all_operations()
  
  # Créer la recette
  recipe <- list(
    name = input$recipe_name,
    description = input$recipe_description,
    operations = list(
      basic = if (!is.null(input$batch_operations_basic)) input$batch_operations_basic else c(),
      filter = if (!is.null(input$batch_operations_filter)) input$batch_operations_filter else c(),
      transform = if (!is.null(input$batch_operations_transform)) input$batch_operations_transform else c(),
      advanced = if (!is.null(input$batch_operations_advanced)) input$batch_operations_advanced else c()
    ),
    parameters = list(
      na_strings = if("convert_na" %in% all_operations) input$batch_na_strings else NULL,
      na_threshold = if("remove_na_cols" %in% all_operations) input$batch_na_threshold else NULL,
      filter_condition = if("filter_condition" %in% all_operations) input$batch_filter_condition else NULL,
      column_selection = if("select_columns" %in% all_operations || "exclude_columns" %in% all_operations) input$batch_column_selection else NULL,
      round_digits = if("round_numeric" %in% all_operations) input$batch_round_digits else NULL,
      impute_method = if("impute_missing" %in% all_operations) input$batch_impute_method else NULL,
      impute_value = if("impute_missing" %in% all_operations && input$batch_impute_method == "value") input$batch_impute_value else NULL
    ),
    created = Sys.time()
  )
  
  # Ajouter la recette à la liste
  batch_rv$recipes[[input$recipe_name]] <- recipe
  
  # Journaliser
  log_batch(paste("Recette", input$recipe_name, "enregistrée avec", length(all_operations), "opérations"))
  
  # Fermer la boîte de dialogue
  removeModal()
  
  # Notification de confirmation
  showNotification(paste("Recette", input$recipe_name, "enregistrée avec succès"), type = "message")
})

# Afficher les recettes enregistrées
output$saved_recipes <- renderUI({
  req(batch_rv$recipes)
  
  if (length(batch_rv$recipes) == 0) {
    return(p("Aucune recette enregistrée"))
  }
  
  # Créer une liste de sélection de recettes avec des informations supplémentaires
  selectInput("selected_recipe", "Sélectionner une recette",
             choices = sapply(batch_rv$recipes, function(r) {
               ops_count <- sum(sapply(r$operations, length))
               paste0(r$name, " (", ops_count, " opérations)")
             }),
             selected = names(batch_rv$recipes)[1])
})

# Charger une recette
observeEvent(input$load_recipe, {
  req(input$selected_recipe, batch_rv$recipes)
  
  # Extraire le nom de la recette sans les informations entre parenthèses
  recipe_name <- strsplit(input$selected_recipe, " \\(")[[1]][1]
  recipe <- batch_rv$recipes[[recipe_name]]
  
  if (!is.null(recipe)) {
    # Mettre à jour les entrées de l'interface
    updateCheckboxGroupInput(session, "batch_operations_basic", selected = recipe$operations$basic)
    updateCheckboxGroupInput(session, "batch_operations_filter", selected = recipe$operations$filter)
    updateCheckboxGroupInput(session, "batch_operations_transform", selected = recipe$operations$transform)
    updateCheckboxGroupInput(session, "batch_operations_advanced", selected = recipe$operations$advanced)
    
    # Mettre à jour les paramètres
    if (!is.null(recipe$parameters$na_strings)) {
      updateTextInput(session, "batch_na_strings", value = recipe$parameters$na_strings)
    }
    
    if (!is.null(recipe$parameters$na_threshold)) {
      updateSliderInput(session, "batch_na_threshold", value = recipe$parameters$na_threshold)
    }
    
    if (!is.null(recipe$parameters$filter_condition)) {
      updateTextInput(session, "batch_filter_condition", value = recipe$parameters$filter_condition)
    }
    
    if (!is.null(recipe$parameters$column_selection)) {
      updateTextInput(session, "batch_column_selection", value = recipe$parameters$column_selection)
    }
    
    if (!is.null(recipe$parameters$round_digits)) {
      updateNumericInput(session, "batch_round_digits", value = recipe$parameters$round_digits)
    }
    
    if (!is.null(recipe$parameters$impute_method)) {
      updateSelectInput(session, "batch_impute_method", selected = recipe$parameters$impute_method)
    }
    
    if (!is.null(recipe$parameters$impute_value)) {
      updateTextInput(session, "batch_impute_value", value = recipe$parameters$impute_value)
    }
    
    # Journaliser
    log_batch(paste("Recette", recipe$name, "chargée"))
    
    # Afficher une notification
    showNotification(paste("Recette", recipe$name, "chargée avec succès"), type = "message")
    
    # Afficher les détails de la recette
    showModal(modalDialog(
      title = paste("Détails de la recette:", recipe$name),
      
      if (!is.null(recipe$description) && recipe$description != "") {
        div(
          h4("Description:"),
          p(recipe$description)
        )
      },
      
      h4("Opérations:"),
      tags$ul(
        lapply(c("basic", "filter", "transform", "advanced"), function(category) {
          ops <- recipe$operations[[category]]
          if (length(ops) > 0) {
            tags$li(
              strong(switch(category,
                          "basic" = "Basiques",
                          "filter" = "Filtrage",
                          "transform" = "Transformation",
                          "advanced" = "Avancées")),
              tags$ul(
                lapply(ops, function(op) {
                  tags$li(op)
                })
              )
            )
          }
        })
      ),
      
      p(paste("Créée le:", format(recipe$created, "%d/%m/%Y à %H:%M"))),
      
      size = "m",
      easyClose = TRUE,
      footer = modalButton("Fermer")
    ))
  }
})

# Supprimer une recette
observeEvent(input$delete_recipe, {
  req(input$selected_recipe)
  
  # Extraire le nom de la recette sans les informations entre parenthèses
  recipe_name <- strsplit(input$selected_recipe, " \\(")[[1]][1]
  
  if (recipe_name %in% names(batch_rv$recipes)) {
    # Demander confirmation
    showModal(modalDialog(
      title = "Confirmer la suppression",
      p(paste("Êtes-vous sûr de vouloir supprimer la recette", recipe_name, "?")),
      footer = tagList(
        modalButton("Annuler"),
        actionButton("confirm_delete_recipe", "Supprimer", class = "btn-danger")
      )
    ))
  } else {
    showNotification("Veuillez sélectionner une recette à supprimer.", type = "warning")
  }
})

# Confirmer la suppression d'une recette
observeEvent(input$confirm_delete_recipe, {
  req(input$selected_recipe)
  
  # Extraire le nom de la recette sans les informations entre parenthèses
  recipe_name <- strsplit(input$selected_recipe, " \\(")[[1]][1]
  
  if (recipe_name %in% names(batch_rv$recipes)) {
    # Supprimer la recette
    batch_rv$recipes[[recipe_name]] <- NULL
    
    # Journaliser
    log_batch(paste("Recette", recipe_name, "supprimée"))
    
    # Fermer la boîte de dialogue
    removeModal()
    
    # Notification de confirmation
    showNotification(paste("Recette", recipe_name, "supprimée"), type = "message")
  }
})

# Télécharger les résultats (fichier zip)
output$download_batch <- downloadHandler(
  filename = function() {
    paste0("batch_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
  },
  content = function(file) {
    req(batch_rv$processed_data)
    
    # Créer un dossier temporaire
    temp_dir <- tempdir()
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    batch_dir <- file.path(temp_dir, paste0("batch_", timestamp))
    dir.create(batch_dir, showWarnings = FALSE)
    
    # Enregistrer chaque fichier traité
    for (name in names(batch_rv$processed_data)) {
      data <- batch_rv$processed_data[[name]]
      
      # Créer un nom de fichier propre
      clean_name <- janitor::make_clean_names(tools::file_path_sans_ext(name))
      output_file <- file.path(batch_dir, paste0(clean_name, "_clean.csv"))
      
      # Écrire le fichier CSV
      write.csv(data, output_file, row.names = FALSE)
    }
    
    # Créer un fichier journal
    log_file <- file.path(batch_dir, "batch_log.txt")
    writeLines(batch_rv$logs, log_file)
    
    # Créer l'archive zip
    zip::zip(file, files = dir(batch_dir, full.names = TRUE), rootdir = temp_dir)
    
    # Journaliser
    log_batch(paste("Résultats téléchargés:", length(batch_rv$processed_data), "fichiers"))
  }
)

# Ajouter un observateur pour afficher des info-bulles sur les formats de fichiers
observeEvent(session$clientData$url_search, {
  output$format_tooltips <- renderUI({
    tags$script(HTML('
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
    '))
  })
  
  # Vérifier si les packages nécessaires sont disponibles
  output$packages_status <- renderUI({
    missing_packages <- c()
    all_ok <- TRUE
    
    # Vérifier les packages essentiels
    required_packages <- c("rio", "readr", "readxl", "data.table", "haven", 
                         "jsonlite", "xml2", "DBI", "RSQLite", "arrow", "fst")
    
    for (pkg in required_packages) {
      if (!requireNamespace(pkg, quietly = TRUE)) {
        missing_packages <- c(missing_packages, pkg)
        all_ok <- FALSE
      }
    }
    
    if (all_ok) {
      return(NULL)  # Tout est OK, ne rien afficher
    } else {
      tags$div(class = "alert alert-warning",
              tags$p(icon("exclamation-triangle"), 
                     "Certains packages sont manquants pour tous les formats de fichiers:"),
              tags$ul(
                lapply(missing_packages, function(pkg) {
                  tags$li(pkg)
                })
              ),
              tags$p("Exécutez ", tags$code("install.packages(c('", 
                                          paste(missing_packages, collapse = "', '"), 
                                          "'))"))
      )
    }
  })
}, once = TRUE)

# Ajouter des statistiques sur les formats de fichiers importés
output$batch_stats <- renderText({
  req(batch_rv$files)
  
  # Compter les formats de fichiers
  formats <- sapply(batch_rv$files, function(file) file$type)
  format_counts <- table(formats)
  
  # Créer le texte de statistiques
  stats_text <- paste("Distribution des formats :", 
                     paste(names(format_counts), ":", format_counts, collapse = ", "))
  
  return(stats_text)
}) 