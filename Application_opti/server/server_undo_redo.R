# server/server_undo_redo.R

# Initialisation - Sauvegarder l'état initial après importation des données
observeEvent(rv$clean_data, {
  # N'enregistrer l'état que si les données sont non vides
  if (!is.null(rv$clean_data) && nrow(rv$clean_data) > 0) {
    # Sauvegarder l'état initial seulement si l'historique est vide
    if (length(rv$history) == 0) {
      # Sauvegarder l'état initial
      save_state()
      log_action("📝 État initial enregistré dans l'historique")
    }
  }
}, ignoreNULL = TRUE, once = TRUE)

# Annuler la dernière action
observeEvent(input$undo_action, {
  # Vérifier si l'annulation est possible
  if (rv$history_index > 1) {
    # Décrémenter l'index
    rv$history_index <- rv$history_index - 1
    
    # Restaurer l'état précédent
    previous_state <- rv$history[[rv$history_index]]
    rv$clean_data <- data.frame(previous_state$clean_data)
    
    log_action("↩️ Action annulée - Retour à l'état précédent")
    showNotification("Action annulée", type = "message")
  } else {
    showNotification("Impossible d'annuler davantage, vous êtes au premier état", type = "warning")
  }
})

# Rétablir l'action annulée
observeEvent(input$redo_action, {
  # Vérifier si le rétablissement est possible
  if (rv$history_index < length(rv$history)) {
    # Incrémenter l'index
    rv$history_index <- rv$history_index + 1
    
    # Restaurer l'état suivant
    next_state <- rv$history[[rv$history_index]]
    rv$clean_data <- data.frame(next_state$clean_data)
    
    log_action("↪️ Action rétablie - Retour à l'état suivant")
    showNotification("Action rétablie", type = "message")
  } else {
    showNotification("Impossible de rétablir davantage, vous êtes au dernier état", type = "warning")
  }
})

# Afficher l'état actuel de l'historique
output$history_status <- renderUI({
  if (length(rv$history) > 0) {
    div(
      p(paste("État actuel:", rv$history_index, "sur", length(rv$history))),
      tags$small(paste("Dernière modification:", format(rv$history[[rv$history_index]]$timestamp, "%H:%M:%S")))
    )
  } else {
    p("Aucun historique disponible")
  }
})

# Afficher la liste des états
output$history_list <- renderUI({
  if (length(rv$history) > 0) {
    history_items <- lapply(1:length(rv$history), function(i) {
      item_class <- if (i == rv$history_index) "active" else ""
      tags$li(class = paste("list-group-item", item_class),
             tags$small(format(rv$history[[i]]$timestamp, "%H:%M:%S")),
             span(paste(" - ", rv$history[[i]]$description)))
    })
    
    tags$ul(class = "list-group history-list", style = "max-height: 150px; overflow-y: auto;",
           history_items)
  }
}) 