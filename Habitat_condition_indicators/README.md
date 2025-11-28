# Habitat Condition Indicators

**Interactive notebooks to batch process Sentinel 2 time-series data from OpenEO for three study sites in Flanders, Belgium. For eacht of the sites, a notebook is given to calculate time-series of soil moisture indices and inundation classfication.**

![Status](https://img.shields.io/badge/Status-Active-success.svg)

## 📋 Overview

This repository demonstrates how soil moisture and inundation of grassland and wetland habitats can be monitored with Sentinel-2 time series data. This for three study areas (Kloosterbeemden, Webbekomsbroek and Schulensmeer) in the Demer valley, Flanders, Belgium. 

The workflow for acquiring satellite imagery via OpenEO is provided, which was used to download for the tree sites for iterative time periods.  

[👉 **See the length and period of the different time here**](./source/hydrology/data/intermediate/README.txt)

[👉 **Scripts can be found here**](./source/analysis/hydrology/analysis/)

* **Retrieve Datacube OpenEO - Demervalley.Rmd**: markdown file that explains on how to batch process and download Sentinel 2 time series data through OpenEO.

* **Datacube_Analysis_Demervalley_Webbekomsbroek.Rmd**: markdown file that demonstrates how time series data can be converted into usefull indicators (soil moisture and inundation). This for habitats in Webbekomsbroek.
* **Datacube_Analysis_Demervalley_Schulensmeer.Rmd**: markdown file that demonstrates how time series data can be converted into usefull indicators (soil moisture and inundation). This for habitats in Schulensmeer.
* **Datacube_Analysis_Demervalley_Kloosterbeemden.Rmd**: markdown file that demonstrates how time series data can be converted into usefull indicators (soil moisture and inundation). This for habitats in Kloosterbeemden.


Further, the notebook of the Flanders workshop that was presented to the partners after the field visit to Webbekomsbroek (15/10/2025) is also provided. Satellite data was compared with field observations (collected as points datasets with QField (RTK corrected data) during the field visit) and aerial ortho images.

* **Workshop Flanders - inudation time series.Rmd**:

Data that was used during the demonstration session can be found on Zenodo:10.5281/zenodo.17751083.

### Key Features
* **Batch Processing:** Iterates through multiple study sites and years automatically (Local loops).
* **interactive maps and time series graphs:** Interactive spatial maps and time-series graphs are provided to allow visual comparisment between classificatie output, aerial reference imagery and spatial interpretability. 

