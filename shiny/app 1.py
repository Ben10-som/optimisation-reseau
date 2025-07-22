import streamlit as st
import pandas as pd
import numpy as np
from folium import Map, CircleMarker, Marker
import streamlit_folium as st_folium
import plotly.express as px
import plotly.graph_objects as go
from math import sqrt

# ===============================
# DONNÉES SIMULÉES DU SÉNÉGAL
# ===============================

# Régions du Sénégal avec coordonnées approximatives
regions_senegal = pd.DataFrame({
    'region': ['Dakar', 'Thiès', 'Diourbel', 'Fatick', 'Kaolack', 'Kaffrine',
               'Louga', 'Saint-Louis', 'Matam', 'Tambacounda', 'Kédougou',
               'Kolda', 'Sédhiou', 'Ziguinchor'],
    'lat': [14.7167, 14.7886, 14.6544, 14.3344, 14.1372, 14.1069,
            15.6181, 16.0469, 15.6550, 13.7706, 12.5569,
            12.8939, 12.7089, 12.5681],
    'lon': [-17.4677, -16.9363, -16.2294, -16.1764, -16.0728, -15.5503,
            -15.6509, -16.4896, -13.2558, -13.6681, -12.1786,
            -14.9444, -15.5564, -16.2681],
    'population': [3732000, 2016000, 1498000, 714000, 960000, 566000,
                   896000, 908000, 563000, 681000, 197000,
                   447000, 452000, 549000]
})

# Données de couverture réseau par région (simulées)
couverture_reseau = pd.DataFrame({
    'region': regions_senegal['region'].repeat(3),
    'technologie': ['2G']*14 + ['3G']*14 + ['4G']*14,
    'couverture_pct': [
        # 2G
        95, 92, 88, 85, 87, 82, 80, 85, 65, 70, 60, 75, 72, 78,
        # 3G
        85, 80, 75, 70, 72, 68, 65, 70, 45, 50, 40, 55, 52, 58,
        # 4G
        75, 70, 60, 55, 58, 50, 45, 55, 25, 30, 20, 35, 32, 38
    ]
})

# Antennes existantes (données simulées)
np.random.seed(123)
antennes_existantes = pd.DataFrame({
    'id': range(1, 151),
    'region': np.random.choice(regions_senegal['region'], size=150, replace=True,
                              p=regions_senegal['population'] / regions_senegal['population'].sum()),
    'lat': np.random.uniform(12, 16.5, 150),
    'lon': np.random.uniform(-17.5, -11.5, 150),
    'type': np.random.choice(['2G', '3G', '4G'], 150, replace=True),
    'puissance': np.random.uniform(10, 100, 150),
    'frequence': np.random.choice([900, 1800, 2100, 2600], 150, replace=True),
    'cout': np.random.uniform(50000, 200000, 150),
    'operateur': np.random.choice(['Orange', 'Free', 'Expresso'], 150, replace=True)
})

# ===============================
# FONCTIONS D'OPTIMISATION
# ===============================

def calculer_puissance_recue(puissance_emise, distance, frequence, alpha=2.5):
    if distance == 0:
        return puissance_emise
    return puissance_emise / (distance**alpha * (frequence/1000)**2)

def calculer_sir(signal, interferences):
    if len(interferences) == 0 or sum(interferences) == 0:
        return float('inf')
    return signal / sum(interferences)

def optimiser_placement_mads(n_antennes, budget, zone_lat, zone_lon):
    positions = pd.DataFrame({
        'lat': np.random.uniform(zone_lat[0], zone_lat[1], n_antennes),
        'lon': np.random.uniform(zone_lon[0], zone_lon[1], n_antennes),
        'puissance': np.random.uniform(20, 80, n_antennes),
        'frequence': np.random.choice([900, 1800, 2100], n_antennes, replace=True)
    })
    cout_total = sum(positions['puissance'] * 1000 + np.random.uniform(30000, 60000, n_antennes))
    couverture_pct = min(95, 40 + n_antennes * 2)
    return {
        'positions': positions,
        'cout_total': cout_total,
        'couverture': couverture_pct,
        'sir_moyen': np.random.uniform(10, 25)
    }

def optimiser_frequences_tabou(positions, iterations=50):
    n = len(positions)
    frequences_disponibles = [900, 1800, 2100, 2600]
    positions = positions.copy()
    
    for _ in range(iterations):
        antenne_idx = np.random.randint(0, n)
        positions.at[antenne_idx, 'frequence'] = np.random.choice(frequences_disponibles)
    
    return positions

# ===============================
# INTERFACE UTILISATEUR STREAMLIT
# ===============================

st.set_page_config(page_title="Optimisation des Antennes - Sénégal", layout="wide")

# Sidebar navigation
st.sidebar.title("Navigation")
page = st.sidebar.radio("Aller à", [
    "Tableau de Bord",
    "Répartition Réseau",
    "Antennes Existantes",
    "Optimisation",
    "Résultats"
])

# Initialize session state for optimization results
if 'resultats_optimisation' not in st.session_state:
    st.session_state.resultats_optimisation = None

# ===============================
# TABLEAU DE BORD
# ===============================

if page == "Tableau de Bord":
    st.title("Tableau de Bord")
    
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Antennes Installées", len(antennes_existantes), delta=None)
    with col2:
        st.metric("Régions Couvertes", len(antennes_existantes['region'].unique()), delta=None)
    with col3:
        moy_4g = couverture_reseau[couverture_reseau['technologie'] == '4G']['couverture_pct'].mean()
        st.metric("Couverture 4G Moyenne", f"{round(moy_4g, 1)}%", delta=None)
    
    col1, col2 = st.columns([2, 1])
    with col1:
        st.subheader("Carte des Régions du Sénégal")
        m = Map(location=[14.5, -14.5], zoom_start=6)
        for _, row in regions_senegal.iterrows():
            CircleMarker(
                location=[row['lat'], row['lon']],
                radius=sqrt(row['population']/100000),
                popup=f"<b>{row['region']}</b><br>Population: {row['population']:,.0f}",
                color='red',
                fill_opacity=0.7
            ).add_to(m)
        st_folium.st_folium(m, height=450, width=800)
    
    with col2:
        st.subheader("Statistiques par Région")
        antennes_par_region = antennes_existantes.groupby('region').agg(
            nb_antennes=('id', 'count'),
            nb_2G=('type', lambda x: sum(x == '2G')),
            nb_3G=('type', lambda x: sum(x == '3G')),
            nb_4G=('type', lambda x: sum(x == '4G'))
        ).reset_index().sort_values('nb_antennes', ascending=False)
        st.dataframe(antennes_par_region, use_container_width=True)

# ===============================
# RÉPARTITION RÉSEAU
# ===============================

elif page == "Répartition Réseau":
    st.title("Répartition Réseau")
    
    col1, col2 = st.columns([1, 3])
    with col1:
        st.subheader("Contrôles")
        techno_select = st.selectbox("Technologie:", ["Toutes", "2G", "3G", "4G"])
        region_filter = st.selectbox("Région:", ["Toutes"] + list(regions_senegal['region']))
    
    with col2:
        st.subheader("Couverture Réseau par Technologie")
        data_filtered = couverture_reseau.copy()
        if techno_select != "Toutes":
            data_filtered = data_filtered[data_filtered['technologie'] == techno_select]
        if region_filter != "Toutes":
            data_filtered = data_filtered[data_filtered['region'] == region_filter]
        
        fig = px.bar(data_filtered, x='region', y='couverture_pct', color='technologie',
                     barmode='group', title="Couverture Réseau par Région et Technologie",
                     labels={'region': 'Région', 'couverture_pct': 'Couverture (%)'})
        fig.update_layout(xaxis_tickangle=45)
        st.plotly_chart(fig, use_container_width=True)
    
    col1, col2 = st.columns(2)
    with col1:
        st.subheader("Répartition 2G/3G/4G")
        totaux = couverture_reseau.groupby('technologie')['couverture_pct'].mean().reset_index()
        fig = px.bar(totaux, x='technologie', y='couverture_pct',
                     title="Couverture Moyenne par Technologie",
                     color='technologie', color_discrete_sequence=['lightblue', 'lightgreen', 'orange'])
        st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("Évolution par Région")
        regions_top = couverture_reseau[couverture_reseau['technologie'] == '4G']\
            .sort_values('couverture_pct', ascending=False).head(6)
        fig = px.line(regions_top, x='region', y='couverture_pct',
                      title="Top 6 Régions - Couverture 4G",
                      markers=True)
        st.plotly_chart(fig, use_container_width=True)

# ===============================
# ANTENNES EXISTANTES
# ===============================

elif page == "Antennes Existantes":
    st.title("Antennes Existantes")
    
    col1, col2 = st.columns([2, 1])
    with col1:
        st.subheader("Localisation des Antennes")
        data = antennes_existantes.copy()
        operateur_filter = st.session_state.get('operateur_filter', 'Tous')
        type_antenne = st.session_state.get('type_antenne', 'Tous')
        
        if operateur_filter != "Tous":
            data = data[data['operateur'] == operateur_filter]
        if type_antenne != "Tous":
            data = data[data['type'] == type_antenne]
        
        m = Map(location=[14.5, -14.5], zoom_start=6)
        couleurs = {'2G': 'red', '3G': 'green', '4G': 'blue'}
        for _, row in data.iterrows():
            CircleMarker(
                location=[row['lat'], row['lon']],
                radius=sqrt(row['puissance'])/3,
                color=couleurs[row['type']],
                fill_opacity=0.7,
                popup=f"<b>Antenne {row['id']}</b><br>Type: {row['type']}<br>Opérateur: {row['operateur']}<br>Puissance: {row['puissance']:.1f} W<br>Fréquence: {row['frequence']} MHz"
            ).add_to(m)
        st_folium.st_folium(m, height=500, width=800)
    
    with col2:
        st.subheader("Filtres")
        st.session_state.operateur_filter = st.selectbox("Opérateur:", ["Tous", "Orange", "Free", "Expresso"], key='operateur_filter')
        st.session_state.type_antenne = st.selectbox("Type d'antenne:", ["Tous", "2G", "3G", "4G"], key='type_antenne')
        
        st.subheader("Statistiques")
        stats = f"""Nombre total: {len(data)}
Puissance moyenne: {data['puissance'].mean():.1f} W
Coût moyen: {data['cout'].mean():,.0f} FCFA
Fréquences utilisées: {len(data['frequence'].unique())}"""
        st.text(stats)
    
    st.subheader("Liste des Antennes")
    table_data = data[['id', 'region', 'type', 'operateur', 'puissance', 'frequence', 'cout']].copy()
    table_data['puissance'] = table_data['puissance'].round(1)
    table_data['cout'] = table_data['cout'].apply(lambda x: f"{x:,.0f}")
    st.dataframe(table_data, use_container_width=True)

# ===============================
# OPTIMISATION
# ===============================

elif page == "Optimisation":
    st.title("Optimisation")
    
    col1, col2 = st.columns([1, 2])
    with col1:
        st.subheader("Paramètres d'Optimisation")
        st.markdown("### Zone d'étude")
        region_optim = st.selectbox("Région cible:", regions_senegal['region'], index=regions_senegal.index[regions_senegal['region'] == 'Tambacounda'][0])
        
        st.markdown("### Contraintes")
        nb_antennes = st.number_input("Nombre d'antennes à placer:", min_value=1, max_value=50, value=10)
        budget_total = st.number_input("Budget total (FCFA):", min_value=100_000_000, max_value=2_000_000_000, value=500_000_000, step=50_000_000)
        
        st.markdown("### Paramètres techniques")
        seuil_sir = st.slider("Seuil SIR minimum (dB):", min_value=5, max_value=25, value=15)
        methode_optim = st.selectbox("Méthode d'optimisation:", ["MADS", "Recherche Tabou", "Hybride"], index=2)
        
        if st.button("Lancer l'Optimisation", use_container_width=True):
            region_info = regions_senegal[regions_senegal['region'] == region_optim]
            log = f"""=== OPTIMISATION EN COURS ===
Région cible: {region_optim}
Méthode: {methode_optim}
Nombre d'antennes: {nb_antennes}
Budget: {budget_total:,.0f} FCFA

Étape 1: Initialisation du modèle...
Étape 2: Calcul des positions optimales...
Étape 3: Optimisation des fréquences...
Étape 4: Validation des contraintes...

OPTIMISATION TERMINÉE !"""
            st.session_state.log_optimisation = log
            
            zone_lat = [region_info['lat'].iloc[0] - 0.5, region_info['lat'].iloc[0] + 0.5]
            zone_lon = [region_info['lon'].iloc[0] - 0.5, region_info['lon'].iloc[0] + 0.5]
            
            resultats = optimiser_placement_mads(nb_antennes, budget_total, zone_lat, zone_lon)
            if methode_optim in ["Recherche Tabou", "Hybride"]:
                resultats['positions'] = optimiser_frequences_tabou(resultats['positions'])
            
            st.session_state.resultats_optimisation = resultats
    
    with col2:
        st.subheader("Progression")
        if 'log_optimisation' in st.session_state:
            st.text(st.session_state.log_optimisation)
        
        st.markdown("### Aperçu de la zone")
        region_info = regions_senegal[regions_senegal['region'] == region_optim]
        m = Map(location=[region_info['lat'].iloc[0], region_info['lon'].iloc[0]], zoom_start=8)
        Marker(
            location=[region_info['lat'].iloc[0], region_info['lon'].iloc[0]],
            popup=f"Zone d'optimisation: {region_optim}"
        ).add_to(m)
        st_folium.st_folium(m, height=300, width=800)

# ===============================
# RÉSULTATS
# ===============================

elif page == "Résultats":
    st.title("Résultats")
    
    res = st.session_state.resultats_optimisation
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Coût Total (FCFA)", "N/A" if res is None else f"{res['cout_total']:,.0f}", delta=None)
    with col2:
        st.metric("Couverture Obtenue", "N/A" if res is None else f"{res['couverture']:.1f}%", delta=None)
    with col3:
        st.metric("SIR Moyen", "N/A" if res is None else f"{res['sir_moyen']:.1f} dB", delta=None)
    
    col1, col2 = st.columns([2, 1])
    with col1:
        st.subheader("Placement Optimisé")
        if res is None:
            m = Map(location=[14.5, -14.5], zoom_start=6)
            st_folium.st_folium(m, height=500, width=800)
        else:
            m = Map(location=[res['positions']['lon'].mean(), res['positions']['lat'].mean()], zoom_start=9)
            couleurs_freq = {'900': 'red', '1800': 'green', '2100': 'blue', '2600': 'purple'}
            for _, row in res['positions'].iterrows():
                CircleMarker(
                    location=[row['lat'], row['lon']],
                    radius=sqrt(row['puissance'])/2,
                    color=couleurs_freq[str(int(row['frequence']))],
                    fill_opacity=0.8,
                    popup=f"<b>Antenne Optimisée</b><br>Fréquence: {row['frequence']} MHz<br>Puissance: {row['puissance']:.1f} W"
                ).add_to(m)
            st_folium.st_folium(m, height=500, width=800)
    
    with col2:
        st.subheader("Analyse des Résultats")
        if res is None:
            st.text("Aucune optimisation lancée")
        else:
            analyse = f"""Performances obtenues:

• Couverture: {res['couverture']:.1f}%
• SIR moyen: {res['sir_moyen']:.1f} dB
• Coût total: {res['cout_total']:,.0f} FCFA
• Coût par antenne: {res['cout_total']/len(res['positions']):,.0f} FCFA

Analyse:
✓ Excellente couverture if {res['couverture'] > 80} else ⚠ Couverture à améliorer
✓ Bonne qualité signal if {res['sir_moyen'] > 15} else ⚠ Signal faible"""
            st.text(analyse)
        
        st.markdown("### Répartition des Fréquences")
        if res is None:
            st.plotly_chart(go.Figure().update_layout(title="Aucune donnée"), use_container_width=True)
        else:
            freq_count = res['positions']['frequence'].value_counts().reset_index()
            freq_count.columns = ['frequence', 'count']
            fig = px.bar(freq_count, x='frequence', y='count',
                         title="Répartition des Fréquences",
                         labels={'frequence': 'Fréquence (MHz)', 'count': "Nombre d'antennes"})
            st.plotly_chart(fig, use_container_width=True)
    
    st.subheader("Antennes Optimisées")
    if res is None:
        st.dataframe(pd.DataFrame(), use_container_width=True)
    else:
        data = res['positions'].copy()
        data['id'] = range(1, len(data) + 1)
        data['lat'] = data['lat'].round(4)
        data['lon'] = data['lon'].round(4)
        data['puissance'] = data['puissance'].round(1)
        data['cout_estime'] = (data['puissance'] * 1000 + np.random.uniform(30000, 60000, len(data))).round(0)
        data = data[['id', 'lat', 'lon', 'frequence', 'puissance', 'cout_estime']]
        st.dataframe(data, use_container_width=True)
