from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import pandas as pd

# Configurer Selenium (avec Chrome)
driver = webdriver.Chrome(executable_path='chemin/vers/chromedriver')
url = "https://www.nperf.com/fr/map/SN/-/-/signal?ll=20&lg=0&zoom=3"
driver.get(url)

# Attendre que la carte se charge
time.sleep(10)  # Ajustez selon votre connexion

# Extraire les données (exemple : noms des opérateurs)
operators = driver.find_elements(By.CLASS_NAME, "operator-name")  # À adapter selon l'HTML
data = []
for op in operators:
    data.append({"Operator": op.text})

# Sauvegarder en CSV
df = pd.DataFrame(data)
df.to_csv("nperf_senegal_coverage.csv", index=False)

driver.quit()