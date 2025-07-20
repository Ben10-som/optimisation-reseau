div(class = "container-fluid",
    div(class = "row",
        column(6,
               div(class = "well-panel",
                   h4(icon("file-export"), "Exporter les données"),
                   selectInput("export_format", "Format d'exportation:",
                               choices = list(
                                 "Feuilles" = c(
                                   "Excel (xlsx)" = "xlsx",
                                   "CSV" = "csv",
                                   "Feather" = "feather",
                                   "FST" = "fst"
                                 ),
                                 "Stata ou spss " = c(
                                   "SPSS (sav)" = "sav",
                                   "Stata (dta)" = "dta"
                                 ),
                                 "Big Data" = c(
                                   "Parquet" = "parquet",
                                   "Arrow" = "arrow"
                                 ),
                                 "Programmation" = c(
                                   "R (rds)" = "rds",
                                   "JSON" = "json"
                                 ),
                                 "Archives compressées" = c(
                                   "ZIP" = "zip",
                                   "GZ" = "gz"
                                 )
                               ),
                               selected = "xlsx"),
                   
                   textInput("export_filename", 
                             label = tags$span("Nom du fichier:", 
                                               tags$small(" (sans extension)")),
                             value = "donnees_nettoyees"),
                   
                   tags$div(class = "form-group",
                            tags$label("Options avancées:"),
                            conditionalPanel(
                              condition = "input.export_format == 'csv'",
                              checkboxInput("csv_header", "En-têtes de colonnes", TRUE),
                              radioButtons("csv_sep", "Séparateur:",
                                           c("Virgule" = ",",
                                             "Point-virgule" = ";",
                                             "Tabulation" = "\t"))
                            ),
                            conditionalPanel(
                              condition = "input.export_format == 'xlsx'",
                              checkboxInput("xlsx_sheetnames", "Ajouter le nom des feuilles", TRUE)
                            ),
                            conditionalPanel(
                              condition = "['fst', 'rds', 'parquet', 'zip', 'gz'].includes(input.export_format)",
                              h5("Options de compression"),
                              sliderInput("compression_level", "Niveau de compression:",
                                         min = 0, max = 100, value = 50, step = 10),
                              span(id = "compression_info", class = "text-muted",
                                  "Plus la compression est élevée, plus le fichier sera petit, mais l'export sera plus lent.")
                            )
                   ),
                   
                   uiOutput("export_size_info"),
                   
                   downloadButton("download_data", 
                                  label = tags$span(icon("download"), " Télécharger"), 
                                  class = "btn btn-success btn-block btn-lg",
                                  style = "margin-top: 15px;")
               )
        ),
        column(6,
               div(class = "well-panel",
                   h4(icon("table"), "Aperçu des données"),
                   withSpinner(DTOutput("clean_table"), 
                               type = 6, color = "#3498db"),
                   hr(),
                   h4(icon("code-compare"), "Comparaison avant/après"),
                   withSpinner(DTOutput("comparison_table"), 
                               type = 6, color = "#3498db"),
                   tags$div(class = "alert alert-info",
                            icon("info-circle"),
                            "Les données exportées contiendront",
                            tags$b(" toutes les transformations appliquées.")
                   )
               )
        )
    )
)