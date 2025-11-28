<!-- badges: start -->
[![website](https://img.shields.io/badge/website-https://www.biodiversa.eu/-c04384)](https://www.biodiversa.eu/)
![GitHub](https://img.shields.io/github/license/inbo/BiodiversaHabitatPilot)
<!-- badges: end -->

# Welcome to the INBO Biodiversa+ Habitat Pilot github page
[Verbesselt, Sebastiaan![ORCID logo](https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png)](https://orcid.org/0000-0003-0173-1123) [^aut] [^cre] [^INBO]
[Heremans, Stien![ORCID logo](https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png)](https://orcid.org/0000-0002-5356-1093) [^aut] [^INBO]
[Oosterlynck, Patrik![ORCID logo](https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png)](https://orcid.org/0000-0002-5712-0770) [^aut] [^INBO]
[Spanhove, Toon![ORCID logo](https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png)](https://orcid.org/0000-0001-9194-0193) [^aut] [^INBO]
Research Institute for Nature and Forest (INBO)[^cph]
Biodiversa+[^fnd]

[^cph]: copyright holder
[^fnd]: funder
[^aut]: author
[^cre]: contact person
[^INBO]: Research Institute for Nature and Forest (INBO)


**keywords**: Biodiversa+, Habitat Pilot, Remote Sensing, grasslands, wetlands

<!-- community: inbo -->

<!-- description: start -->
Within this repository, you will find the scripts that INBO has developed for the Biodiversa+ Habitat pilot project (2023-2025).
Each subtaks has its own subfolder. 

### 📂 Project Modules

#### 1. 🌊 Sentinel-2 Inundation Model Validation
A specific R workflow to validate and compare **Jussila** and **WiW** inundation models against Sentinel-2 imagery using OpenEO.
* **Key Features:** Batch processing (multi-site/multi-year), automated pre-processing, and comparative synthesis reporting.
* [**👉 Go to Documentation & Workflow**](./Inundation/README.md)

#### 2. :earth_africa: Habitat condition indicators
A specific R workflow to download and analyse **Sentinel-2 time-series imagery**. Downloading was performed using Open EO (like in the subtask **1. Sentinel-2 Inundation Model Validation**). Imagery data was converted into **soil moisture indices** and to to classify inundation (**Jussila** and **WiW** inundation model) to monitor grass- and wetlands in 3 study areas in the Demer valley in Flanders.   
* **Key Features:** time-series analysis (multi-site/multi-year), soil moisture and inundation.
* [**👉 Go to Documentation & Workflow**](./Habitat_condition_indicators/README.md)

#### 3. :mag_right: Super resolution
A pixel-wise comparisment between super resolution products (**satlas ESRGAN model** https://github.com/allenai/satlas-super-resolution and **Gamma Earth S2DR3 model** https://colab.research.google.com/drive/18phbwA1iYG5VDGN2WjK7WrWYi-FdCHJ5 with reference images: winter aerial ortho imagery and Sentinel-2).
* **Key Features:** super resolution, pixel-wise comparisment.
* [**👉 Go to Documentation & Workflow**](./Super resolution/README.md)
---

**General Note:**
* R scripts and their documentation are provided in R files, Rmarkdown files or Quarto files (rendered as HTML).
* Python scripts are provided as Jupyter notebooks.
<!-- description: end -->

[![INBOLogo](./Logos/image-1.png)](https://www.vlaanderen.be/inbo/home/)
[![BiodiversaLogo](./Logos/image.png)](https://www.biodiversa.eu/)
