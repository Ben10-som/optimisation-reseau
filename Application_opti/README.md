# Nettoyage automatique avec Janitor - Application Shiny

[![Shiny](https://img.shields.io/badge/Shiny-2.0+-blue?logo=r&logoColor=white)](https://shiny.rstudio.com/)
[![janitor](https://img.shields.io/badge/janitor-2.2.0-green)](https://github.com/sfirke/janitor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Description

Application Shiny interactive pour le nettoyage et la préparation de données utilisant le package R [`janitor`](https://github.com/sfirke/janitor).


## Fonctionnalités clés

### Nettoyage de base
- [`clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html) : Standardisation des noms de colonnes
- [`remove_empty()`](https://sfirke.github.io/janitor/reference/remove_empty.html) : Suppression des lignes/colonnes vides
- [`remove_constant()`](https://sfirke.github.io/janitor/reference/remove_constant.html) : Élimination des colonnes sans variation
- [`excel_numeric_to_date()`](https://sfirke.github.io/janitor/reference/excel_numeric_to_date.html) : Conversion des dates Excel

### Analyse des doublons
- [`get_dupes()`](https://sfirke.github.io/janitor/reference/get_dupes.html) : Identification des doublons
- [`compare_df_cols()`](https://sfirke.github.io/janitor/reference/compare_df_cols.html) : Comparaison de structure

### Tableaux Croisés
- [`tabyl()`](https://sfirke.github.io/janitor/reference/tabyl.html) : Création de tableaux croisés
- Fonctions [`adorn_*`](https://sfirke.github.io/janitor/reference/adorn_totals.html) : Mise en forme avancée

**Pour plus foctions, consultez les liens en bas**

### Structure des fichiers
- **Vu d'ensemble des UI** : Interface organisée en onglets thématiques

## Structure Globale (`ui_main.R`)

**Améliorations possibles**
- Ajouter un sélecteur de thème (dark/light mode)
- Ajouter un indicateur de chargement global

## Modules Spécifiques

### 1. Importation (`ui_import.R`)
Optimisation des imports via le format FST

Tous les fichiers importés dans l'application sont systématiquement convertis en format FST (Fast Serialization for R) après leur chargement initial.
Cette approche garantit des temps de réponse inférieurs à 500 ms même pour des datasets de 1 million de lignes, tout en nettoyant automatiquement les fichiers temporaires en fin de session via session$onSessionEnded().
- Zone de dépôt de fichiers  visible
- Options conditionnelles pour les formats CSV/TSV
- Aperçu immédiat des données
- Panneau de métadonnées


### 2. Nettoyage de Base (`ui_clean_base.R`)
- Boutons d'actions identifiés
- Gestion des doublons 
- Conversion de dates Excel pratique


### 3. Nettoyage Avancé (`ui_clean_advanced.R`)

- Organisation en 3 colonnes thématiques
- Gestion complète des NA et formats


### 4. Analyse (`ui_analysis.R`)
- Visualisation Plotly interactive
- Options de formatage des tableaux croisés
- Spiners pendant le chargement

**Potentielles améliorations**:
- Ajouter des options de personnalisation des graphiques
- Exporter les visualisations
- Faire des tableaux avec `gtsummary`

### 5. Export (`ui_export.R`)
- Classification logique des formats
- Options  conditionnelles
- Aperçu avant export

**Potentielles améliorations**:
- Options de compression pour les gros fichiers

### 6. Rapport (`ui_report.R`)
- Champ pour notes additionnelles

**Potentielles améliorations**:
- Ajouter un sélecteur de template
- Options de personnalisation avancées

### 7. Recherche (`ui_search.R`)

- Intégration directe avec Google
- Sélection multiple des fonctions

**Potentielles améliorations**:
- Ajouter d'autres sources (StackOverflow, RDocumentation)
- Historique des recherches
- Intégrer les IA


## **Vue d'ensemble du Serveur** : Gestion réactive des données

-Import des données (server_import.R)

-Nettoyage de base (server_clean_base.R)

-Nettoyage avancé (server_clean_advanced.R)

-Analyse des données (server_analysis.R)

-Export des données (server_export.R)

-Génération de rapports (server_report.R)

-Fonctionnalité de recherche (server_search.R)

Quelques aspects:

-Support de nombreux formats (CSV, Excel, SPSS, etc.)

-Opérations de nettoyage étendues

-Fonctionnalités d'analyse (tableaux croisés, visualisations)

Expérience Utilisateur :

-Notifications

-Feedback sonore avec beepr

-Prévisualisation des données avec DT

Gestion des Erreurs :

-Blocs tryCatch pour une gestion des erreurs

Gestion de la Mémoire :

-Utilisation du format FST pour un stockage efficace

-Nettoyage des fichiers temporaires


## 📚 Ressources utiles


Voici quelques ressources pour l'utilisation du package `janitor`:

- [Cours de projet-statistique-sous-R dispensé par M. Aboubacar HEMA (ENSAE-Dakar)](https://github.com/Abson-dev/Projet-statistique-sous-R/tree/main)
- [Documentation officielle du package janitor](https://sfirke.github.io/janitor/)
- [Fiche janitor sur RDocumentation](https://rdocumentation.org/packages/janitor/versions/0.3.0)
- [Tutoriels R sur DellaData.fr](https://delladata.fr/)
- [Cours et ressources R de Lise Vaudor (ENS Lyon)](https://perso.ens-lyon.fr/lise.vaudor/)





Ce projet a été réalisé par :

- **Hildegarde EDIMA BIYENDA**  
   [eddiebugb@gmail.com](mailto:eddiebugb@gmail.com)

- **Djerakei MISTALENGAR**  
  [yvesdjerake@gmail.com](mailto:yvesdjerake@gmail.com)

Sous la supervision de **M. Aboubacar HEMA**,  
[Analyste de Recherche à l'IFPRI](https://www.ifpri.org/profile/aboubacar-hema)

