library(devtools)
library(httr2)
library(dplyr)
library(raster)
library(readr)
library(terra)
library(tidyverse)
library(sf)
library(sp)
library(raster)
library(stars)
library(glatos)
library(utils)
library(geosphere)
library(rangeBuilder)
library(surimi)

devtools::install_github("ocean-tracking-network/surimi", force=TRUE)

devtools::install_github("ocean-tracking-network/remora", force=TRUE)
library(remora)

setwd('YOUR/PATH/TO/remora')

download.file("https://members.oceantrack.org/data/share/testdataotn.zip/@@download/file/testDataOTN.zip", "./testDataOTN.zip")
unzip("testDataOTN.zip")

world_raster <- raster::raster("./testDataOTN/NE2_50M_SR.tif")

tests_vector <-  c("FDA_QC",
                   "Velocity_QC",
                   "Distance_QC",
                   "DetectionDistribution_QC",
                   "DistanceRelease_QC",
                   "ReleaseDate_QC",
                   "ReleaseLocation_QC",
                   "Detection_QC")

otn_files_nsbs <- list(det = "./nsbs_matched_detections_2021.csv")

scientific_name <- "Prionace glauca"

sharkOccurrence <- getOccurrence(scientific_name)

sharkPolygon <- createPolygon(sturgeonOccurrence, fraction=1, partsCount=1, buff=100000, clipToCoast = "aquatic")

otn_test_tag_qc <- runQC(otn_files_nsbs, 
                         data_format = "otn", 
                         tests_vector = tests_vector, 
                         shapefile = sharkPolygon, 
                         col_spec = NULL, 
                         fda_type = "pincock", 
                         rollup = TRUE,
                         world_raster = world_raster,
                         .parallel = FALSE, .progress = TRUE)

plotQC(otn_test_tag_qc, distribution_shp = sturgeonPolygon, data_format = "otn")
