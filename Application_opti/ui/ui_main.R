# ui/ui_main.R

bslib::page_navbar(
  title = tags$div(
    style = "display: flex; align-items: center;",
    tags$img(src = "images/antenne.png", height = "90px", style = "margin-right:12px;")
  ),
  theme = bslib::bs_theme(
    bootswatch = "flatly",
    primary = "#0072B2",
    base_font = bslib::font_google("Roboto"),
    heading_font = bslib::font_google("Montserrat")
  ),
  window_title = "Optimisation Antennes Sénégal",
  id = "main_navbar",
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
    tags$style(HTML('
      body, .bslib-page-navbar {
        background: linear-gradient(120deg, #e0eafc 0%, #cfdef3 100%) !important;
      }
      .accueil-hero {
        background: rgba(255,255,255,0.95);
        border-radius: 24px;
        box-shadow: 0 8px 32px rgba(0,0,0,0.08);
        padding: 40px 30px 30px 30px;
        margin: 40px auto 30px auto;
        max-width: 900px;
        position: relative;
      }
      .methodo-section {
        background: rgba(255,255,255,0.97);
        border-radius: 18px;
        box-shadow: 0 4px 18px rgba(0,0,0,0.10);
        padding: 32px 24px 24px 24px;
        margin: 40px auto 30px auto;
        max-width: 900px;
      }
      .methodo-section h2 {
        color: #0072B2;
        font-weight: 800;
        margin-bottom: 18px;
      }
      .methodo-step {
        display: flex;
        align-items: flex-start;
        gap: 18px;
        margin-bottom: 18px;
      }
      .methodo-step .fa, .methodo-step .fas, .methodo-step .far, .methodo-step .fal, .methodo-step .fab {
        font-size: 2em;
        color: #0072B2;
        margin-top: 2px;
      }
      .methodo-algo {
        margin-bottom: 24px;
      }
      .methodo-formula {
        background: #f8f9fa;
        border-radius: 8px;
        padding: 12px 18px;
        font-family: "Fira Mono", "Consolas", monospace;
        font-size: 1.08em;
        margin-bottom: 12px;
        color: #333;
      }
    '))
  ),
  bslib::nav_panel(
    tagList(icon("home", class = "me-2"), "Accueil"),
    tags$style(HTML(
      "body[data-page='accueil'] { \
        background-image: url('images/fond.png'); \
        background-size: cover; \
        background-position: center; \
        background-repeat: no-repeat; \
        background-attachment: fixed; \
      }"
    )),
    div(class = "accueil-hero",
        tags$img(src = "images/anten_sen.png", height = "120px", style = "margin-bottom: 18px; border-radius:18px;"),
        div(class = "hero-box",
            tags$h1(style = "font-weight:900; font-size:1.6em; color:#0072B2; margin-bottom:10px; letter-spacing:1px; text-shadow:0 2px 8px #e0eafc;", "Optimisation intelligente des antennes au Sénégal"),
            div(class = "slogan", icon("lightbulb", class = "text-warning me-2 fa-bounce"), HTML("<span style='color:#00c6fb;font-weight:700; font-size:1.2em;'>Une plateforme innovante pour une connectivité optimale !</span>")),
            tags$p("Cette plateforme interactive vous permet d’analyser, de visualiser et d’optimiser le placement des antennes de télécommunication au Sénégal, en combinant données, algorithmes avancés et visualisation intuitive.", style = "font-size:1.15em; max-width:700px; margin:auto; margin-bottom: 0; color:#333;")
        ),
        div(class = "accueil-cards",
            div(class = "accueil-card box-blue",
                icon("map-marked-alt", class = "fa-2x"),
                div(class = "objectif", style = "font-weight:700; font-size:1.1em;", "Cartographie & Données"),
                tags$p("Explorez la couverture réseau, la répartition des antennes et les statistiques régionales sur des cartes interactives et dynamiques.")
            ),
            div(class = "accueil-card box-green",
                icon("cogs", class = "fa-2x"),
                div(class = "objectif", style = "font-weight:700; font-size:1.1em;", "Optimisation Avancée"),
                tags$p("Testez différents scénarios d’implantation d’antennes et comparez les résultats d’optimisation (MADS, Tabou, Hybride) pour maximiser la couverture et la qualité.")
            ),
            div(class = "accueil-card box-yellow",
                icon("chart-line", class = "fa-2x"),
                div(class = "objectif", style = "font-weight:700; font-size:1.1em;", "Analyse & Résultats"),
                tags$p("Analysez les performances obtenues (couverture, SIR, coût) et exportez les résultats pour vos rapports ou présentations.")
            ),
            div(class = "accueil-card box-cyan",
                icon("users", class = "fa-2x"),
                div(class = "objectif", style = "font-weight:700; font-size:1.1em;", "Collaboration & Décision"),
                tags$p("Partagez vos analyses, impliquez les parties prenantes et prenez des décisions éclairées pour le déploiement des réseaux.")
            )
        ),
        div(class = "accueil-footer",
            tags$div(style = "font-size:1.13em; font-weight:600; letter-spacing:0.5px; margin-bottom:6px; display:flex; align-items:center; justify-content:center; gap:8px;",
                icon("graduation-cap", class = "me-2"),
                HTML("Projet académique – <b>Optimisation du placement des antennes au Sénégal</b>.")
            ),
            tags$hr(style = "border-top:1.5px solid #fff; opacity:0.25; width:60%; margin:10px auto 8px auto;"),
            tags$div(style = "font-size:1.08em; color:#fff; font-weight:500; display:flex; align-items:center; justify-content:center; gap:8px;",
                icon("user-tie", class = "me-2 text-primary"),
                HTML("Sous la supervision du <b>Dr Omar DIOP</b>")
            )
        ),
    )
  ),
  bslib::nav_panel(
    tagList(icon("tachometer-alt", class = "me-2"), "Tableau de Bord"),
    mod_dashboard_ui("dashboard")
  ),
  bslib::nav_panel(
    tagList(icon("project-diagram", class = "me-2"), "Répartition Réseau"),
    mod_repartition_ui("repartition")
  ),
  bslib::nav_panel(
    tagList(icon("broadcast-tower", class = "me-2"), "Antennes Existantes"),
    mod_antennes_ui("antennes")
  ),
  bslib::nav_panel(
    tagList(icon("cogs", class = "me-2"), "Optimisation"),
    mod_optimisation_ui("optimisation")
  ),
  bslib::nav_panel(
    tagList(icon("book-open", class = "me-2"), "Méthodologie"),
    div(class = "methodo-section",
        tags$h2(icon("project-diagram", class = "me-2"), "Étapes de l'optimisation"),
        div(class = "methodo-step", icon("search-location"),
            div(
              tags$b("1. Définition de la zone d'étude et des contraintes"),
              tags$p("Sélection de la région cible, du budget, du nombre d'antennes, des contraintes techniques et géographiques.")
            )
        ),
        div(class = "methodo-step", icon("map-marked-alt"),
            div(
              tags$b("2. Modélisation du réseau"),
              tags$p("Création d'un modèle mathématique prenant en compte la propagation des ondes, la puissance, la fréquence, et la topographie.")
            )
        ),
        div(class = "methodo-step", icon("cogs"),
            div(
              tags$b("3. Optimisation des positions (MADS)"),
              tags$p("Recherche des meilleurs emplacements d'antennes pour maximiser la couverture et respecter le budget.")
            )
        ),
        div(class = "methodo-step", icon("random"),
            div(
              tags$b("4. Optimisation des fréquences (Recherche Tabou)"),
              tags$p("Affectation optimale des fréquences et puissances pour minimiser les interférences.")
            )
        ),
        div(class = "methodo-step", icon("chart-line"),
            div(
              tags$b("5. Analyse et visualisation des résultats"),
              tags$p("Cartes, statistiques, heatmaps, et export des résultats pour la prise de décision.")
            )
        ),
        tags$hr(),
        tags$h2(icon("brain", class = "me-2"), "Algorithmes utilisés"),
        div(class = "methodo-algo",
            tags$h4(icon("cogs", class = "me-2 text-success"), "MADS (Mesh Adaptive Direct Search)"),
            tags$p("Algorithme d'optimisation sans dérivée, adapté aux problèmes complexes et non convexes. Il explore l'espace des positions d'antennes par maillage adaptatif pour maximiser la couverture et respecter les contraintes."),
            tags$div(class = "methodo-formula", "f(x) = w1 * U(x) + w2 * I(x) + w3 * C(x)")
        ),
        div(class = "methodo-algo",
            tags$h4(icon("random", class = "me-2 text-info"), "Recherche Tabou"),
            tags$p("Métaheuristique pour optimiser les variables discrètes (fréquences, puissances). Utilise une liste tabou pour éviter les solutions déjà testées et sortir des minima locaux."),
            tags$div(class = "methodo-formula", "g(s) = w2 * I(s) + w4 * Q(s)")
        ),
        div(class = "methodo-algo",
            tags$h4(icon("layer-group", class = "me-2 text-warning"), "Approche Hybride"),
            tags$p("Combine MADS pour les positions et Recherche Tabou pour les fréquences/puisances, afin d'obtenir une solution globale optimale.")
        ),
        tags$hr(),
        tags$h2(icon("calculator", class = "me-2"), "Formules clés"),
        tags$div(class = "methodo-formula", HTML("<b>Modèle de Friis :</b><br>Pr = Pt / (d<sup>α</sup> × (f/1000)<sup>2</sup>)")),
        tags$div(class = "methodo-formula", HTML("<b>SIR (Signal to Interference Ratio) :</b><br>SIR = Signal / Interférences")),
        tags$div(class = "methodo-formula", HTML("<b>Fonction objectif globale :</b><br>min w1 × U(x, s) + w2 × I(x, s) + w3 × C(x, s)")),
        tags$div(class = "methodo-formula", HTML("<b>Capacité de Shannon :</b><br>C = Δf × log<sub>2</sub>(1 + SNR)")),
        tags$hr(),
        tags$p("Pour plus de détails, consultez le rapport ou contactez l'équipe projet.", style = "color:#888; font-size:1em;")
    )
  ),
  bslib::nav_panel(
    tagList(icon("chart-line", class = "me-2"), "Résultats"),
    mod_resultats_ui("resultats")
  )
)
