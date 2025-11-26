# ==============================================================================
# CONFIGURATION: Local Batch Processing Settings
# ==============================================================================

# --- 1. Batch Definitions ---
# The scripts will loop through every combination of these sites and years.
ALL_SITE_NAMES <- c("Webbekomsbroek", "Schulensmeer", "Kloosterbeemden", "Webbekomsbroek2")
ALL_YEARS      <- c(2020, 2021, 2023, 2024)

# --- 2. Site Mappings ---
# Maps full names to abbreviations used in filenames (e.g., 'Extent_WB.shp')
SITE_ABBREVIATIONS <- list(
  "Webbekomsbroek"  = "WB",
  "Webbekomsbroek2" = "WB",
  "Schulensmeer"    = "SM",
  "Kloosterbeemden" = "KB"
)

# --- 3. Local Directory Structure ---
# Everything is local now. Ensure your 'data' folder is populated!
DIRS <- list(
  # --- ROOTS ---
  DATA             = "data",
  OUTPUT           = "output",
  
  # Inputs
  LOOKUP_TABLE     = file.path("data", "lookup_tables", "sen2_dates.csv"),
  EXTENT_SHP_DIR   = file.path("data", "Extent_studiegebieden"),
  LABELS_SHP_DIR   = file.path("data", "final_labels"),
  
  # Outputs
  SEN2_DIR         = file.path("data", "Sen2"),
  FRACTIONS_DIR    = file.path("output", "fraction_rasters"),
  PIXEL_DATA_DIR   = file.path("output", "pixel_data_tables"),
  PLOTS_DIR        = file.path("output", "plots"),
  FINAL_MAPS_DIR   = file.path("output", "final_maps")
)

# --- 4. OpenEO Settings ---
OPENEO_URL <- "https://openeo.dataspace.copernicus.eu"

# --- 5. Project Constants ---
BACKGROUND_LABEL <- "not inundated"

message("✅ Batch Configuration Loaded.")

# --- 6. Models ---
# Define a named list of models to evaluate
MODELS <- list(
  "Jussila" = "source/jussila_decisiontree.RData",
  "WiW"     = "source/WiW_decisiontree.RData"      
)