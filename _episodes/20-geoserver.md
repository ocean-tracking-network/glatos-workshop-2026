---
title: "Accessing OTN GeoServer Data"
teaching: 15
exercises: 15
questions:
- "What is GeoServer and what does it serve?"
- "How do I download OTN layers like stations or receivers?"
- "How can I bring these layers into R or Python for mapping?"
objectives:
- "Know what kinds of spatial layers OTN publishes via GeoServer."
- "Construct a WFS `GetFeature` request for a specific layer."
- "Load GeoServer data directly into R or Python for analysis and mapping."
keypoints:
- "GeoServer shares OTN’s spatial data via open standards (WFS/WMS)."  
- "WFS requests are just URLs: specify the layer, format, and optional filters."  
- "You can load these URLs directly into R or Python for analysis."  
- "Keep requests efficient with filters, bounding boxes, and paging."  
- "For mapping, `folium` (Python) or `leaflet` (R) can turn data into interactive maps."
---

## What is GeoServer?

GeoServer is an **open-source server** that follows international OGC (Open Geospatial Consortium) standards to share spatial data:

- **WFS (Web Feature Service):** vector features (points, lines, polygons)  
- **WMS (Web Map Service):** map images (good for viewing, not analysis)  
- **WCS (Web Coverage Service):** raster data (e.g. grids, surfaces)

**How OTN uses it**  
OTN publishes **infrastructure layers** through GeoServer — things like:

- station and receiver deployments  
- mooring sites  
- project footprints  

These layers let researchers:

- plot receiver locations on maps  
- filter detections by space  
- combine OTN infrastructure with their own GIS workflows  

In short: GeoServer is OTN’s **map server**.  
For reproducible analysis we’ll focus on **WFS**, since it delivers data in tabular or spatial formats that R and Python can read directly.

## Anatomy of a WFS GetFeature request

A WFS request is just a URL with parts you can mix and match:

```text
https://members.oceantrack.org/geoserver/otn/ows?
service=WFS&
version=1.0.0&
request=GetFeature&
typeName=otn:stations_receivers&
outputFormat=csv
````
### What each part means

**Base endpoint**  
: `https://members.oceantrack.org/geoserver/otn/ows?`

**service=WFS**  
: `specifies the service type (Web Feature Service)`

**version=1.0.0**  
: `version of the WFS standard to use`

**request=GetFeature**  
: `the action to perform: fetch vector features`

**typeName=otn:stations_receivers**  
: `the layer to request`

**outputFormat=csv**  
: `format for the results (CSV, GeoJSON, Shapefile/ZIP)`

### Optional filters

```text
&bbox=-70,40,-40,60,EPSG:4326
```

> Restrict features to a geographic bounding box (minLon, minLat, maxLon, maxLat, CRS)

```text
&cql_filter=collectioncode='MAST'
```

> Filter features by attribute values (here, only rows where `collectioncode = MAST`)

------------------------------------------------------------------------

<p align="center">
  <img src="../fig/geoserver_layers.png" alt="OTN GeoServer catalog with otn:stations_receivers highlighted" width="80%">
</p>

The screenshot above shows the **GeoServer catalog** at [geoserver.oceantrack.org](http://geoserver.oceantrack.org/).  
From this interface you can:

- Browse layers such as stations, receivers, animals, and project footprints  
- Download data directly (CSV, GeoJSON, Shapefile, etc.)  

Note: by default, downloads are limited to **50 features**. To retrieve larger datasets you must adjust the request (e.g. add `&maxFeatures=50000`).  

For reproducible workflows, it is better to build a **WFS request URL** and load the data programmatically in R or Python (examples below).

------------------------------------------------------------------------

# Accessing OTN GeoServer Data

## Example: Receivers Layer in R

Before we can use spatial layers in analysis, we first need to **build the WFS request** and then **read the results into R**. Here’s how:

```r
# If needed, first install:
# install.packages("readr")

library(readr)

# 1) Define WFS URL (CSV output)
# This is the "request URL" that tells GeoServer what we want.
# Here: the `otn:stations_receivers` layer in CSV format.
wfs_csv <- "https://members.oceantrack.org/geoserver/otn/ows?
service=WFS&version=1.0.0&request=GetFeature&
typeName=otn:stations_receivers&outputFormat=csv"

# 2) Download directly into a data frame
# R will fetch the URL and treat the result as a CSV.
receivers <- read_csv(wfs_csv, guess_max = 50000, show_col_types = FALSE)

# 3) Preview first rows
print(head(receivers, 5))
```

## Example: Receivers Layer in Python

The same workflow works in Python: **construct the URL, download it, read into a DataFrame.**

```python
# If needed, first install:
# pip install pandas

import pandas as pd

# 1) Define WFS URL (CSV output)
# Same request as above, but written in Python.
wfs_csv = (
    "https://members.oceantrack.org/geoserver/otn/ows?"
    "service=WFS&version=1.0.0&request=GetFeature&"
    "typeName=otn:stations_receivers&outputFormat=csv"
)

# 2) Read CSV into DataFrame
receivers = pd.read_csv(wfs_csv)

# 3) Preview first rows
print(receivers.head())
```
## Follow Along: Mapping OTN Data in Python

Now let’s go one step further: **visualizing animal detections and station deployments on an interactive map.** We’ll use `folium` to create a Leaflet web map.

### 1. Imports & Setup

Here we load the libraries and prepare some helpers.

* `pandas` → tables
* `requests` → download data
* `folium` → mapping

```python
# If needed, first install:
# pip install pandas folium requests
import pandas as pd
import requests
from io import StringIO
import folium
from folium.plugins import MarkerCluster, HeatMap
```

---

### 2. Define Region & Layers

Every request can be **limited by a bounding box** (min/max longitude/latitude).
We also specify which layers we want (animals, stations) and a maximum number of features.

```python
lon_lo, lat_lo, lon_hi, lat_hi = -70.0, 40.0, -40.0, 60.0
srs = "EPSG:4326"

animals_layer  = "otn:animals"
stations_layer = "otn:stations"
max_features_animals  = 200_000
max_features_stations = 50_000
```

---

### 3. Build WFS Requests

The base WFS endpoint stays the same, we just plug in:

* `typeName=` for the layer
* `outputFormat=` for the format (CSV)
* `bbox=` for geographic limits

```python
BASE = "https://members.oceantrack.org/geoserver/otn/ows"

animals_url = (
    f"{BASE}?service=WFS&version=1.0.0&request=GetFeature"
    f"&typeName={animals_layer}&outputFormat=csv&maxFeatures={max_features_animals}"
    f"&bbox={lon_lo},{lat_lo},{lon_hi},{lat_hi},{srs}"
)

stations_url = (
    f"{BASE}?service=WFS&version=1.0.0&request=GetFeature"
    f"&typeName={stations_layer}&outputFormat=csv&maxFeatures={max_features_stations}"
    f"&bbox={lon_lo},{lat_lo},{lon_hi},{lat_hi},{srs}"
)

print("Animals URL:\n", animals_url)
print("\nStations URL:\n", stations_url)
```

---

### 4. Download CSV Data

We send the request, grab the CSV text, and load it into pandas.
Lowercasing the column names makes later handling easier.

```python
animals_csv  = requests.get(animals_url, timeout=180).text
stations_csv = requests.get(stations_url, timeout=180).text

animals  = pd.read_csv(StringIO(animals_csv)).rename(columns=str.lower)
stations = pd.read_csv(StringIO(stations_csv)).rename(columns=str.lower)

print("animals shape:", animals.shape)
print("stations shape:", stations.shape)

animals.head(3)
```

---

### 5. Clean Up Data

Geospatial data often needs cleanup.
Here we:

* Convert date strings to datetime
* Remove rows without coordinates

```python
if "datecollected" in animals.columns:
    animals["datecollected"] = pd.to_datetime(animals["datecollected"], errors="coerce")

animals = animals.dropna(subset=["latitude","longitude"]).copy()
stations = stations.dropna(subset=["latitude","longitude"]).copy()

print("after cleanup:", animals.shape, stations.shape)
```

---

### 6. Create Interactive Map

Finally, we build a Leaflet map:

* **Animal detections** as clustered markers + heatmap
* **Stations** as circle markers
* A **layer switcher** so you can toggle overlays

```python
# Center map
if len(animals):
    center = [animals["latitude"].median(), animals["longitude"].median()]
else:
    center = [(lat_lo + lat_hi)/2, (lon_lo + lon_hi)/2]

m = folium.Map(location=center, zoom_start=5, tiles="OpenStreetMap")

# ---- Animals markers ----
mc = MarkerCluster(name="Detections").add_to(m)
sample = animals.sample(min(3000, len(animals)), random_state=42) if len(animals) else animals

vern = "vernacularname" if "vernacularname" in animals.columns else None
sci  = "scientificname"  if "scientificname"  in animals.columns else None
date = "datecollected"   if "datecollected"   in animals.columns else None

for _, r in sample.iterrows():
    sp = (vern and r.get(vern)) or (sci and r.get(sci)) or "Unknown"
    when = (pd.to_datetime(r.get(date)).strftime("%Y-%m-%d %H:%M") if date and pd.notna(r.get(date)) else "")
    popup = f"<b>{sp}</b>" + (f"<br>{when}" if when else "")
    folium.Marker([r["latitude"], r["longitude"]], popup=popup).add_to(mc)

# ---- Heatmap ----
if len(animals):
    HeatMap(animals[["latitude","longitude"]].values.tolist(),
            name="Density heatmap", radius=15, blur=20, min_opacity=0.2).add_to(m)

# ---- Stations ----
fg = folium.FeatureGroup(name="Stations").add_to(m)
name_col = "station_name" if "station_name" in stations.columns else None

for _, r in stations.iterrows():
    tip = r.get(name_col) if name_col and pd.notna(r.get(name_col)) else "(station)"
    folium.CircleMarker([r["latitude"], r["longitude"]], radius=4, tooltip=tip).add_to(fg)

folium.LayerControl().add_to(m)

m.save("ocean_map.html")
print("Saved → ocean_map.html")
```

## Outputs

<div style="display: flex; justify-content: center; gap: 20px;">
  <div style="text-align: center;">
    <img src="../fig/map_detections.png"
         alt="Animal detections as clustered markers"
         width="100%">
    <p><em>Figure 1. Animal detections only.</em></p>
  </div>
  <div style="text-align: center;">
    <img src="../fig/map_detections_density.png"
         alt="Detections with density heatmap"
         width="100%">
    <p><em>Figure 2. Detections with density heatmap.</em></p>
  </div>
</div>

<p align="center">
  <img src="../fig/map_detections_density_stations.png"
       alt="Detections, density heatmap, and stations combined"
       width="70%">
  <br>
  <em>Figure 3. All layers combined: detections, density heatmap, and stations.</em>
</p>

## Advanced WFS Request Tips

WFS requests can do more than just `typeName` + `outputFormat`.  
Here are a few useful extras:

- **Limit columns** → `&propertyName=station_name,latitude,longitude`
- **Filter by attributes** → `&cql_filter=collectioncode='MAST'`
- **Filter by space** → `&bbox=-70,40,-60,50,EPSG:4326`
- **Sort results** → `&sortBy=datecollected D` (D = descending)
- **Reproject on the fly** → `&srsName=EPSG:3857`
- **Page through large results** → `&count=5000&startIndex=0`

### Things to avoid
- Requesting *everything at once* (can be very slow).  
  → Always add a `bbox`, `cql_filter`, or `count`.  
- Huge Shapefile downloads (`outputFormat=SHAPE-ZIP`) for big datasets.  
  → Use CSV or GeoJSON instead.  
- Ignoring CRS in `bbox`.  
  → Always include the EPSG code at the end.

These options make requests faster, lighter, and more reproducible.

---

### Exercise

* Try swapping in a different `typeName=` layer
* Limit results with `bbox=` to a smaller area
* Switch `outputFormat=application/json` and load with `sf::st_read()` (R) or `geopandas.read_file()` (Python)

---