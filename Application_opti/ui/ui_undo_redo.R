# ui/ui_undo_redo.R

div(class = "undo-redo-panel",
    div(class = "well-panel",
        h4(icon("history"), "Historique des modifications"),
        div(class = "row",
            div(class = "col-md-6",
                actionButton("undo_action", "Annuler", 
                             icon = icon("undo"), 
                             class = "btn btn-warning btn-block")
            ),
            div(class = "col-md-6",
                actionButton("redo_action", "Rétablir", 
                             icon = icon("redo"), 
                             class = "btn btn-info btn-block")
            )
        ),
        hr(),
        div(class = "history-info",
            uiOutput("history_status"),
            uiOutput("history_list")
        )
    )
) 