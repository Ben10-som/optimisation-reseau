# ui/ui_analysis.R

fluidPage(
  titlePanel("Analyse et Visualisation"),
  
  # JavaScript pour déclencher des clics sur des boutons
  tags$head(
    tags$script(HTML("
      Shiny.addCustomMessageHandler('triggerButtonClick', function(message) {
        document.getElementById(message).click();
      });
    "))
  ),
  
  # Activer shinyjs
  shinyjs::useShinyjs(),
  
  fluidRow(
    column(3,
      wellPanel(
        h4("Paramètres"),
        
        # Sélection des variables pour les tableaux statistiques
        selectizeInput("tabyl_vars", 
                     "Variables à analyser:", 
                     choices = NULL, 
                     multiple = TRUE,
                     options = list(placeholder = "Sélectionner une ou plusieurs variables")),
        
        # Options de stratification
        selectizeInput("strat_var", 
                     "Variable de stratification (optionnelle):", 
                     choices = NULL, 
                     options = list(placeholder = "Aucune stratification")),
        
        # Option de pondération
        selectizeInput("weight_var", 
                     "Variable de pondération (optionnelle):", 
                     choices = NULL, 
                     options = list(placeholder = "Aucune pondération")),
        
        # Options d'affichage
        checkboxInput("striped_rows", "Lignes alternées", value = TRUE),
        
        # Statistiques descriptives pour les variables quantitatives
        h4("Statistiques descriptives"),
        
        checkboxGroupInput("desc_stats", "Pour les variables quantitatives:",
                         choices = c(
                           "Moyenne" = "mean",
                           "Médiane" = "median",
                           "Écart type" = "sd",
                           "Min/Max" = "range",
                           "Quantiles" = "quantiles"
                         ),
                         selected = c("mean", "median", "sd")),
        
        # Mode comparaison
        checkboxInput("enable_comparison", "Activer la comparaison avant/après",
                    value = FALSE),
        
        # Bouton pour créer le tableau
        actionButton("create_tabyl", "Créer le tableau", 
                   icon = icon("table"), 
                   class = "btn-primary btn-block"),
        
        hr(),
        
        # Options d'exportation
        h4("Exportation"),
        
        selectInput("export_format", "Format d'exportation:", 
                  choices = c("Excel (.xlsx)" = "xlsx",
                             "CSV (.csv)" = "csv",
                             "HTML (.html)" = "html",
                             "PDF (.pdf)" = "pdf")),
        
        downloadButton("export_table", "Exporter le tableau", 
                     icon = icon("download"), 
                     class = "btn-success btn-block")
      )
    ),
    
    column(9,
      # Titre du tableau
      div(class = "panel panel-primary",
          div(class = "panel-heading text-center",
              h3(class = "panel-title", 
                 icon("chart-bar", class = "mr-2"),
                 "Tableau statistique descriptif"
              )
          ),
          div(class = "panel-body",
              # Messages d'erreur ou d'avertissement
              uiOutput("tabyl_message"),
              
              # Résultats du tableau statistique
              shinyjs::hidden(
                div(id = "gtsummary_table", 
                    style = "overflow-x: auto;",
                    htmlOutput("gtsummary_table")
                )
              ),
              
              # Section de comparaison (affichée conditionnellement)
              conditionalPanel(
                condition = "input.enable_comparison == true",
                hr(),
                div(class = "well",
                    h4(class = "text-center", 
                       icon("exchange-alt", class = "mr-2"), 
                       "Comparaison avant/après"),
                    div(class = "row",
                        column(6,
                              div(class = "panel panel-info",
                                  div(class = "panel-heading", 
                                      h4(class = "panel-title text-center", "Données originales")),
                                  div(class = "panel-body",
                                      htmlOutput("comparison_original")
                                  )
                              )
                        ),
                        column(6,
                              div(class = "panel panel-success",
                                  div(class = "panel-heading", 
                                      h4(class = "panel-title text-center", "Données nettoyées")),
                                  div(class = "panel-body",
                                      htmlOutput("comparison_cleaned")
                                  )
                              )
                        )
                    ),
                    div(class = "text-center mt-4",
                        actionButton("refresh_comparison", "Actualiser la comparaison",
                                   icon = icon("sync"),
                                   class = "btn-info")
                    )
                )
              )
          )
      ),
      
      # Message d'information sur l'exportation
      div(class = "alert alert-info mt-3",
          icon("info-circle"),
          "Les données exportées contiendront toutes les transformations appliquées."
      )
    )
  )
)
