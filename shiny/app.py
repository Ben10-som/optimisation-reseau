
import streamlit as st
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import io

# Paramètres
GRID_SIZE = 100  # Taille de la grille
N_ANTENNAS = 10  # Nombre d'antennes
N_CHANNELS = 5   # Nombre de canaux
ALPHA = 3.0      # Exposant de perte (terrain accidenté)
FREQ = 900e6     # Fréquence (900 MHz)
K = 1e-4         # Constante de propagation
N0 = 1e-12       # Bruit thermique
THRESHOLD = -90  # Seuil SIR (dB)
MAX_ITER = 50    # Nombre maximum d'itérations

# Générer une grille de densité (centrée)
def generate_density_grid():
    grid = np.zeros((GRID_SIZE, GRID_SIZE))
    center_x, center_y = GRID_SIZE // 2, GRID_SIZE // 2
    sigma = GRID_SIZE / 6
    for i in range(GRID_SIZE):
        for j in range(GRID_SIZE):
            grid[i, j] = 1000 * np.exp(-((i - center_x)**2 + (j - center_y)**2) / (2 * sigma**2))
    return grid

# Charger une grille depuis un fichier CSV
def load_density_grid(file):
    try:
        data = pd.read_csv(file)
        if not {'x', 'y', 'density'}.issubset(data.columns):
            st.error("Le fichier CSV doit contenir les colonnes 'x', 'y', 'density'.")
            return None
        grid = np.zeros((GRID_SIZE, GRID_SIZE))
        for _, row in data.iterrows():
            x, y = int(row['x']), int(row['y'])
            if 0 <= x < GRID_SIZE and 0 <= y < GRID_SIZE:
                grid[x, y] = row['density']
        return grid
    except Exception as e:
        st.error(f"Erreur lors du chargement du fichier : {e}")
        return None

# Calculer le SIR
def compute_sir(antennas, channels):
    sir_grid = np.zeros((GRID_SIZE, GRID_SIZE))
    for i in range(GRID_SIZE):
        for j in range(GRID_SIZE):
            signal = 0
            interference = 0
            for idx, (x, y, ch) in enumerate(antennas):
                d = np.sqrt((i - x)**2 + (j - y)**2) + 1e-6
                power = K / (d**ALPHA * FREQ**2)
                if ch == channels[0]:
                    signal += power
                else:
                    interference += power
            sir_grid[i, j] = 10 * np.log10(signal / (interference + N0))
    return sir_grid

# Calculer la couverture et les métriques
def compute_coverage(sir_grid, density_grid, antennas):
    coverage = sir_grid >= THRESHOLD
    ne = np.sum(density_grid * (1 - coverage))
    users_per_antenna = np.zeros(N_ANTENNAS)
    for i in range(GRID_SIZE):
        for j in range(GRID_SIZE):
            if coverage[i, j]:
                closest = np.argmin([np.sqrt((i - x)**2 + (j - y)**2) for x, y, _ in antennas])
                users_per_antenna[closest] += density_grid[i, j]
    v = np.var(users_per_antenna)
    return coverage, ne, v

# Recherche tabou
def tabu_search(antennas, channels, density_grid):
    current_channels = channels.copy()
    best_channels = current_channels.copy()
    best_ne, best_v = float('inf'), float('inf')
    tabu_list = []
    for _ in range(MAX_ITER // 2):
        neighbors = []
        for i in range(N_ANTENNAS):
            for ch in range(N_CHANNELS):
                if ch != current_channels[i]:
                    neighbor = current_channels.copy()
                    neighbor[i] = ch
                    antennas_temp = [(x, y, ch) for (x, y, _), ch in zip(antennas, neighbor)]
                    sir_grid = compute_sir(antennas_temp, neighbor)
                    _, ne, v = compute_coverage(sir_grid, density_grid, antennas_temp)
                    neighbors.append((neighbor, ne, v))
        neighbors = [n for n in neighbors if tuple(n[0]) not in tabu_list]
        if not neighbors:
            break
        best_neighbor = min(neighbors, key=lambda x: x[1])
        current_channels = best_neighbor[0]
        tabu_list.append(tuple(current_channels))
        if len(tabu_list) > 10:
            tabu_list.pop(0)
        if best_neighbor[1] < best_ne:
            best_ne = best_neighbor[1]
            best_v = best_neighbor[2]
            best_channels = best_neighbor[0]
    return best_channels, best_ne, best_v

# MADS simplifié
def mads(antennas, channels, density_grid):
    current_antennas = antennas.copy()
    best_antennas = current_antennas.copy()
    best_ne, best_v = float('inf'), float('inf')
    delta = 10.0
    for _ in range(MAX_ITER // 2):
        neighbors = []
        for i in range(N_ANTENNAS):
            x, y, ch = current_antennas[i]
            for dx, dy in [(delta, 0), (-delta, 0), (0, delta), (0, -delta)]:
                x_new, y_new = x + dx, y + dy
                if 0 <= x_new < GRID_SIZE and 0 <= y_new < GRID_SIZE:
                    neighbor = current_antennas.copy()
                    neighbor[i] = (x_new, y_new, ch)
                    sir_grid = compute_sir(neighbor, channels)
                    _, ne, v = compute_coverage(sir_grid, density_grid, neighbor)
                    neighbors.append((neighbor, ne, v))
        if neighbors:
            best_neighbor = min(neighbors, key=lambda x: x[1])
            if best_neighbor[1] < best_ne:
                best_ne = best_neighbor[1]
                best_v = best_neighbor[2]
                best_antennas = best_neighbor[0]
                delta *= 1.2
            else:
                delta /= 2
            current_antennas = best_neighbor[0]
        if delta < 0.1:
            break
    return best_antennas, best_ne, best_v

# Optimisation générale
def optimize(density_grid):
    antennas = [(np.random.uniform(0, GRID_SIZE), np.random.uniform(0, GRID_SIZE), np.random.randint(0, N_CHANNELS)) for _ in range(N_ANTENNAS)]
    channels = [a[2] for a in antennas]
    ne_history, v_history = [], []
    
    # Initialisation
    sir_grid = compute_sir(antennas, channels)
    coverage, ne, v = compute_coverage(sir_grid, density_grid, antennas)
    ne_history.append(ne)
    v_history.append(v)
    
    # Recherche tabou
    channels, ne, v = tabu_search(antennas, channels, density_grid)
    antennas = [(x, y, ch) for (x, y, _), ch in zip(antennas, channels)]
    ne_history.append(ne)
    v_history.append(v)
    
    # MADS
    antennas, ne, v = mads(antennas, channels, density_grid)
    ne_history.append(ne)
    v_history.append(v)
    
    # Final
    sir_grid = compute_sir(antennas, channels)
    coverage, ne, v = compute_coverage(sir_grid, density_grid, antennas)
    ne_history.append(ne)
    v_history.append(v)
    
    return coverage, antennas, ne_history, v_history

# Visualiser les résultats
def plot_results(coverage, antennas, ne_history, v_history):
    # Carte de service
    fig1, ax1 = plt.subplots(figsize=(8, 8))
    ax1.imshow(coverage, cmap='Greys', origin='lower')
    for idx, (x, y, ch) in enumerate(antennas):
        ax1.scatter(x, y, c='red', s=100, label=f'Antenne {idx} (Canal {ch})' if idx == 0 else "")
        ax1.text(x + 2, y, f'A{idx} (C{ch})', fontsize=8, color='black')
    ax1.set_title("Carte de service - Kédougou")
    ax1.legend()
    
    # Profil d'évolution
    fig2, ax2 = plt.subplots(figsize=(8, 4))
    iterations = list(range(len(ne_history)))
    ax2.plot(iterations, ne_history, 'b-', label='Usagers non couverts (N_e)')
    ax2.plot(iterations, v_history, 'r-', label='Variance (V)')
    ax2.set_xlabel('Itérations')
    ax2.set_ylabel('Valeur')
    ax2.set_title("Profil d'évolution - Kédougou")
    ax2.legend()
    
    return fig1, fig2

# Interface Streamlit
st.title("Optimisation du Placement des Antennes - Kédougou")
st.write("Chargez une carte de densité ou utilisez la densité par défaut (centrée). Cliquez sur 'Optimiser' pour lancer l'algorithme.")

# Chargement du fichier
uploaded_file = st.file_uploader("Charger un fichier CSV (x, y, density)", type="csv")

# Bouton pour charger la carte par défaut
if st.button("Charger la carte par défaut"):
    density_grid = generate_density_grid()
    st.session_state['density_grid'] = density_grid
    st.success("Carte par défaut (densité centrée) chargée avec succès.")

# Charger une carte depuis un fichier
if uploaded_file is not None:
    density_grid = load_density_grid(uploaded_file)
    if density_grid is not None:
        st.session_state['density_grid'] = density_grid
        st.success("Carte chargée depuis le fichier CSV.")

# Bouton pour lancer l'optimisation
if st.button("Optimiser"):
    if 'density_grid' not in st.session_state:
        st.error("Veuillez d'abord charger une carte.")
    else:
        density_grid = st.session_state['density_grid']
        with st.spinner("Optimisation en cours..."):
            coverage, antennas, ne_history, v_history = optimize(density_grid)
            fig1, fig2 = plot_results(coverage, antennas, ne_history, v_history)
            st.pyplot(fig1)
            st.pyplot(fig2)
            
            # Téléchargement des images
            buf1 = io.BytesIO()
            fig1.savefig(buf1, format="png")
            buf1.seek(0)
            st.download_button("Télécharger la carte de service", buf1, "kedougou_service.png")
            
            buf2 = io.BytesIO()
            fig2.savefig(buf2, format="png")
            buf2.seek(0)
            st.download_button("Télécharger le profil d'évolution", buf2, "kedougou_evolution.png")
# Fin de l'application

