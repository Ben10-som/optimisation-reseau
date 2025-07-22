# ui/ui_search.R

div(class = "container-fluid",
    div(class = "row",
        column(4,
               div(class = "well-panel",
                   h4(icon("search"), "Recherche des fonctions Janitor"),
                   
                   # Sélection des fonctions
                   selectizeInput("janitor_functions", "Fonctions Janitor:", choices = janitor_functions,
                                  multiple = TRUE,
                                  options = list(
                                    placeholder = 'Sélectionnez une ou plusieurs fonctions',
                                    maxOptions = length(janitor_functions)
                                  )),
                   
                   # Sélection des sources
                   checkboxGroupInput("search_sources", "Sources:",
                                     c("Google" = "google",
                                       "StackOverflow" = "stackoverflow",
                                       "RDocumentation" = "rdoc",
                                       "GitHub" = "github"),
                                     selected = c("google", "rdoc")),
                   
                   # Option pour aide par IA
                   checkboxInput("use_ai", "Utiliser l'aide IA", FALSE),
                   conditionalPanel(
                     condition = "input.use_ai == true",
                     selectInput("ai_source", "Source IA:",
                                choices = c("ChatGPT" = "chatgpt",
                                           "Bard" = "bard",
                                           "GitHub Copilot" = "copilot"))
                   ),
                   
                   # Bouton de recherche
                   actionButton("search_button", "Rechercher", icon = icon("search"), 
                               class = "btn btn-primary btn-action"),
                   
                   hr(),
                   
                   # Historique des recherches
                   h4(icon("history"), "Historique des recherches"),
                   selectInput("search_history", NULL, choices = NULL),
                   actionButton("use_history", "Utiliser cette recherche", 
                               icon = icon("arrow-rotate-left"), 
                               class = "btn btn-secondary btn-sm")
               )
        ),
        column(8,
               div(class = "well-panel",
                   tabsetPanel(id = "search_results_tabs",
                      tabPanel("Résultats", icon = icon("search"),
                              uiOutput("search_results"),
                              uiOutput("ai_results"),
                              tags$div(id = "loading_message", style = "display: none;",
                                      div(class = "loader", style = "width: 20px; height: 20px; margin: 10px auto;"))
                      ),
                      tabPanel("Documentation", icon = icon("book"),
                              h4("Documentation Janitor"),
                              uiOutput("docs_content")
                      ),
                      tabPanel("Exemples", icon = icon("code"),
                              h4("Exemples de code"),
                              verbatimTextOutput("code_examples")
                      )
                   )
               )
        )
    )
)
