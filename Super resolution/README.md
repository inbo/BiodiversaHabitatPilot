# Super resolution

**Pixel-wise comparisment between a satellite super resolution image and a reference image (aerial high resolution aerial image and Sentinle-2 low resolution image).**


![Status](https://img.shields.io/badge/Status-Active-success.svg)

## 📋 Overview

This repository contains different scripts that compares super resolution (SR) images (satlas ESRGAB model and Gamma Earth S2DR3 model) with a high (aerial ortho winter image) and low resolution reference (Sentinel-2 L2A) for Webbekomsbroek. The aerial ortho image and the cloud-free Sentinel-2 image are from the same date (01/03/2023).  

* **satlas ESRGAN model** https://github.com/allenai/satlas-super-resolution --> images where provided by the Metria team (contact persons: <nils.gumaelius@metria.se> and <johannaskarpman@gmail.com>). 
* **Gamma Earth S2DR3 model** https://colab.research.google.com/drive/18phbwA1iYG5VDGN2WjK7WrWYi-FdCHJ5 

* [**👉 More Documentation on the SR images**](./source/Quantitative_Analysis_Webbekomsbroek/data/processed/README.txt)

## Scripts
[**👉 link to the scripts**](./source/Quantitative_Analysis_Webbekomsbroek/analysis/)

* **S2DR3T_infer_20240430.ipynb**: Google colab notebook that was used to donwload the super resolution image from the S2DR3 model for the study area.
* **WB_SR_QA_S2DR3.qmd**: Quarto file that does the pixel-wise quantative evalatution between the S2DR3 super resolution image with the reference images (aerial ortho image and the Sentinel-2 L2A image).
* **WB_SR_QA_Satlas_1im_input.qmd**: Quarto file that does the pixel-wise quantative evalatution between the Satlas ESRGAN super resolution image with the reference images (aerial ortho image and the Sentinel-2 L2A image). This super resolution image was generated with only 1 low resolution Sentinel-2 input image and contains only RGB (red-green-blue) information.
* **WB_SR_QA_Satlas81im_input.qmd**: Quarto file that does the pixel-wise quantative evalatution between the Satlas ESRGAN super resolution image with the reference images (aerial ortho image and the Sentinel-2 L2A image). This super resolution image was generated with 8 multi-date low resolution Sentinel-2 input image and contains only RGB (red-green-blue) information. Bands 8, 12 and 13 (= band 8A (NIR), band 11 (SWIR1) and band 12 (SWIR2)) were generated using pan-sharpening.  

### Key Features
* **Sentinel 2 super resolution images:** 
* **Multi-Model Support:** Runs simultaneous validation of different algorithms (Decision Trees vs. Hardcoded Thresholds).

