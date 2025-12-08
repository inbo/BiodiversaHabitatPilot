# EU Grassland Watch - Typology validation

**The EU Grassland Watch provided typology rasters as a prototype project for severall regions in Europe. Management and Productivity products were not available during the project, and where therefore not evaluated. Validation occured on severall levels, including (1) binary validation (grassland vs non-grassland) based on photo interpretation of high resolution ortho imagery and (2) field survey to validate grassland typology based on the EUNIS Level 2 definitions.**

![Status](https://img.shields.io/badge/Status-Active-success.svg)

## 📋 Overview

This repository contains different scripts to support EUGW validation. 


[👉 **Scripts can be found here**](./source/), under the analysis folder of each topic.

## Scripts

* **notebook_validatie_EUGrasslandWatch.ipynb**: Jupyter notebook that allows binary validation of the EUGW topology raster products. The requirements file contains the list of necessary python packages that have to be installed in an python evironment in order to run the notebook succesfully.  
* **__CONFIG_&_RUN.R**: R scripts that creates the Sankey-Diagrams of a EUGW topology tile, created for each year between 2016-2023. This master scripts runs the orther scripts within the same folder. 
* **Statistical power analysis field survey.R**: R script that conducts power analysis (binomial test) for the user accuracy of a topology class. 
* **Stratified_random_sample_EUGW_raster_multipletiles.R**: R script that takes a random sample (sampled over multipe EUGW tiles) for a certain topology class. 


### Key Features
* **Field survey desig,:** R-scripts to determine the minimum number of validation samples per stratum through power analsysis and selecting sample locations for field validation.
* **Interactive notebook for ortho validation:** Jupyter notebook that allows binary validation (grassland vs non-grassland) of the EUGW typology raster based on photo-interpretation of high resolution ortho-imagery. 
* **Sankey-diagrams:** Sankey-diagrams that show pixel value change over the different yearly products 


