---
title: "Accessing OTN Data via OBIS"
teaching: 15
exercises: 15
questions:
- "What does OBIS hold for the Ocean Tracking Network?"
- "How do I query OTN records by node, dataset, or species?"
- "How can I bring OTN occurrence data into R or Python for mapping?"
objectives:
- "Recognize what OTN contributes to OBIS (occurrence-focused)."
- "Filter OBIS by OTN node, dataset, taxon, region, and time."
- "Load OTN records into R or Python and make a quick map."
keypoints:
- "OBIS hosts species occurrence records (not infrastructure layers)."
- "OTN is an OBIS node; UUID: 68f83ea7-69a7-44fd-be77-3c3afd6f3cf8."
- "Use robis (R) or pyobis (Python) for programmatic queries."
- "Keep queries lean with fields, geometry, time window, and paging."
---

## What is OBIS and how does OTN fit in?

- **OBIS (Ocean Biodiversity Information System)** is the global hub for **marine species occurrence** data.
- The **Ocean Tracking Network (OTN)** is one of OBIS’s **regional nodes**.  
  OTN contributes **tagging and tracking metadata** summarized as *occurrence records* (e.g., tag releases, detection events).
- To focus only on OTN-contributed data, use the **OTN node UUID**:

```

68f83ea7-69a7-44fd-be77-3c3afd6f3cf8

```
---

## Anatomy of an OBIS query (OTN-focused)

An OBIS request is just a URL with filters.  
Here’s a simple example, limited to **blue sharks** contributed by **OTN**:

```text
https://api.obis.org/v3/occurrence?
nodeid=68f83ea7-69a7-44fd-be77-3c3afd6f3cf8&
scientificname=Prionace%20glauca&
startdate=2000-01-01&
size=100
````

### What each part means

> **nodeid** — restrict to the OTN node  
> **scientificname** — filter by species (e.g., *Prionace glauca*)  
> **startdate / enddate** — filter by time window  
> **geometry** — filter by region (polygon or bounding box in WKT)  
> **datasetid** — limit to one OTN dataset  
> **size / from** — control paging through large results  
> **fields** — choose only the columns you need (faster, smaller)

## Minimal recipes: your first OBIS query

The smallest working recipe is just: **species + OTN node**.
Here’s an example pulling **blue shark (*Prionace glauca*)** records contributed by OTN.

### R (robis)

```r
# install.packages("robis")   # once
library(robis)

OTN <- "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"

blue <- occurrence("Prionace glauca", nodeid = OTN, size = 500)

head(blue)
```

### Python (pyobis)

```python
# pip install pyobis pandas   # once
from pyobis import occurrences

OTN = "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"

blue = occurrences.search(
    scientificname="Prionace glauca",
    nodeid=OTN,
    size=500
).execute()

print(blue.head())
```

## Adding filters

Just like with WFS, you can **add filters** to make queries more precise.
The most useful are:

* **Time window** (`startdate`, `enddate`)
* **Place** (`geometry=` WKT polygon or bbox in lon/lat)
* **Dataset** (`datasetid=`)
* **Fields** (`fields=` → return only the columns you need)

### R

```r
# Time filter (since 2000)
blue_time <- occurrence("Prionace glauca", nodeid = OTN, startdate = "2000-01-01")

# Place filter (box in Gulf of St. Lawrence)
wkt <- "POLYGON((-70 40, -70 50, -55 50, -55 40, -70 40))"
blue_space <- occurrence("Prionace glauca", nodeid = OTN, geometry = wkt)

# Dataset filter (replace with an actual dataset UUID)
# blue_ds <- occurrence("Prionace glauca", nodeid = OTN, datasetid = "DATASET-UUID")

# Slim down fields
blue_lean <- occurrence("Prionace glauca", nodeid = OTN,
  fields = c("scientificName","eventDate","decimalLatitude","decimalLongitude","datasetName"))
```

### Python

```python
# Time filter (since 2000)
blue_time = occurrences.search(
    scientificname="Prionace glauca", nodeid=OTN, startdate="2000-01-01"
).execute()

# Place filter (box in Gulf of St. Lawrence)
wkt = "POLYGON((-70 40, -70 50, -55 50, -55 40, -70 40))"
blue_space = occurrences.search(
    scientificname="Prionace glauca", nodeid=OTN, geometry=wkt
).execute()

# Dataset filter (replace with an actual dataset UUID)
# blue_ds = occurrences.search(
#     scientificname="Prionace glauca", nodeid=OTN, datasetid="DATASET-UUID"
# ).execute()

# Slim down fields
blue_lean = occurrences.search(
    scientificname="Prionace glauca", nodeid=OTN,
    fields="scientificName,eventDate,decimalLatitude,decimalLongitude,datasetName"
).execute()
```

**Tips**

* Always **drop NAs** in latitude/longitude before mapping.
* Dates come back as text — convert to `Date` (R) or `datetime` (Python) if you need time plots.
* For large datasets, **paginate** with `size` + `from` (Python) or repeat calls with `from` (R).


## Follow-Along: “Where are the Blue Sharks?”

We’ll walk through a full workflow:

* pull **blue shark (*Prionace glauca*)** records contributed by **OTN**,
* focus on the **NW Atlantic**,
* make an **interactive map** and a couple of **time-series views**.

> **Install once**

```bash
pip install pyobis pandas folium matplotlib
````

### 1) Imports & Setup

Load the libraries, set the OTN node UUID, species, and a bounding box (WKT polygon) for the NW Atlantic.

```python
from pyobis import occurrences, dataset
import pandas as pd
import folium
from folium.plugins import HeatMap, MarkerCluster
import matplotlib.pyplot as plt

OTN = "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"
SPECIES = "Prionace glauca"  # blue shark
WKT = "POLYGON((-80 30, -80 52, -35 52, -35 30, -80 30))"
```

### 2) Peek at OTN datasets

This shows which datasets under OTN actually contain blue shark records.

```python
ds = dataset.search(nodeid=OTN, limit=100, offset=0).execute()
pd.DataFrame(ds["results"])[["id","title"]].head(10)
```

### 3) Query OBIS for Blue Shark

We add filters: **species + node + region + time window**.

```python
df = occurrences.search(
    scientificname=SPECIES,
    nodeid=OTN,
    geometry=WKT,
    startdate="2000-01-01",
    size=5000,
    fields="id,scientificName,eventDate,decimalLatitude,decimalLongitude,datasetName"
).execute()
```

### 4) Clean the results

Drop rows without coordinates, parse event dates, and check the shape.

```python
df = df.dropna(subset=["decimalLatitude","decimalLongitude"]).copy()
df["eventDate"] = pd.to_datetime(df["eventDate"], errors="coerce")
df = df.dropna(subset=["eventDate"])
print(df.shape)
df.head()
```

### 5) Quick sanity checks

See which datasets dominate and what the date range looks like.

```python
print("Top datasets:\n", df["datasetName"].value_counts().head(10))
print("Date range:", df["eventDate"].min(), "→", df["eventDate"].max())
```

### 6) Interactive Map

Plot both individual points (sampled so the map stays fast) and a density heatmap.

```python
center = [df["decimalLatitude"].median(), df["decimalLongitude"].median()]
m = folium.Map(location=center, zoom_start=4, tiles="OpenStreetMap")

# Markers
sample = df.sample(min(len(df), 2000), random_state=42)
mc = MarkerCluster(name="Blue shark points").add_to(m)
for _, r in sample.iterrows():
    tip = f"{r['scientificName']} • {str(r['eventDate'])[:10]}"
    folium.CircleMarker([r["decimalLatitude"], r["decimalLongitude"]],
                        radius=3, tooltip=tip).add_to(mc)

# Heatmap
HeatMap(df[["decimalLatitude","decimalLongitude"]].values.tolist(),
        name="Density", radius=14, blur=22, min_opacity=0.25).add_to(m)

folium.LayerControl().add_to(m)
m.save("otn_blue_shark_map.html")
print("Saved → otn_blue_shark_map.html")
```

### 7) Yearly & Monthly Patterns

Summarize how records are distributed in time.

```python
# Records per year
df["eventDate"].dt.year.value_counts().sort_index().plot(kind="bar", title="Records per year")
plt.xlabel("Year"); plt.ylabel("Records"); plt.show()

# Records by month
df["eventDate"].dt.month.value_counts().sort_index().plot(kind="bar", title="Records by month")
plt.xlabel("Month"); plt.ylabel("Records"); plt.show()
```

## Quick-Start: Atlantic Salmon in Atlantic Canada

Now let’s see a **lighter example**: just 4 steps for **Atlantic salmon (*Salmo salar*)**.

### 1) Setup

Use the OTN node, species name, and a bounding box around the Gulf of St. Lawrence.

```python
from pyobis import occurrences
import pandas as pd
import folium
from folium.plugins import HeatMap
import matplotlib.pyplot as plt

OTN = "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"
SPECIES = "Salmo salar"
WKT = "POLYGON((-70 40, -70 50, -55 50, -55 40, -70 40))"
```

### 2) Fetch & clean

Get occurrence records, parse dates, and drop missing coordinates.

```python
df = occurrences.search(
    scientificname=SPECIES,
    nodeid=OTN,
    geometry=WKT,
    startdate="2005-01-01",
    size=2000,
    fields="scientificName,eventDate,decimalLatitude,decimalLongitude,datasetName"
).execute()

df = df.dropna(subset=["decimalLatitude","decimalLongitude"]).copy()
df["eventDate"] = pd.to_datetime(df["eventDate"], errors="coerce")
```

### 3) Map

Plot a heatmap plus a few sample points.

```python
m = folium.Map([df["decimalLatitude"].median(), df["decimalLongitude"].median()], zoom_start=5)
HeatMap(df[["decimalLatitude","decimalLongitude"]].values.tolist(),
        radius=14, blur=22, min_opacity=0.25).add_to(m)

m.save("otn_salmon_map.html")
print("Saved → otn_salmon_map.html")
```

### 4) Simple trend

Count records per year.

```python
df["eventDate"].dt.year.value_counts().sort_index().plot(kind="bar", title="Salmon records per year")
plt.xlabel("Year"); plt.ylabel("Records"); plt.show()
```

---

## Common pitfalls & quick fixes

* **Empty results?** Loosen filters (remove `geometry`, broaden dates, drop `datasetid`).
* **Slow/large queries?** Use `fields=...`, smaller regions, and paginate with `size` + `from`.
* **Missing coordinates?** Drop NA lat/lon before mapping.
* **CRS confusion?** OBIS returns WGS84 (EPSG:4326); mapping expects lon/lat.

---

## Exercises

1. Query a **different species** (e.g., `"Gadus morhua"`) restricted to OTN.
2. Find a specific OTN dataset and filter occurrences by `datasetid`.
3. Compare **recent vs historical** records with `startdate` / `enddate`.
4. Change the `geometry` to your own study region and map results.
5. Save results:

   * **Python:** `df.to_csv("export.csv", index=False)`
   * **R:** `write.csv(salmon, "export.csv", row.names = FALSE)`

---