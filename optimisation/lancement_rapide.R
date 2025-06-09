# ================================================================
# LANCEMENT RAPIDE - BOOKDOWN + SHINY
# Optimisation du Placement des Antennes au Sénégal
# ================================================================

cat("🚀 LANCEMENT RAPIDE - PROJET OPTIMISATION ANTENNES SÉNÉGAL\n")
cat("==========================================================\n\n")

# ================================================================
# 1. VÉRIFICATION DE L'ENVIRONNEMENT
# ================================================================

cat("🔍 1. Vérification de l'environnement...\n")

# Packages nécessaires
packages_requis <- c(
  # Pour Bookdown
  "bookdown", "knitr", "rmarkdown", "kableExtra", 
  # Pour Shiny
  "shiny", "shinydashboard", "DT", "plotly", "leaflet",
  # Pour analyses
  "ggplot2", "dplyr", "GA"
)

# Fonction d'installation automatique
installer_si_manquant <- function(packages) {
  for(pkg in packages) {
    if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat(sprintf("📦 Installation de %s...\n", pkg))
      install.packages(pkg, quiet = TRUE)
      if(require(pkg, character.only = TRUE, quietly = TRUE)) {
        cat(sprintf("   ✅ %s installé avec succès\n", pkg))
      } else {
        cat(sprintf("   ❌ Échec installation %s\n", pkg))
      }
    } else {
      cat(sprintf("   ✅ %s déjà disponible\n", pkg))
    }
  }
}

# Installation des packages
installer_si_manquant(packages_requis)

# ================================================================
# 2. VÉRIFICATION DES FICHIERS PROJET
# ================================================================

cat("\n📁 2. Vérification des fichiers du projet...\n")

fichiers_bookdown <- c(
  "index.Rmd", "_bookdown.yml", "_output.yml", "01-introduction.Rmd"
)

fichiers_shiny <- c(
  "app_shiny_antennes/app.R"
)

fichiers_scripts <- c(
  "optimisation_antennes_senegal.R",
  "README_PROJET_ANTENNES.md", 
  "plan_innovant_antennes_senegal.md"
)

# Vérification Bookdown
cat("\n📖 Fichiers Bookdown:\n")
for(fichier in fichiers_bookdown) {
  if(file.exists(fichier)) {
    cat(sprintf("   ✅ %s\n", fichier))
  } else {
    cat(sprintf("   ⚠️ %s manquant\n", fichier))
  }
}

# Vérification Shiny
cat("\n🖥️ Fichiers Shiny:\n")
for(fichier in fichiers_shiny) {
  if(file.exists(fichier)) {
    cat(sprintf("   ✅ %s\n", fichier))
  } else {
    cat(sprintf("   ⚠️ %s manquant\n", fichier))
  }
}

# Vérification Scripts
cat("\n📄 Scripts du projet:\n")
for(fichier in fichiers_scripts) {
  if(file.exists(fichier)) {
    cat(sprintf("   ✅ %s\n", fichier))
  } else {
    cat(sprintf("   ⚠️ %s manquant\n", fichier))
  }
}

# ================================================================
# 3. FONCTIONS DE LANCEMENT
# ================================================================

cat("\n🎛️ 3. Fonctions de lancement disponibles...\n")

# Fonction pour tester Bookdown
tester_bookdown <- function() {
  cat("\n📖 Test du Bookdown...\n")
  
  tryCatch({
    if(!require("bookdown", quietly = TRUE)) {
      stop("Package bookdown non disponible")
    }
    
    if(file.exists("index.Rmd")) {
      cat("   🔍 Vérification syntaxe index.Rmd...\n")
      # Test de compilation basique
      rmarkdown::render("index.Rmd", 
                       output_format = "html_document",
                       output_file = "test_index.html",
                       quiet = TRUE)
      cat("   ✅ Compilation index.Rmd réussie\n")
      
      # Nettoyage
      if(file.exists("test_index.html")) {
        file.remove("test_index.html")
      }
      
    } else {
      cat("   ⚠️ Fichier index.Rmd manquant\n")
    }
    
  }, error = function(e) {
    cat(sprintf("   ❌ Erreur test Bookdown: %s\n", e$message))
  })
}

# Fonction pour tester Shiny
tester_shiny <- function() {
  cat("\n🖥️ Test de l'application Shiny...\n")
  
  tryCatch({
    if(!require("shiny", quietly = TRUE)) {
      stop("Package shiny non disponible")
    }
    
    if(file.exists("app_shiny_antennes/app.R")) {
      cat("   🔍 Vérification syntaxe app.R...\n")
      
      # Test de parsing basique
      source("app_shiny_antennes/app.R", local = TRUE)
      cat("   ✅ Syntaxe app.R correcte\n")
      
    } else {
      cat("   ⚠️ Fichier app.R manquant\n")
    }
    
  }, error = function(e) {
    cat(sprintf("   ❌ Erreur test Shiny: %s\n", e$message))
  })
}

# Fonction pour lancer Bookdown
lancer_bookdown <- function() {
  cat("\n📖 Lancement du Bookdown...\n")
  
  if(!require("bookdown", quietly = TRUE)) {
    cat("   ❌ Package bookdown requis\n")
    return(FALSE)
  }
  
  if(!file.exists("index.Rmd")) {
    cat("   ❌ Fichier index.Rmd manquant\n")
    return(FALSE)
  }
  
  tryCatch({
    cat("   🔄 Génération du livre en cours...\n")
    bookdown::render_book("index.Rmd", "bookdown::gitbook", quiet = TRUE)
    cat("   ✅ Livre généré avec succès dans le dossier 'docs/'\n")
    cat("   🌐 Ouvrez 'docs/index.html' dans votre navigateur\n")
    return(TRUE)
    
  }, error = function(e) {
    cat(sprintf("   ❌ Erreur génération: %s\n", e$message))
    return(FALSE)
  })
}

# Fonction pour lancer Shiny
lancer_shiny <- function() {
  cat("\n🖥️ Lancement de l'application Shiny...\n")
  
  if(!require("shiny", quietly = TRUE)) {
    cat("   ❌ Package shiny requis\n")
    return(FALSE)
  }
  
  if(!file.exists("app_shiny_antennes/app.R")) {
    cat("   ❌ Fichier app.R manquant\n")
    return(FALSE)
  }
  
  tryCatch({
    cat("   🚀 Démarrage de l'application...\n")
    cat("   🌐 L'application va s'ouvrir dans votre navigateur\n")
    cat("   ⏹️ Appuyez sur Ctrl+C pour arrêter\n\n")
    
    shiny::runApp("app_shiny_antennes", launch.browser = TRUE)
    return(TRUE)
    
  }, error = function(e) {
    cat(sprintf("   ❌ Erreur lancement Shiny: %s\n", e$message))
    return(FALSE)
  })
}

# ================================================================
# 4. MENU INTERACTIF
# ================================================================

menu_principal <- function() {
  cat("\n🎯 MENU PRINCIPAL - OPTIMISATION ANTENNES SÉNÉGAL\n")
  cat("================================================\n")
  cat("1. 📖 Tester Bookdown\n")
  cat("2. 🖥️ Tester Application Shiny\n") 
  cat("3. 📚 Lancer Bookdown (génération complète)\n")
  cat("4. 🚀 Lancer Application Shiny\n")
  cat("5. 📋 Voir guide d'utilisation\n")
  cat("6. ❌ Quitter\n")
  cat("\nChoisissez une option (1-6): ")
  
  choix <- readline()
  
  switch(choix,
    "1" = {
      tester_bookdown()
      Sys.sleep(2)
      menu_principal()
    },
    "2" = {
      tester_shiny()
      Sys.sleep(2)
      menu_principal()
    },
    "3" = {
      if(lancer_bookdown()) {
        cat("\n📖 Bookdown prêt! Consultez le dossier 'docs/'\n")
      }
      Sys.sleep(2)
      menu_principal()
    },
    "4" = {
      lancer_shiny()
    },
    "5" = {
      afficher_guide()
      menu_principal()
    },
    "6" = {
      cat("\n👋 Au revoir! Bonne soutenance!\n")
      return(invisible())
    },
    {
      cat("\n⚠️ Option invalide. Réessayez.\n")
      Sys.sleep(1)
      menu_principal()
    }
  )
}

# Fonction guide
afficher_guide <- function() {
  cat("\n📋 GUIDE D'UTILISATION RAPIDE\n")
  cat("=============================\n")
  cat("\n📖 BOOKDOWN:\n")
  cat("• Rédaction académique interactive\n")
  cat("• Code R intégré avec résultats\n")
  cat("• Export HTML/PDF professionnel\n")
  cat("• Commande: bookdown::render_book('index.Rmd')\n")
  
  cat("\n🖥️ SHINY:\n")
  cat("• Interface d'optimisation interactive\n")
  cat("• Algorithme GSAGC en temps réel\n")
  cat("• Visualisations et cartes avancées\n") 
  cat("• Commande: shiny::runApp('app_shiny_antennes')\n")
  
  cat("\n🎓 POUR LA SOUTENANCE:\n")
  cat("• Démonstration live des deux outils\n")
  cat("• Bookdown pour la théorie et méthodes\n")
  cat("• Shiny pour l'interaction et résultats\n")
  cat("• Exportation automatique de rapports\n")
  
  cat("\n📞 AIDE:\n")
  cat("• Consultez GUIDE_BOOKDOWN_SHINY.md\n")
  cat("• README_PROJET_ANTENNES.md\n")
  cat("• plan_innovant_antennes_senegal.md\n")
  
  cat("\nAppuyez sur Entrée pour continuer...")
  readline()
}

# ================================================================
# 5. TESTS AUTOMATIQUES
# ================================================================

executer_tests_auto <- function() {
  cat("\n🧪 Exécution des tests automatiques...\n")
  
  # Test Bookdown
  tester_bookdown()
  
  # Test Shiny 
  tester_shiny()
  
  cat("\n✅ Tests terminés!\n")
}

# ================================================================
# 6. LANCEMENT PRINCIPAL
# ================================================================

cat("\n🎉 PROJET OPTIMISATION ANTENNES SÉNÉGAL PRÊT!\n")
cat("============================================\n")

cat("\n🎯 OBJECTIF: Algorithme GSAGC pour placement optimal d'antennes\n")
cat("🇸🇳 PAYS: République du Sénégal\n") 
cat("🔬 INNOVATION: Genetic-Simulated Annealing with Geographic Clustering\n")
cat("📚 OUTILS: Bookdown (documentation) + Shiny (interface)\n")

# Exécution des tests automatiques
executer_tests_auto()

# Lancement du menu interactif si en mode interactif
if(interactive()) {
  cat("\n🎛️ Menu interactif disponible!\n")
  menu_principal()
} else {
  cat("\n💡 COMMANDES RAPIDES:\n")
  cat("   Bookdown: bookdown::render_book('index.Rmd')\n")
  cat("   Shiny: shiny::runApp('app_shiny_antennes')\n")
  cat("   Menu: source('lancement_rapide.R')\n")
}

cat("\n🏆 Bonne chance pour votre soutenance d'optimisation!\n") 