---
title: Telemetry Reports for Array Operators
teaching: 30
exercises: 0
questions:
    - "How do I summarize and plot my deployments?"
    - "How do I summarize and plot my detections?"
---

**NOTE:** this workshop has been update to align with OTN's 2025 Detection Extract Format. For older detection extracts, please see the this lesson: [Archived OTN Workshop](https://ocean-tracking-network.github.io/otn-workshop-2025-06/). 


## GLATOS Network

### Mapping GLATOS stations - Static map

This section will use a set of receiver metadata from the GLATOS Network, showing stations which may not be included in our Project. We will make a static map of all the receiver stations in three steps, using the package `ggmap`. 

First, we set a basemap using the aesthetics and bounding box we desire. Then, we will filter our stations dataset for those which we would like to plot on the map. Next, we add the stations onto the basemap and look at our creation! If we are happy with the product, we can export the map as a `.tiff` file using the `ggsave` function, to use outside of R. Other possible export formats include: `.png`, `.jpeg`, `.pdf` and more.
~~~
library(ggmap)


#first, what are our columns called?
names(glatos_receivers)


#make a basemap for all of the stations, using the min/max deploy lat and longs as bounding box

base <- get_stadiamap(
  bbox = c(left = min(glatos_receivers$deploy_long), 
           bottom = min(glatos_receivers$deploy_lat), 
           right = max(glatos_receivers$deploy_long), 
           top = max(glatos_receivers$deploy_lat)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable

glatos_deploy_plot <- glatos_receivers %>% 
  dplyr::mutate(deploy_date=ymd_hms(deploy_date_time)) %>% #make a datetime
  dplyr::mutate(recover_date=ymd_hms(recover_date_time)) %>% #make a datetime
  dplyr::filter(!is.na(deploy_date)) %>% #no null deploys
  dplyr::filter(deploy_date > '2011-07-03' & recover_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  dplyr::group_by(station, glatos_array) %>% 
  dplyr::summarise(MeanLat=mean(deploy_lat), MeanLong=mean(deploy_long)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
#to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(decimalLatitude <= 0.5 & decimalLatitude >= 24.5 & decimalLongitude <= 0.6 & decimalLongitude >= 34.9)


#add your stations onto your basemap

glatos_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = glatos_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = glatos_array), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!

glatos_map

#save your receiver map into your working directory

ggsave(plot = glatos_map, filename = "glatos_map.tiff", units="in", width=15, height=8) 
#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping our stations - Static map

We can do the same exact thing with the deployment metadata from OUR project only! This will use metadata imported from our Workbook.

~~~
base <- get_stadiamap(
  bbox = c(left = min(walleye_recievers$DEPLOY_LONG), 
           bottom = min(walleye_recievers$DEPLOY_LAT), 
           right = max(walleye_recievers$DEPLOY_LONG), 
           top = max(walleye_recievers$DEPLOY_LAT)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable

walleye_deploy_plot <- walleye_recievers %>% 
  dplyr::mutate(deploy_date=ymd_hms(GLATOS_DEPLOY_DATE_TIME)) %>% #make a datetime
  dplyr::mutate(recover_date=ymd_hms(GLATOS_RECOVER_DATE_TIME)) %>% #make a datetime
  dplyr::filter(!is.na(deploy_date)) %>% #no null deploys
  dplyr::filter(deploy_date > '2011-07-03' & is.na(recover_date)) %>% #only looking at certain deployments, can add start/end dates here
  dplyr::group_by(STATION_NO, GLATOS_ARRAY) %>% 
  dplyr::summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment

#add your stations onto your basemap

walleye_deploy_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = walleye_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = GLATOS_ARRAY), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!


#view your receiver map!

walleye_deploy_map

#save your receiver map into your working directory

ggsave(plot = walleye_deploy_map, filename = "walleye_deploy_map.tiff", units="in", width=15, height=8) 
#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping all GLATOS Stations - Interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable.  

~~~
library(plotly)

#set your basemap

geo_styling <- list(
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85")
)
~~~
{: .language-r}

Then, we choose which Deployment Metadata dataset we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function.
~~~
#decide what data you're going to use. We have chosen glatos_deploy_plot which we created earlier.

glatos_map_plotly <- plot_geo(glatos_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  
~~~
{: .language-r}

Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long.
~~~
#add your markers for the interactive map

glatos_map_plotly <- glatos_map_plotly %>% add_markers(
  text = ~paste(station, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
~~~
{: .language-r}

Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!
~~~
#Add layout (title + geo stying)

glatos_map_plotly <- glatos_map_plotly %>% layout(
  title = 'GLATOS Deployments<br />(> 2011-07-03)', geo = geo_styling
)

#View map

glatos_map_plotly
~~~
{: .language-r}

To save this interactive map as an `.html` file, you can explore the function htmlwidgets::saveWidget(), which is beyond the scope of this lesson.

### How are my stations performing?

Let's find out more about the animals detected by our array! These summary statistics, created using `dplyr` functions, could be used to help determine the how successful each of your stations has been at detecting your tagged animals. We will also learn how to export our results using `write_csv`.

~~~
#How many detections of my tags does each station have?

library(dplyr)

det_summary  <- all_dets  %>%
  filter(glatos_project_receiver == 'HECST') %>%  #choose to summarize by array, project etc!
  mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc))  %>%
  group_by(station, year = year(detection_timestamp_utc), month = month(detection_timestamp_utc)) %>%
  summarize(count =n())

det_summary #number of dets per month/year per station


#How many detections of my tags does each station have? Per species

anim_summary  <- all_dets  %>%
  filter(glatos_project_receiver == 'HECST') %>%  #choose to summarize by array, project etc!
  mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc))  %>%
  group_by(station, year = year(detection_timestamp_utc), month = month(detection_timestamp_utc), common_name_e) %>%
  summarize(count =n())

anim_summary #number of dets per month/year per station & species

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- all_dets %>% 
  group_by(station) %>%
  summarise(num_detections = length(animal_id),
            start = min(detection_timestamp_utc),
            end = max(detection_timestamp_utc),
            uniqueIDs = length(unique(animal_id)), 
            det_days=length(unique(as.Date(detection_timestamp_utc))))
View(stationsum)

~~~
{: .language-r}
