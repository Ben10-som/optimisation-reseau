# server/server_clean_base.R

# Nettoyage des noms
observeEvent(input$clean_names, {
  req(rv$clean_data)
  tryCatch({
    rv$clean_data <- janitor::clean_names(rv$clean_data)
    log_action("✔ Noms nettoyés", "rv$clean_data <- janitor::clean_names(rv$clean_data)")
    save_state()  # Sauvegarder l'état après modification
    showNotification("✔ Noms nettoyés", type = "message")
    beepr::beep(10)
  }, error = function(e) {
    showNotification(paste("Erreur :", e$message), type = "error")
  })
})

# Suppression des lignes/colonnes vides
observeEvent(input$remove_empty, {
  req(rv$clean_data)
  tryCatch({
    rv$clean_data <- janitor::remove_empty(rv$clean_data, c("rows", "cols"))
    log_action("🗑️ Lignes et colonnes vides supprimées", 
              "rv$clean_data <- janitor::remove_empty(rv$clean_data, c(\"rows\", \"cols\"))")
    save_state()  # Sauvegarder l'état après modification
    showNotification("✔ Suppression des vides effectuée", type = "message")
    beepr::beep(10)
  }, error = function(e) {
    showNotification(paste("Erreur :", e$message), type = "error")
  })
})

# Colonnes constantes
observeEvent(input$remove_constant, {
  req(rv$clean_data)
  tryCatch({
    rv$clean_data <- janitor::remove_constant(rv$clean_data)
    log_action("🔁 Colonnes constantes supprimées", 
              "rv$clean_data <- janitor::remove_constant(rv$clean_data)")
    save_state()  # Sauvegarder l'état après modification
    showNotification("✔ Suppression des constantes effectuée", type = "message")
    beepr::beep(10)
  }, error = function(e) {
    showNotification(paste("Erreur :", e$message), type = "error")
  })
})

# Nettoyage des facteurs
observeEvent(input$clean_factors, {
  req(rv$clean_data)
  tryCatch({
    rv$clean_data <- rv$clean_data %>%
      mutate(across(where(is.factor), janitor::make_clean_names))
    log_action("🏷️ Facteurs nettoyés", 
              "rv$clean_data <- rv$clean_data %>% mutate(across(where(is.factor), janitor::make_clean_names))")
    save_state()  # Sauvegarder l'état après modification
    showNotification("✔ Facteurs nettoyés", type = "message")
    beepr::beep(10)
  }, error = function(e) {
    showNotification(paste("Erreur :", e$message), type = "error")
  })
})

# Conversion des dates Excel
observeEvent(input$convert_date, {
  tryCatch({
    excel_date <- input$excel_date
    converted_date <- janitor::excel_numeric_to_date(excel_date)
    log_action("📅 Date Excel convertie", 
              paste0("converted_date <- janitor::excel_numeric_to_date(", excel_date, ")"))
    output$excel_date_result <- renderText({
      paste("Date convertie:", as.character(converted_date))
    })
    beepr::beep(10)
  }, error = function(e) {
    showNotification(paste("Erreur:", e$message), type = "error")
  })
})

observeEvent(input$find_dupes, {
  req(rv$clean_data, input$dupe_cols)
  tryCatch({
    dupes <- rv$clean_data %>% janitor::get_dupes(!!!syms(input$dupe_cols))
    if(nrow(dupes) > 0) {
      rv$dupes_data <- dupes %>% arrange(desc(dupe_count))
      log_action("🔍 Recherche de doublons effectuée", 
                paste0("dupes <- rv$clean_data %>% janitor::get_dupes(", paste(input$dupe_cols, collapse = ", "), ")"))
    } else {
      rv$dupes_data <- NULL
      log_action("🔍 Aucun doublon trouvé", 
                paste0("rv$clean_data %>% janitor::get_dupes(", paste(input$dupe_cols, collapse = ", "), ")"))
      showNotification("Aucun doublon trouvé.", type = "message")
    }
  }, error = function(e) {
    showNotification(paste("Erreur:", e$message), type = "error")
  })
})

output$clean_table <- renderDT({
  req(rv$clean_data)
  datatable(rv$clean_data, 
            options = list(
              scrollX = TRUE, 
              pageLength = 5,
              dom = 'Bfrtip',
              buttons = c('copy', 'csv', 'excel')
            ),
            extensions = 'Buttons',
            rownames = FALSE
  )
})

output$dupes_table <- renderDT({
  req(rv$dupes_data)
  datatable(rv$dupes_data,
            options = list(scrollX = TRUE, pageLength = 5, dom = 'Bfrtip', buttons = c('copy', 'csv', 'excel')),
            extensions = 'Buttons', rownames = FALSE) %>%
    formatStyle("dupe_count", backgroundColor = styleInterval(c(1, 2), c("white", "#fff3cd", "#f8d7da")))
})