# Directus Food Import

Diese Datei ergänzt die bestehende Food-Datenbasis um **130** gängige Obst-, Gemüse- und Fleischsorten in einem CSV-Format, das sich gut für einen Directus-Import eignet.

## Dateien

- `directus-food-import.csv`: erweiterte Import-Datei mit 130 Einträgen und Zusatzfeldern wie `category`, `carbsPer100g`, `fiberPer100g` und `source`.
- `directus-food-import-api-schema.csv`: reduzierte Import-Datei mit exakt den aktuellen Food-Feldern aus dem Repo-Schema, damit du in einer passenden Directus-Collection nichts mehr manuell mappen musst.

## Feldlogik

- `barcode`: künstlicher eindeutiger Schlüssel für den Import.
- `name`: Anzeigename des Lebensmittels.
- `category`: einfache Gruppierung für Directus (`Obst`, `Gemüse`, `Fleisch`).
- `brand`: Quelle der Nährwerte.
- `kcalPer100g`: Energie pro 100 g.
- `proteinPercent`: Protein in g pro 100 g; im aktuellen API-Schema entspricht das zugleich Prozent.
- `fatPercent`: Fett in g pro 100 g; im aktuellen API-Schema entspricht das zugleich Prozent.
- `carbsPer100g`: Kohlenhydrate pro 100 g.
- `fiberPer100g`: Ballaststoffe pro 100 g.
- `crudeAshPercent`: nur für Fleisch gepflegt; bei Obst/Gemüse bewusst leer gelassen.
- `crudeFiberPercent`: bewusst leer gelassen, damit du für Obst/Gemüse keine Rohfaser importierst.
- `source`: Kurzverweis auf die Datengrundlage.

## Umfang

Die CSV enthält aktuell:

- 40 Obstsorten
- 55 Gemüse-/Pilzsorten
- 35 Fleischsorten

## Quellenbasis

Die Werte sind für gängige Rohprodukte auf 100 g normalisiert und auf Basis von USDA FoodData Central zusammengestellt. Für die Auswahl der alltagstauglichen Standardwerte wurden typische Referenzwerte für rohe Lebensmittel verwendet.

## Import-Hinweis

Wenn deine Directus-Collection das aktuelle Food-Schema aus diesem Repo spiegelt, nutze direkt `directus-food-import-api-schema.csv`. Diese Datei enthält exakt die Felder `barcode`, `name`, `brand`, `kcalPer100g`, `proteinPercent`, `fatPercent`, `crudeAshPercent` und `crudeFiberPercent`. Die größere `directus-food-import.csv` bleibt sinnvoll, wenn du zusätzlich Kategorien, Kohlenhydrate, Ballaststoffe oder Quelleninformationen importieren möchtest.
