# ==============================================================================
# 02. Batch Pre-processing & Extraction
# ==============================================================================
# This script prepares the ground-truth data for analysis.
# For every Site/Year combination, it:
# 1. Rasterizes the Label Shapefiles into Fractional Cover layers.
# 2. Aligns Sentinel-2 imagery to these Fractional layers.
# 3. Extracts all pixel values into a tidy CSV for modeling.

library(terra)
library(sf)
library(dplyr)

# --- Load Project Configuration & Utilities ---
source("source/config.R")
source("source/spatial_processing_utils.R")

message("🚀 Starting Batch Pre-processing...")

for (site_name in ALL_SITE_NAMES) {
  for (year in ALL_YEARS) {
    
    message(paste("\n🛠️  Preprocessing:", site_name, year))
    
    tryCatch({
      # --- A. Setup Paths & Variables ---
      site_abbr <- SITE_ABBREVIATIONS[[site_name]]
      
      # 1. Input: Sentinel-2 Image
      sen2_filename <- paste0(site_name, "_Sen2_", year, ".tif")
      sen2_path     <- file.path(DIRS$SEN2_DIR, sen2_filename)
      
      # 2. Input: Label Shapefile (Handle "Webbekomsbroek2" naming exception)
      if (site_name == "Webbekomsbroek2") {
        label_shp_name <- paste0("Labels_WB_", year, "_2.shp")
      } else {
        label_shp_name <- paste0("Labels_", site_abbr, "_", year, ".shp")
      }
      label_path <- file.path(DIRS$LABELS_SHP_DIR, label_shp_name)
      
      # 3. Output: Fraction Raster
      frac_out_dir <- file.path(DIRS$FRACTIONS_DIR, site_name, year)
      if(!dir.exists(frac_out_dir)) dir.create(frac_out_dir, recursive=TRUE)
      frac_out_path <- file.path(frac_out_dir, paste0(site_name, "_", year, "_fractions.tif"))
      
      # 4. Output: Final Pixel CSV
      pixel_out_dir <- file.path(DIRS$PIXEL_DATA_DIR, site_name, year)
      if(!dir.exists(pixel_out_dir)) dir.create(pixel_out_dir, recursive=TRUE)
      csv_out_path <- file.path(pixel_out_dir, paste0(site_name, "_", year, "_final_pixel_attributes.csv"))
      
      # --- B. Validation Checks ---
      if (!file.exists(sen2_path)) {
        message(paste("   ⚠️ Skipping: Sentinel-2 image missing at", sen2_path))
        next
      }
      if (!file.exists(label_path)) {
        message(paste("   ⚠️ Skipping: Label shapefile missing at", label_path))
        next
      }
      
      # --- STEP 1: Create Fraction Raster ---
      # We only run this if the raster doesn't already exist
      if (!file.exists(frac_out_path)) {
        message("   Generating fractional raster...")
        
        # Load inputs
        s2_template <- rast(sen2_path)
        labels_v <- st_read(label_path, quiet = TRUE)
        
        # Fix potential label inconsistencies (e.g. "Reeds" -> "Reed")
        if("Label" %in% names(labels_v)) {
          if("Reeds" %in% labels_v$Label) {
            labels_v$Label[labels_v$Label == "Reeds"] <- "Reed"
            message("   -> Fixed label spelling: 'Reeds' to 'Reed'")
          }
        }
        
        # Ensure CRS Match
        if (st_crs(labels_v) != st_crs(s2_template)) {
          message("   -> Reprojecting shapefile to match Sentinel-2 CRS...")
          labels_v <- st_transform(labels_v, st_crs(s2_template))
        }
        
        # Create and Save
        fractions_r <- create_fraction_raster(labels_v, s2_template)
        writeRaster(fractions_r, frac_out_path, overwrite=TRUE)
        message("   ✅ Fraction raster saved.")
      } else {
        fractions_r <- rast(frac_out_path)
        message("   ℹ️  Fractional raster already exists. Loaded from disk.")
      }
      
      # --- STEP 2: Align, Extract & Calculate ---
      if (!file.exists(csv_out_path)) {
        message("   Extracting pixel values...")
        
        s2_template <- rast(sen2_path) 
        
        # Filter to only spectral bands (B02, B03, etc.) ignoring masks/classification layers
        s2_bands <- subset(s2_template, names(s2_template)[grep("^B(\\d{1,2}A?)$", names(s2_template))])
        
        # Align Sentinel-2 grid to Fraction Grid
        # (Resample using Nearest Neighbor to preserve values, Mask to valid fraction area)
        s2_aligned <- terra::resample(s2_bands, fractions_r, method = "near")
        s2_aligned <- terra::mask(s2_aligned, fractions_r[[1]])
        
        # Combine into one stack
        combined_stack <- c(fractions_r, s2_aligned)
        
        # Extract to Data Frame
        # values() gets the data, xyFromCell gets the coordinates
        df <- as.data.frame(values(combined_stack, na.rm=TRUE))
        valid_cells <- which(!is.na(values(combined_stack[[1]])))
        coords <- xyFromCell(combined_stack, valid_cells)
        
        df <- cbind(as.data.frame(coords), df)
        colnames(df)[1:2] <- c("x_coord", "y_coord")
        
        # Calculate Scaled Reflectance (0-1) and Spectral Indices
        s2_cols <- names(df)[grep("^B", names(df))]
        for(col in s2_cols) {
          df[[paste0(col, "_scaled")]] <- df[[col]] / 10000.0
        }
        
        df <- calculate_spectral_indices(df)
        
        # Classify Purity (Pure/Mixed) based on fraction columns
        # (names(fractions_r) gives us the label columns like 'Inundated', 'Reed', etc.)
        df <- classify_pixel_mixture(df, names(fractions_r))
        
        # Save Final CSV
        write.csv(df, csv_out_path, row.names = FALSE)
        message("   ✅ Extracted pixel data saved to CSV.")
        
      } else {
        message("   ℹ️  Pixel CSV already exists. Skipping.")
      }
      
    }, error = function(e) {
      message(paste("❌ Error in preprocessing:", e$message))
    })
  }
}

message("\n🎉 Batch Pre-processing Finished.")

