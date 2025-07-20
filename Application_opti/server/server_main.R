# server/server_main.R

function(input, output, session) {
  # Variables réactives globales
  resultats_optimisation <- reactiveVal(NULL)

  # Appel des modules
  callModule(mod_dashboard_server, "dashboard")
  callModule(mod_repartition_server, "repartition")
  callModule(mod_antennes_server, "antennes")
  callModule(mod_optimisation_server, "optimisation", resultats_optimisation = resultats_optimisation)
  callModule(mod_resultats_server, "resultats", resultats_optimisation = resultats_optimisation)
}
