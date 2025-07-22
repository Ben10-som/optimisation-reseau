# ui/ui_report.R

div(class = "container-fluid",
    div(class = "row",
        column(6,
               div(class = "well-panel",
                   h4(icon("file-alt"), "Générer un rapport HTML"),
                   textInput("report_title", "Titre du rapport", "Rapport de nettoyage"),
                   
                   # Sélecteur de template
                   selectInput("report_template", "Type de rapport:",
                              choices = c("Standard" = "standard",
                                          "Détaillé" = "detailed",
                                          "Minimal" = "minimal",
                                          "Présentation" = "presentation")),
                   
                   # Logo personnalisé
                   fileInput("report_logo", "Logo personnalisé (optionnel)",
                            accept = c('image/png', 'image/jpeg', 'image/gif')),
                   
                   # Auteur du rapport
                   textInput("report_author", "Auteur", ""),
                   
                   # Notes additionnelles
                   textAreaInput("report_notes", "Notes additionnelles", "", rows = 4),
                   
                   # Alerte pour la traçabilité du code
                   div(class = "alert alert-info",
                       icon("code"), strong("Traçabilité du code : "),
                       "Activez l'option 'Code R généré' ci-dessous pour inclure le code R associé à chaque opération dans votre rapport."
                   ),
                   
                   # Options avancées
                   checkboxGroupInput("report_elements", "Éléments à inclure:",
                                     choices = c("Résumé des opérations" = "operations",
                                                "Statistiques descriptives" = "stats",
                                                "Visualisations" = "plots",
                                                "Code R généré" = "code"),
                                     selected = c("operations", "stats", "code")),
                   
                   downloadButton("download_report", "Télécharger le rapport", 
                                 class = "btn btn-primary btn-block")
               )
        ),
        column(6,
               div(class = "well-panel",
                   h4(icon("eye"), "Aperçu du rapport"),
                   
                   # Aperçu du template sélectionné
                   uiOutput("report_preview"),
                   
                   hr(),
                   
                   # Options d'export supplémentaires
                   h4(icon("cog"), "Options d'export avancées"),
                   radioButtons("report_format", "Format de sortie:",
                               choices = c("HTML" = "html",
                                          "PDF" = "pdf",
                                          "Word" = "docx"),
                               selected = "html", inline = TRUE),
                   
                   # Options conditionnelles pour le PDF
                   conditionalPanel(
                     condition = "input.report_format == 'pdf'",
                     selectInput("report_paper", "Format de page:",
                                choices = c("A4" = "a4",
                                           "Letter" = "letter",
                                           "Legal" = "legal"))
                   )
               )
        )
    )
)
