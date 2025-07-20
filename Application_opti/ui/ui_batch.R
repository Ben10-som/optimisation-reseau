# ui/ui_batch.R

div(class = "container-fluid",
    # Éléments UI pour le JavaScript et les tooltips
    uiOutput("format_tooltips"),
    uiOutput("packages_status"),
    
    div(class = "row",
        column(4,
               div(class = "well-panel",
                   h4(icon("folder-open"), "Import par lots"),
                   div(class = "file-input-container",
                       fileInput("batch_files", "Sélectionnez plusieurs fichiers",
                                 multiple = TRUE, 
                                 accept = c(
                                   # Formats texte
                                   ".csv", ".tsv", ".txt", ".tab", 
                                   # Formats Excel
                                   ".xlsx", ".xls", ".xlsm",
                                   # Formats statistiques
                                   ".sas7bdat", ".sav", ".dta", 
                                   # Formats R
                                   ".rds", ".rda", ".rdata", 
                                   # Formats Big Data
                                   ".parquet", ".feather", ".fst",
                                   # Autres formats
                                   ".json", ".xml", ".html", ".ods", ".sqlite", ".db"
                                 )),
                       tags$div(class = "format-list",
                               tags$p(class = "text-muted", "Formats supportés:"),
                               tags$div(
                                 tags$span(class = "badge bg-primary me-1", "CSV"),
                                 tags$span(class = "badge bg-primary me-1", "TSV"),
                                 tags$span(class = "badge bg-primary me-1", "TXT"),
                                 tags$span(class = "badge bg-success me-1", "Excel"),
                                 tags$span(class = "badge bg-success me-1", "ODS"),
                                 tags$span(class = "badge bg-info me-1", "SAS"),
                                 tags$span(class = "badge bg-info me-1", "SPSS"),
                                 tags$span(class = "badge bg-info me-1", "Stata"),
                                 tags$span(class = "badge bg-warning me-1", "RDS"),
                                 tags$span(class = "badge bg-warning me-1", "RData"),
                                 tags$span(class = "badge bg-secondary me-1", "JSON"),
                                 tags$span(class = "badge bg-secondary me-1", "XML"),
                                 tags$span(class = "badge bg-dark me-1", "Parquet"),
                                 tags$span(class = "badge bg-dark me-1", "Feather"),
                                 tags$span(class = "badge bg-dark me-1", "FST"),
                                 tags$span(class = "badge bg-danger me-1", "SQLite")
                               )
                        )
                   ),
                   materialSwitch("batch_header", "Première ligne comme en-tête", TRUE, status = "primary"),
                   conditionalPanel(
                     condition = "input.batch_files",
                     selectInput("batch_sep", "Séparateur:", c("Virgule" = ",", "Point-virgule" = ";", "Tabulation" = "\t", "Espace" = " ", "Pipe" = "|")),
                     selectInput("batch_dec", "Séparateur décimal:", c("Point" = ".", "Virgule" = ","))
                   )
               ),
               div(class = "well-panel",
                   h4(icon("sliders"), "Recette de nettoyage"),
                   
                   # Onglets pour organiser les opérations par catégorie
                   tabsetPanel(
                     tabPanel("Basique",
                              checkboxGroupInput("batch_operations_basic", "Opérations basiques:",
                                                choices = c(
                                                  "Nettoyer les noms de colonnes" = "clean_names",
                                                  "Supprimer colonnes/lignes vides" = "remove_empty",
                                                  "Supprimer colonnes constantes" = "remove_constant",
                                                  "Convertir valeurs en NA" = "convert_na",
                                                  "Supprimer colonnes avec trop de NA" = "remove_na_cols",
                                                  "Recoder variables catégorielles" = "recode_categorical"
                                                )
                              )
                     ),
                     tabPanel("Filtrage",
                              checkboxGroupInput("batch_operations_filter", "Filtrage des données:",
                                                choices = c(
                                                  "Supprimer doublons" = "remove_duplicates",
                                                  "Filtrer lignes selon conditions" = "filter_condition",
                                                  "Garder seulement certaines colonnes" = "select_columns",
                                                  "Exclure certaines colonnes" = "exclude_columns"
                                                )
                              )
                     ),
                     tabPanel("Transformation", 
                              checkboxGroupInput("batch_operations_transform", "Transformations:",
                                                choices = c(
                                                  "Convertir texte en minuscules" = "to_lowercase",
                                                  "Convertir texte en majuscules" = "to_uppercase",
                                                  "Arrondir valeurs numériques" = "round_numeric",
                                                  "Standardiser variables numériques" = "standardize",
                                                  "Transformer en facteurs" = "to_factor",
                                                  "Convertir dates" = "convert_dates"
                                                )
                              )
                     ),
                     tabPanel("Avancé",
                              checkboxGroupInput("batch_operations_advanced", "Opérations avancées:",
                                                choices = c(
                                                  "Imputation des valeurs manquantes" = "impute_missing",
                                                  "Détecter et traiter les valeurs aberrantes" = "handle_outliers",
                                                  "Regrouper des valeurs" = "group_values",
                                                  "Calcul de statistiques agrégées" = "calculate_stats",
                                                  "Générer variables calculées" = "create_variables"
                                                )
                              )
                     )
                   ),
                   
                   # Paramètres conditionnels pour les opérations
                   conditionalPanel(
                     condition = "input.batch_operations_basic.includes('convert_na')",
                     textInput("batch_na_strings", "Valeurs à convertir en NA (séparées par des virgules):", 
                              value = "NA, N/A, Missing, None, #N/A, undefined, null, -")
                   ),
                   conditionalPanel(
                     condition = "input.batch_operations_basic.includes('remove_na_cols')",
                     sliderInput("batch_na_threshold", "Seuil de valeurs manquantes (%):",
                                min = 10, max = 100, value = 50, step = 5)
                   ),
                   conditionalPanel(
                     condition = "input.batch_operations_filter.includes('filter_condition')",
                     textInput("batch_filter_condition", "Condition de filtrage (ex: Colonne > 10):", "")
                   ),
                   conditionalPanel(
                     condition = "input.batch_operations_filter.includes('select_columns') || input.batch_operations_filter.includes('exclude_columns')",
                     textInput("batch_column_selection", "Colonnes (séparées par des virgules):", "")
                   ),
                   conditionalPanel(
                     condition = "input.batch_operations_transform.includes('round_numeric')",
                     numericInput("batch_round_digits", "Nombre de décimales:", 2, min = 0, max = 10)
                   ),
                   conditionalPanel(
                     condition = "input.batch_operations_advanced.includes('impute_missing')",
                     selectInput("batch_impute_method", "Méthode d'imputation:", 
                               c("Moyenne" = "mean", "Médiane" = "median", "Mode" = "mode", "Valeur spécifique" = "value"))
                   ),
                   conditionalPanel(
                     condition = "input.batch_operations_advanced.includes('impute_missing') && input.batch_impute_method == 'value'",
                     textInput("batch_impute_value", "Valeur d'imputation:", "0")
                   ),
                   
                   # Boutons pour gérer les recettes
                   hr(),
                   div(class = "row",
                       column(6, actionButton("save_recipe", "Enregistrer recette", 
                                             icon = icon("save"), 
                                             class = "btn btn-info btn-block")),
                       column(6, actionButton("test_recipe", "Tester recette", 
                                             icon = icon("vial"), 
                                             class = "btn btn-warning btn-block"))
                   )
               ),
               div(class = "well-panel",
                   h4(icon("clock-rotate-left"), "Recettes enregistrées"),
                   uiOutput("saved_recipes"),
                   actionButton("load_recipe", "Charger recette", 
                                icon = icon("upload"), 
                                class = "btn btn-secondary btn-block"),
                   actionButton("delete_recipe", "Supprimer recette", 
                                icon = icon("trash"), 
                                class = "btn btn-danger btn-block mt-2")
               )
        ),
        column(8,
               div(class = "well-panel",
                   h4(icon("cogs"), "Traitement par lots"),
                   # Afficher les statistiques des formats importés
                   conditionalPanel(
                     condition = "input.batch_files",
                     div(class = "alert alert-info", textOutput("batch_stats"))
                   ),
                   verbatimTextOutput("batch_summary"),
                   hr(),
                   div(class = "row",
                       column(6,
                              actionButton("process_batch", "Lancer le traitement", 
                                          icon = icon("play"), 
                                          class = "btn btn-success btn-block")),
                       column(6,
                              downloadButton("download_batch", "Télécharger les résultats",
                                           class = "btn btn-primary btn-block"))
                   ),
                   hr(),
                   div(id = "batch_progress_container", style = "display: none;",
                       h4("Progression du traitement"),
                       div(id = "batch_progress_bar", class = "progress",
                           div(class = "progress-bar progress-bar-striped progress-bar-animated",
                               role = "progressbar",
                               style = "width: 0%"))
                   ),
                   hr(),
                   h4(icon("list"), "Journaux d'opérations"),
                   verbatimTextOutput("batch_logs"),
                   style = "max-height: 600px; overflow-y: auto;"
               ),
               div(class = "well-panel",
                   h4(icon("table"), "Aperçu des fichiers traités"),
                   DTOutput("batch_preview")
               )
        )
    )
) 