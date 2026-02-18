---
title: Telemetry Reports - Imports
teaching: 10
exercises: 0
questions:
    - "What datasets do I need from the Network?"
    - "How do I import all the datasets?"
---

**NOTE:** this workshop has been update to align with OTN's 2025 Detection Extract Format. For older detection extracts, please see the this lesson: [Archived OTN Workshop](https://ocean-tracking-network.github.io/otn-workshop-2025-06/). 

## GLATOS Network

### Importing all the datasets
Now that we have an idea of what an exploratory workflow might look like with Tidyverse libraries like `dplyr` and `ggplot2`, let's look at how we might implement a common telemetry workflow using these tools. 

For the GLATOS Network you will receive Detection Extracts which include all the Tag matches for your animals. These can be used to create many meaningful summary reports.

> ## Regarding Raw Data
> Although this lesson assumes you are working with detection extracts from your node (processed data containing matches between animals and receivers), 
> it is likely that you also have raw data directly from your instruments. If you are using Innovasea equipment, the file format for this raw data is '.vdat.' 
> While reading and manipulating this raw data is beyond the scope of this workshop, there are tools available to help you with this. The [rvdat](https://github.com/mhpob/rvdat/) 
> package provides a lightweight R interface for inspecting .vdat file metadata and converting the data to .csv format. Additionally, .csv files created in this way can be 
> read and manipulated with the glatos package, covered later in this workshop. In short, although the purpose of this workshop is to teach you to work with detection extracts, 
> there exist related, robust options for managing your raw data as well.
{: .callout}

First, we will comfirm we have our Tag Matches stored in a dataframe.

~~~
View(all_dets) #already have our tag matches

# if you do not have the variable created from a previous lesson, you can use the following code to re-create it:

#lamprey_dets <- read_csv("inst_extdata_lamprey_detections.csv", guess_max = 3103)
#walleye_dets <- read_csv("inst_extdata_walleye_detections.csv", guess_max = 9595) 
# lets join these two detection files together!
#all_dets <- rbind(lamprey_dets, walleye_dets)
~~~
{: .language-r}

To give meaning to these detections we should import our GLATOS Workbook. These are in the standard GLATOS-style template which can be found [here](https://glatos.glos.us/portal).

~~~
library(readxl)

# Deployment Metadata

walleye_deploy <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Deployment') #pull in deploy sheet
View(walleye_deploy)

walleye_recovery <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Recovery') #pull in recovery sheet
View(walleye_recovery)

#join the deploy and recovery sheets together

walleye_recovery <- walleye_recovery %>% rename(INS_SERIAL_NO = INS_SERIAL_NUMBER) #first, rename INS_SERIAL_NUMBER so they match between the two dataframes.

walleye_recievers <- merge(walleye_deploy, walleye_recovery,
                          by.x = c("GLATOS_PROJECT", "GLATOS_ARRAY", "STATION_NO",
                                    "CONSECUTIVE_DEPLOY_NO", "INS_SERIAL_NO"), 
                          by.y = c("GLATOS_PROJECT", "GLATOS_ARRAY", "STATION_NO", 
                                    "CONSECUTIVE_DEPLOY_NO", "INS_SERIAL_NO"), 
                          all.x=TRUE, all.y=TRUE) #keep all the info from each, merged using the above columns

View(walleye_recievers)

# Tagging metadata

walleye_tag <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Tagging')

View(walleye_tag)

#remember: we learned how to switch timezone of datetime columns above, 
# if that is something you need to do with your dataset!! 
  #hint: check GLATOS_TIMEZONE column to see if its what you want!
~~~
{: .language-r}

The `glatos` R package (which will be introduced in future lessons) can import your Workbook in one step! The function will format all datetimes to UTC, check for conflicts, join the deploy/recovery tabs etc. This package is beyond the scope of this lesson, but is incredibly useful for GLATOS Network members. Below is some example code:

~~~
# this won't work unless you happen to have this installed - just an teaser today, will be covered tomorrow
library(glatos) 
data <- read_glatos_workbook('inst_extdata_walleye_workbook.xlsm')
receivers <- data$receivers
animals <-  data$animals
~~~
{: .language-r}

Finally, we can import the station locations for the entire GLATOS Network, to help give context to our detections which may have occured on parter arrays.
~~~
glatos_receivers <- read_csv("inst_extdata_sample_receivers.csv")
View(glatos_receivers)
~~~
{: .language-r}
