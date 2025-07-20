# server/server_search.R

# Initialiser un objet reactiveValues pour stocker l'historique des recherches
rv_search <- reactiveValues(
  history = list(),
  current_results = NULL
)

observe({
  updateSelectizeInput(
    session,
    "janitor_functions",
    choices = janitor_functions,
    server = TRUE
  )
})

# Mise à jour de l'historique des recherches
observe({
  req(length(rv_search$history) > 0)
  
  # Créer des étiquettes pour l'historique (date + fonctions)
  history_labels <- lapply(rv_search$history, function(item) {
    paste0(format(item$timestamp, "%Y-%m-%d %H:%M"), ": ", 
           paste(item$functions, collapse = ", "))
  })
  
  # Mettre à jour le sélecteur d'historique
  updateSelectInput(session, "search_history", 
                   label = paste("Historique (", length(rv_search$history), ")"),
                   choices = setNames(seq_along(rv_search$history), unlist(history_labels)))
})

# Utiliser une recherche depuis l'historique
observeEvent(input$use_history, {
  req(input$search_history, rv_search$history)
  
  # Récupérer la recherche sélectionnée
  selected_search <- rv_search$history[[as.numeric(input$search_history)]]
  
  # Mettre à jour l'interface avec les paramètres historiques
  updateSelectizeInput(session, "janitor_functions", 
                      selected = selected_search$functions)
  
  updateCheckboxGroupInput(session, "search_sources",
                          selected = selected_search$sources)
  
  # Exécuter automatiquement la recherche
  if(length(selected_search$functions) > 0) {
    session$userData$show_loading()
    Sys.sleep(0.5)  # Petit délai pour l'effet visuel
    perform_search(selected_search$functions, selected_search$sources)
    session$userData$hide_loading()
  }
})

# Fonction pour exécuter la recherche
perform_search <- function(functions, sources) {
  results <- list()
  
  # Construire la requête de base
  search_terms <- paste(functions, collapse = " ")
  base_query <- paste("R package janitor", search_terms)
  
  # Recherche Google
  if("google" %in% sources) {
    google_url <- paste0("https://www.google.com/search?q=", URLencode(base_query))
    results$google <- list(
      url = google_url,
      label = "Google"
    )
  }
  
  # Recherche StackOverflow
  if("stackoverflow" %in% sources) {
    so_url <- paste0("https://stackoverflow.com/search?q=", URLencode(paste("[r]", base_query)))
    results$stackoverflow <- list(
      url = so_url,
      label = "StackOverflow"
    )
  }
  
  # Recherche RDocumentation
  if("rdoc" %in% sources) {
    rdoc_functions <- paste(functions, collapse = "+")
    rdoc_url <- paste0("https://www.rdocumentation.org/packages/janitor/versions/2.2.0/topics/", rdoc_functions)
    results$rdoc <- list(
      url = rdoc_url,
      label = "RDocumentation"
    )
  }
  
  # Recherche GitHub
  if("github" %in% sources) {
    github_url <- paste0("https://github.com/sfirke/janitor/search?q=", URLencode(search_terms))
    results$github <- list(
      url = github_url,
      label = "GitHub"
    )
  }
  
  # Stocker les résultats courants
  rv_search$current_results <- results
  
  # Ajouter à l'historique
  new_history_item <- list(
    timestamp = Sys.time(),
    functions = functions,
    sources = sources,
    results = results
  )
  
  # Ajouter au début de l'historique (limiter à 20 entrées)
  rv_search$history <- c(list(new_history_item), rv_search$history)
  if(length(rv_search$history) > 20) {
    rv_search$history <- rv_search$history[1:20]
  }
  
  # Retourner les résultats pour affichage
  return(results)
}

# Gestion du bouton de recherche
observeEvent(input$search_button, {
  req(input$janitor_functions, input$search_sources)
  
  # Afficher l'indicateur de chargement
  session$userData$show_loading()
  shinyjs::show("loading_message")
  
  # Effectuer la recherche
  results <- perform_search(input$janitor_functions, input$search_sources)
  
  # Masquer l'indicateur de chargement
  session$userData$hide_loading()
  shinyjs::hide("loading_message")
  
  # Notification sonore
  beepr::beep(5)
  showNotification("Recherche terminée", type = "message")
})

# Affichage des résultats de recherche
output$search_results <- renderUI({
  req(rv_search$current_results)
  
  results <- rv_search$current_results
  result_links <- lapply(results, function(result) {
    tags$div(
      tags$h4(result$label),
      tags$a(href = result$url, target = "_blank", 
             class = "btn btn-info",
             tags$i(class = "fa fa-external-link-alt"), 
             paste("Voir les résultats sur", result$label))
    )
  })
  
  # Création de l'UI des résultats
  tagList(
    tags$h3("Résultats pour: ", paste(input$janitor_functions, collapse = ", ")),
    tags$div(class = "search-results-container", 
            style = "margin-top: 20px;",
            result_links)
  )
})

# Gestion de l'aide IA (si activée)
observeEvent(input$search_button, {
  req(input$janitor_functions, input$use_ai == TRUE)
  
  # Simuler une réponse IA 
  # (dans une vraie application, vous appelleriez l'API de l'IA choisie)
  ai_source <- input$ai_source
  functions_text <- paste(input$janitor_functions, collapse = ", ")
  
  # Délai pour simuler le temps de réponse de l'IA
  Sys.sleep(1.5)
  
  output$ai_results <- renderUI({
    if(input$use_ai) {
      tags$div(
        class = "ai-response",
        style = "background-color: #f0f8ff; border-left: 4px solid #3498db; padding: 15px; margin-top: 20px;",
        tags$h4(paste("Réponse de", ai_source)),
        tags$p(paste("Voici quelques informations sur les fonctions janitor:", functions_text)),
        tags$p("Pour utiliser ces fonctions, assurez-vous d'avoir installé le package janitor."),
        tags$pre(paste0("install.packages('janitor')\nlibrary(janitor)\n\n# Exemple d'utilisation\n",
                      "# ", input$janitor_functions[1], "(data)"))
      )
    }
  })
})

# Contenu de documentation
output$docs_content <- renderUI({
  req(input$janitor_functions)
  
  # Créer des liens vers la documentation pour chaque fonction
  doc_links <- lapply(input$janitor_functions, function(func) {
    tags$div(
      tags$h4(func),
      tags$p("Documentation officielle:"),
      tags$a(
        href = paste0("https://sfirke.github.io/janitor/reference/", func, ".html"),
        target = "_blank",
        paste("Voir la documentation de", func)
      ),
      tags$hr()
    )
  })
  
  tagList(doc_links)
})

# Exemples de code
output$code_examples <- renderText({
  req(input$janitor_functions)
  
  # Générer des exemples de code pour les fonctions sélectionnées
  example_code <- paste0("# Exemples pour les fonctions janitor\n\n")
  
  for(func in input$janitor_functions) {
    example_code <- paste0(example_code, "# Exemple pour ", func, "\n")
    
    # Ajouter des exemples spécifiques selon la fonction
    if(func == "clean_names") {
      example_code <- paste0(example_code, 
                            "library(janitor)\n",
                            "data <- data.frame('First Name' = c('John', 'Jane'), 'Last Name' = c('Doe', 'Smith'))\n",
                            "data_clean <- clean_names(data)\n",
                            "# Résultat: colonnes deviennent 'first_name' et 'last_name'\n\n")
    } else if(func == "tabyl") {
      example_code <- paste0(example_code,
                            "library(janitor)\n",
                            "mtcars %>% tabyl(cyl, gear) %>% adorn_percentages()\n\n")
    } else if(func == "get_dupes") {
      example_code <- paste0(example_code,
                            "library(janitor)\n",
                            "data <- data.frame(x = c(1, 1, 2), y = c('a', 'a', 'b'))\n",
                            "get_dupes(data, x)\n\n")
    } else {
      example_code <- paste0(example_code,
                            "library(janitor)\n",
                            "# Voir la documentation pour des exemples détaillés\n",
                            "?", func, "\n\n")
    }
  }
  
  return(example_code)
})
