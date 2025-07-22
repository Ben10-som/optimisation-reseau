Optimisation du Placement des Antennes Réseaux au Sénégal
Contexte et Problématique
Ce projet vise à optimiser le placement des antennes de télécommunication au Sénégal pour réduire la fracture numérique, particulièrement dans les zones rurales comme Kédougou, Tambacounda, et Matam. Avec une pénétration mobile de 58 % en 2022 mais des disparités marquées entre zones urbaines et rurales, l’accès à la 4G reste limité dans ces régions en raison de contraintes géographiques (collines, végétation dense) et budgétaires.
Objectifs

Maximiser la couverture réseau pour améliorer l’accès à Internet.
Minimiser les interférences pour garantir une bonne qualité de signal (rapport signal-bruit, SIR).
Minimiser les coûts de déploiement tout en respectant un budget limité (par exemple, 10 millions FCFA).


Méthodologie
Algorithmes d’Optimisation
Trois approches sont utilisées pour résoudre le problème :

MADS (Mesh Adaptive Direct Search) 
Recherche Tabou 
Approche Hybride : Combine MADS (positions) et Recherche Tabou (fréquences, puissances) pour une optimisation globale.

Implémentation Pratique

Discrétisation : Grille régulière ou tessellation de Voronoï pour les positions.
Simulation : Calcul du SIR pour chaque point utilisateur.
Visualisation : Cartes de chaleur pour analyser la couverture.

Structure du Projet
antenna-optimization-senegal/
├── data/
│   ├── carte.png                # Carte de densité du Sénégal
│   ├── carte_couverture_2G.png  # Couverture 2G
│   ├── carte_couverture_3G.png  # Couverture 3G
│   ├── carte_couverture_4G.png  # Couverture 4G
│   ├── coverage_per_operator.png # Couverture par opérateur
├── images/
│   ├── antenne.png              # Image pour la page de titre
│   ├── fibre.jpg                # Image pour les canaux de communication
├── src/
│   ├── mads.py                  # Implémentation de l’algorithme MADS
│   ├── tabu_search.py           # Implémentation de la Recherche Tabou
│   ├── hybrid_approach.py       # Implémentation de l’approche hybride
├── docs/
│   ├── presentation.tex         # Fichier LaTeX de la présentation Beamer
│   ├── presentation.pdf         # PDF compilé de la présentation
├── README.md                    # Ce fichier
├── requirements.txt             # Dépendances Python



Perspectives

Intégration de données en temps réel (mobilité, usage).
Amélioration des algorithmes pour réduire le temps de calcul.
Collaboration avec les opérateurs (Orange, Free, Expresso) pour une implémentation pratique.



Auteurs

SOMA Ben Idriss
Yves Djerakeï Mistalengar

Superviseur : M. Omar DIOP, Docteur en MathématiquesInstitution : École nationale de la Statistique et de l’Analyse économique Pierre Ndiaye

Merci à l’ENSAE Pierre Ndiaye et à notre superviseur pour leur soutien dans ce projet visant à réduire la fracture numérique au Sénégal.
