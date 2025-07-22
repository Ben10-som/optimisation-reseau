# ui/ui_import

div(class = "container-fluid",
    div(class = "row",
        column(4,
               div(class = "well-panel",
                   h4(icon("file-import"), "Importer des données"),
                   
                   # Mise en évidence des formats supportés avec badges colorés
                   div(class = "format-badges-container mb-3",
                       h5(icon("file-code"), "Formats supportés:"),
                       div(class = "format-list p-2 border rounded bg-light",
                           div(class = "d-flex flex-wrap justify-content-center",
                               # Formats texte
                               tags$span(class = "badge bg-primary m-1", "CSV"),
                               tags$span(class = "badge bg-primary m-1", "TSV"),
                               tags$span(class = "badge bg-primary m-1", "TXT"),
                               # Formats Excel
                               tags$span(class = "badge bg-success m-1", "Excel"),
                               tags$span(class = "badge bg-success m-1", "ODS"),
                               # Formats statistiques
                               tags$span(class = "badge bg-info m-1", "SAS"),
                               tags$span(class = "badge bg-info m-1", "SPSS"),
                               tags$span(class = "badge bg-info m-1", "Stata"),
                               # Formats R
                               tags$span(class = "badge bg-warning m-1", "RDS"),
                               tags$span(class = "badge bg-warning m-1", "RData"),
                               # Autres formats
                               tags$span(class = "badge bg-secondary m-1", "JSON"),
                               tags$span(class = "badge bg-secondary m-1", "XML"),
                               # Formats Big Data
                               tags$span(class = "badge bg-dark m-1", "Parquet"),
                               tags$span(class = "badge bg-dark m-1", "Feather"),
                               tags$span(class = "badge bg-dark m-1", "FST"),
                               tags$span(class = "badge bg-danger m-1", "SQLite")
                           )
                       )
                   ),
                   
                   div(class = "file-input-container",
                       fileInput("file_input", "Sélectionner un fichier", 
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
                                )
                       )
                   ),
                   hr(),
                   h4(icon("cog"), "Options d'import"),
                   materialSwitch("header", "Première ligne comme en-tête", TRUE, status = "primary"),
                   conditionalPanel(
                     condition = "input.file_input && ['csv','tsv','txt','tab'].includes(input.file_input.name.split('.').pop().toLowerCase())",
                     selectInput("sep", "Séparateur:", c("Virgule" = ",", "Point-virgule" = ";", "Tabulation" = "\t", "Espace" = " ", "Pipe" = "|")),
                     selectInput("dec", "Séparateur décimal:", c("Point" = ".", "Virgule" = ","))
                   ),
                   actionButton("reset_data", "Réinitialiser tout", icon = icon("trash"), 
                                class = "btn btn-danger btn-action")
               ),
               div(class = "well-panel",
                   h4(icon("info-circle"), "Résumé des données"),
                   verbatimTextOutput("data_summary"),
                   hr(),
                   h4(icon("database"), "Métadonnées"),
                   verbatimTextOutput("data_types")
               )
        ),
        column(8,
               div(class = "well-panel",
                   h4(icon("table"), "Aperçu des données"),
                   withSpinner(DTOutput("raw_table"), type = 6, color = "#3498db")
               )
        )
    )
)
