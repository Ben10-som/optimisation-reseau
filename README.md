Optimisation du Placement des Antennes Réseaux au Sénégal
Contexte et Problématique
Ce projet vise à optimiser le placement des antennes de télécommunication au Sénégal pour réduire la fracture numérique, particulièrement dans les zones rurales comme Kédougou, Tambacounda, et Matam. Avec une pénétration mobile de 58 % en 2022 mais des disparités marquées entre zones urbaines et rurales, l’accès à la 4G reste limité dans ces régions en raison de contraintes géographiques (collines, végétation dense) et budgétaires.
Objectifs

Maximiser la couverture réseau pour améliorer l’accès à Internet.
Minimiser les interférences pour garantir une bonne qualité de signal (rapport signal-bruit, SIR).
Minimiser les coûts de déploiement tout en respectant un budget limité (par exemple, 10 millions FCFA).

Modélisation Mathématique
Le problème est formulé comme une optimisation multi-objectif avec les composantes suivantes :

Couverture réseau (( U(\mathbf{x}, \mathbf{f}, \mathbf{p}) )) :[U(\mathbf{x}) = \sum_{j=1}^m \mathbf{1}_{{\text{SIR}(p_j) \geq \theta}}]Compte les points où le SIR dépasse un seuil ( \theta ).

Interférences (( I(\mathbf{x}, \mathbf{f}, \mathbf{p}) )) :[I(\mathbf{x}) = \sum_{i \neq l} \frac{p_i}{d_{i,l}^\alpha}]Mesure les interférences entre antennes, où ( p_i ) est la puissance, ( d_{i,l} ) la distance, et ( \alpha ) l’exposant de perte de propagation.

Coût (( C(\mathbf{x}, \mathbf{p}) )) :[C(\mathbf{x}) = \sum_{i=1}^n c_i(\mathbf{x}_i)]Somme des coûts d’installation des antennes, variant selon leur position.

Fonction objectif :[\min_{\mathbf{x}, \mathbf{f}, \mathbf{p}} \quad -w_1 \cdot U(\mathbf{x}, \mathbf{f}, \mathbf{p}) + w_2 \cdot I(\mathbf{x}, \mathbf{f}, \mathbf{p}) + w_3 \cdot C(\mathbf{x}, \mathbf{p})]Où ( w_1, w_2, w_3 ) sont des poids pour équilibrer les objectifs.

Contraintes :

Budget : ( \sum c_i + c'(p_i) \leq B ).
Géographiques : Positions ( (x_i, y_i) \in \Omega ).
Techniques : Fréquences ( f_i \in F ), puissances ( p_i^{\min} \leq p_i \leq p_i^{\max} ).



Méthodologie
Algorithmes d’Optimisation
Trois approches sont utilisées pour résoudre le problème :

MADS (Mesh Adaptive Direct Search) :

Optimise les positions continues des antennes (( x_i, y_i )).
Utilise une fonction de pénalité pour respecter les contraintes de budget et de zones autorisées :[\Phi(\mathbf{x}) = f(\mathbf{x}) + \lambda \max \left( \left( \sum_{i=1}^n c_i(\mathbf{x}i) - B \right), 0 \right) + \mu \sum{i=1}^n \mathbf{1}_{{\mathbf{x}_i \notin \Omega}}]
Exemple : À Kédougou, ajuste les positions de (3,3), (7,7) à (4,3), (6,7), augmentant la couverture de 60 % à 85 %.


Recherche Tabou :

Optimise les variables discrètes (fréquences ( f_i ), puissances ( p_i )) pour minimiser les interférences.
Explore les voisins d’une configuration (par exemple, changer ( f_i ) de ( f_1 ) à ( f_2 )) tout en évitant les cycles via une liste tabou.
Exemple : À Kédougou, ajuste les fréquences de ( (f_1, f_1, f_1) ) à ( (f_1, f_2, f_3) ), augmentant le SIR de 5 dB à 15 dB.


Approche Hybride :

Combine MADS (positions) et Recherche Tabou (fréquences, puissances) pour une optimisation globale.
Exemple : Atteint une couverture de 85 %, un coût de 4M FCFA, et un SIR de 12 dB.



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
