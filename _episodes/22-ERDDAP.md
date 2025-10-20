---
title: "Accessing OTN ERDDAP Data"
teaching: 15
exercises: 15
questions:
- "What is ERDDAP and what kind of data does it serve?"
- "How can I query OTN datasets and download subsets for analysis?"
- "How can I bring ERDDAP data into R or Python for exploration?"
objectives:
- "Understand what kinds of OTN data are published via ERDDAP."
- "Construct a simple TableDAP request to retrieve a custom data subset."
- "Load ERDDAP data directly into R or Python for analysis."
keypoints:
- "ERDDAP shares OTN’s tabular and time-series data through open web services."  
- "Every dataset has a stable ID and variables you can select freely."  
- "Requests are just URLs: pick variables, add filters, and choose an output format."  
- "You can load ERDDAP results directly into R or Python using CSV or JSON."  
- "Start small, then build up filters for time, space, and attributes."
---

## What is ERDDAP?

**ERDDAP** (Environmental Research Division’s Data Access Program) is an **open-source data server** that provides a consistent, flexible way to **search, subset, and download scientific data**, especially time-series and tabular data from many sources using simple web URLs.

It acts as both a **database and a web API**: you describe what data you want by specifying variables, filters, and an output format, and ERDDAP returns a ready-to-use file (like CSV, JSON, or NetCDF) that can be loaded directly into R, Python, or other analysis tools.

### How OTN uses it

OTN publishes its **public time-series and detection data** through ERDDAP.
That includes things like:

* detections of acoustically tagged animals
* glider mission measurements (temperature, salinity, etc.)
* mooring or sensor time-series

Each dataset in ERDDAP has a unique **dataset ID** (e.g. `otn_aat_detections`) and a list of **variables** (columns) such as `time`, `latitude`, `longitude`, `depth`, or `transmitter_id`.

Researchers can use ERDDAP to:

* pull only the **columns** they need (no giant downloads)
* limit results by **time** or **location**
* choose an **output format** (CSV, JSON, NetCDF)
* integrate those results directly into analysis workflows

In short: ERDDAP is OTN’s **data engine** — it tells you *what happened, where, and when*.

## Anatomy of an ERDDAP TableDAP Request

ERDDAP provides **table-based access** to OTN data through a simple, reproducible URL pattern.
Each request is a **complete recipe** for what data you want, how it should be filtered, and what format it should come back in.

### The basic structure

```text
https://members.oceantrack.org/erddap/tabledap/<dataset_id>.<file_type>?<variables>[&<filters>]
```

An ERDDAP URL is made up of four parts:

| Component         | Description                                 | Example                                                                          |
| ----------------- | ------------------------------------------- | -------------------------------------------------------------------------------- |
| **Base endpoint** | Always starts with `/erddap/tabledap/`      | `https://members.oceantrack.org/erddap/tabledap/`                                |
| **Dataset ID**    | The specific dataset to query               | `otn_aat_detections`                                                             |
| **File type**     | The output format you want                  | `.csv`, `.json`, `.nc`                                                           |
| **Query**         | Variables and filters joined by `?` and `&` | `?time,latitude,longitude&time>=2016-11-01T00:00:00Z&time<=2016-11-16T23:59:59Z` |

Putting it all together:

```text
https://members.oceantrack.org/erddap/tabledap/otn_aat_detections.csv?time,latitude,longitude&time>=2016-11-01T00:00:00Z&time<=2016-11-16T23:59:59Z
```

This request asks ERDDAP to:

* use the **`otn_aat_detections`** dataset
* return results in **CSV** format
* include only the columns `time`, `latitude`, and `longitude`
* limit rows to detections between **1–16 November 2016**

### Choosing Variables, Filters, and Formats

Every ERDDAP dataset comes with its own list of variables and supported filters, all visible directly in the web interface. You can select only the variables you need, then apply constraints, such as time ranges, latitude and longitude bounds, or numeric thresholds, to limit what the server returns. All of these filters are applied on the server side, meaning you only download the exact subset you request.

You can also choose from multiple output formats, depending on your workflow. Most users start with `.csv` for use in R or Python, but ERDDAP also supports JSON, NetCDF (`.nc`), and newer formats like Parquet for large or cloud-based analyses. The full list of options appears at the bottom of the Data Access Form.

### Try it yourself

You can open a live query in your browser right now:

🔗 [https://members.oceantrack.org/erddap/tabledap/otn_aat_detections.csv?time,latitude,longitude&time>=2016-11-01T00:00:00Z&time<=2016-11-16T23:59:59Z](https://members.oceantrack.org/erddap/tabledap/otn_aat_detections.csv?time,latitude,longitude&time>=2016-11-01T00:00:00Z&time<=2016-11-16T23:59:59Z)

You can change `.csv` → `.json` or adjust the dates to explore how the system responds.

## Accessing OTN ERDDAP Data in R and Python

### Example: Reading from ERDDAP in R

```r
# If needed, install:
# install.packages("readr")

library(readr)

# Define the ERDDAP URL
erddap_url <- "https://members.oceantrack.org/erddap/tabledap/otn_aat_detections.csv?time,latitude,longitude&time>=2016-11-01T00:00:00Z&time<=2016-11-16T23:59:59Z"

# Read directly into R as a data frame
detections <- read_csv(erddap_url, show_col_types = FALSE)

# Preview the first few rows
head(detections)
```

**What happens here:**

* `read_csv()` downloads the filtered dataset directly from ERDDAP.
* The server only returns the columns and date range specified in the URL.
* The result is ready for immediate use — you can summarize, plot, or join it with other data.

### Example: Reading from ERDDAP in Python

```python
# If needed, install:
# pip install pandas

import pandas as pd

# Define the ERDDAP URL
erddap_url = (
    "https://members.oceantrack.org/erddap/tabledap/otn_aat_detections.csv?"
    "time,latitude,longitude&"
    "time>=2016-11-01T00:00:00Z&"
    "time<=2016-11-16T23:59:59Z"
)

# Load the data into a pandas DataFrame
detections = pd.read_csv(erddap_url)

# Preview the first few rows
print(detections.head())
```

**What happens here:**

* `pd.read_csv()` fetches the CSV directly from ERDDAP.
* Filtering, variable selection, and formatting all happened server-side.
* You can now analyze or visualize this subset locally.

## Exploring ERDDAP’s Built-in Tools

Beyond being a data API, **ERDDAP provides a complete browser interface** for exploring, filtering, plotting, and exporting datasets.
Each dataset page includes a set of built-in utilities designed for quick data access, discovery, and testing.

**Exploring the ERDDAP Dataset Catalog**

When you first open the Ocean Tracking Network’s ERDDAP server, this is the page you’ll see.
It’s a catalog, a complete list of every dataset that the system makes publicly available.
Think of it as the **front door** to OTN’s data services.

<p align="center">
  <img src="../fig/erddap_catalog.png" alt="ERDDAP main dataset catalog showing dataset titles, links, and dataset IDs" width="85%">
</p>

Each row in this table represents a single dataset. Some are small (for example, metadata tables or summaries), while others, like **animal detections** or **glider missions**, contain millions of records collected across years of field work.

If you look closely, every dataset row is packed with small links, each one opens a different way of exploring the same data.

The link under **“TableDAP”** takes you to the *Data Access Form*.
That’s where you can select specific variables, apply filters (for example, only detections from a certain date or region), and download a subset of the data.
This is the page most researchers use first, since it gives full control over what to request.

The link under **“Make A Graph”** opens a lightweight plotting interface directly on the server.
It’s a quick way to visualize patterns, for instance, you can plot a glider’s depth through time or see where animals were detected along latitude and longitude.
It’s not meant for final figures, but it’s perfect for checking if the data behave as expected before you start coding.

Some datasets also include a **“Files”** link, which points to raw data files, usually in NetCDF or CSV format.
This is useful if you want the complete dataset for offline work rather than a filtered subset.

To the right, the **Metadata** and **Background Info** links take you to documentation pages that describe the dataset in detail:
variable names, units, ranges, collection methods, licensing, and citation information.
These pages are essential for understanding what you’re actually downloading and how to use it responsibly.

Finally, each dataset has a short **Dataset ID** in the far-right column, something like `otn_aat_detections` or `otn200_20220912_116_realtime`.
That ID is what you’ll use in R, Python, or any programmatic query.
It’s how ERDDAP knows which dataset you’re asking for.

In practice, this catalog is the starting point for everything you do in ERDDAP.
You find the dataset you want here, click through to explore it, and then either download it manually or copy the generated URL into your code.
Once you know how to read this page, you can move through the rest of ERDDAP effortlessly.

## The Data Access Form

Clicking a dataset’s **data** link opens the *Data Access Form* — an interactive page where you can explore variables, apply filters, and build precise queries before downloading.

<p align="center" style="display: flex; justify-content: center; gap: 15px;">
  <img src="../fig/erddap_data_access_form.png" alt="ERDDAP Data Access Form showing variable and filter options" width="48%">
  <img src="../fig/erddap_data_access_preview.png" alt="ERDDAP data preview after clicking Submit" width="48%">
</p>

Each row in the form represents a variable, such as `time`, `latitude`, `longitude`, or `depth`. You can tick the boxes beside the variables you want, or add constraints beside them to narrow your search — for example, a specific time window or a latitude range. At the bottom, the **File type** menu controls how ERDDAP returns your data. Most people start with `.csv` for quick analysis, though `.json` or `.nc` formats work just as easily.

When you’re ready, there are two paths forward. Clicking **Submit** runs your query instantly and shows the results as a live table in your browser. It’s a fast way to confirm that your filters worked and that the dataset contains what you expect. Alternatively, you can choose **“Just generate the URL”**. That option builds a reusable link that encodes everything you’ve selected, the dataset ID, variables, filters, and file format so you can paste it directly into a browser, R script, or Python notebook and get the exact same data again.

## The “Make A Graph” Tool

Right beside the **data** link in each ERDDAP dataset, you’ll find **Make A Graph**, a quick way to visualize data directly on the server before downloading anything.

<p align="center">
  <img src="../fig/erddap_make_a_graph.png" alt="ERDDAP Make A Graph interface showing variable selection and plot preview" width="65%">
</p>

This page works a lot like the Data Access Form but adds a plotting panel at the bottom. You can choose which variable to plot on the X and Y axes, apply filters to limit time or space, and preview the results as a simple line, scatter, or depth profile. It’s meant for exploration rather than publication, a lightweight way to check data coverage, spot trends, or verify that your filters are returning what you expect.

When you click **Redraw the graph**, ERDDAP builds the plot instantly. Below it, you’ll see a caption and a direct URL that reproduces the same visualization. That link works the same way as the data URLs: it encodes every choice you’ve made, dataset, variables, filters, and plot type, so anyone can re-create the same graph later.

## Other Features in ERDDAP

Beyond the data and graph tools, ERDDAP also provides a few other views that help you understand each dataset in more depth.

The **Metadata** link opens a detailed description of the dataset, every variable, its units, range, and data type, along with global attributes such as license, citation, and time coverage. It’s the reference point for anyone wanting to understand what the data represent or how they were collected.

The **Background Info** page offers a higher-level summary: where the dataset came from, which project or instrument produced it, and sometimes links to external documentation or related studies. It’s especially helpful when working with glider or animal tracking data, where context matters as much as the measurements themselves.

Some datasets also include a **Files** link. This provides direct access to pre-packaged data files, often in NetCDF or CSV or Parquet, for users who prefer to download entire archives instead of making filtered requests. It’s a straightforward option when you want everything, not just a subset.

Together, these pages make ERDDAP more than just a data portal. It’s a complete environment for discovery — you can inspect, filter, visualize, and document the same dataset without ever leaving the interface. Once you know how these parts fit together, you can move confidently between browsing in the web interface and automating the same workflows in R or Python.

---