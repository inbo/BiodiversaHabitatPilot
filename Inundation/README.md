# Sentinel-2 Inundation Model Validation

**A batch processing workflow for validating and comparing inundation detection models using Sentinel-2 imagery and ground-truth data in Flanders.**

![R](https://img.shields.io/badge/Made%20with-R-blue.svg)
![Status](https://img.shields.io/badge/Status-Active-success.svg)

## 📋 Overview

This repository contains a modular R workflow designed to automate the validation of inundation detection models. It specifically compares the **Jussila Decision Tree** against the **WiW (Water in Wetlands) Threshold** model across multiple study sites and years.

The workflow handles the entire pipeline: from acquiring satellite imagery via OpenEO to generating high-level synthesis reports comparing model performance side-by-side.

### Key Features
* **Batch Processing:** Iterates through multiple study sites and years automatically (Local loops).
* **Multi-Model Support:** Runs simultaneous validation of different algorithms (Decision Trees vs. Hardcoded Thresholds).
* **Automated Pre-processing:** Handles rasterization of vector labels, pixel alignment, and spectral extraction.
* **Comprehensive Reporting:** Generates per-site confusion matrices, spatial maps, and global synthesis plots.

---

## 🔄 Workflow Architecture

The analysis is split into four sequential batch scripts. Each script iterates through the site/year combinations defined in the configuration.

```mermaid
graph TD
    Config[source/config.R] --> S1
    Config --> S2
    Config --> S3
    Config --> S4

    subgraph "1. Acquisition"
    S1[01_OpenEO_Acquisition_Loop.R] -->|Downloads| TIF[Sentinel-2 GeoTIFFs]
    end

    subgraph "2. Pre-processing"
    TIF --> S2[02_Preprocess_And_Extract_Loop.R]
    Labels[Label Shapefiles] --> S2
    S2 -->|Generates| CSV[Pixel Attribute Tables]
    S2 -->|Generates| FRAC[Fractional Cover Rasters]
    end

    subgraph "3. Analysis & Mapping"
    CSV --> S3[03_Analysis_And_Mapping_Loop.R]
    S3 -->|Validates| Jussila[Jussila Model]
    S3 -->|Validates| WiW[WiW Model]
    S3 -->|Outputs| Plots[Per-Site Plots]
    S3 -->|Outputs| Maps[Classified Maps]
    end

    subgraph "4. Synthesis"
    Plots --> S4[04_Synthesis_Report.R]
    S4 -->|Aggregates| Report[Global Synthesis Plots]
    end