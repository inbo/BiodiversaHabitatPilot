library(raster)
library(sp)
library(sf)
library(dplyr)

# ---------------- USER INPUTS -----------------

input_folder  <- "G:/Mijn Drive/Grasland validatie/Validatie_grasland/data/EUGW_data/type/2023/selectie Semois"
output_folder <- "G:/Mijn Drive/Grasland validatie/Validatie_grasland/data/EUGW_data/type/2023/selectie Semois/Mesic_samples"

target_value <- 22      # Grassland class to sample
subset_n     <- 200     # Number of random samples to keep
process_na   <- TRUE    # Include NA sampling

# --- NEW: Path to polygon area you want to restrict sampling to ---
aoi_path <- "G:/Mijn Drive/Grasland validatie/Validatie_grasland/data/EUGW_data/type/2023/selectie Semois/SAC_Marais_Semois.gpkg"

# ------------------------------------------------

# Read AOI
aoi <- st_read(aoi_path)
aoi <- st_make_valid(aoi)

# Use same CRS as rasters (assumes first raster defines CRS)
first_r <- raster(list.files(input_folder, pattern = "\\.tif$", full.names = TRUE)[1])
aoi <- st_transform(aoi, crs(first_r))

# List raster files
rasters <- list.files(input_folder, pattern = "\\.tif$", full.names = TRUE)

# Create output folder
if(!dir.exists(output_folder)) dir.create(output_folder, recursive = TRUE)

# Empty storage lists
combined_index_pts <- list()
combined_na_pts    <- list()

# ------------------------------------------------
# Function to process one tile
# ------------------------------------------------
process_tile <- function(raster_path) {

  message("\n----- Processing: ", basename(raster_path), " -----")

  r <- raster(raster_path)

  # ---- Create an "original NA map" BEFORE masking ----
  orig_na <- is.na(r)

  # ---- Crop and mask to AOI ----
  r       <- crop(r, aoi)
  r       <- mask(r, aoi)

  orig_na <- crop(orig_na, aoi)
  orig_na <- mask(orig_na, aoi)

  # ============================
  # 1. TARGET CLASS SAMPLING
  # ============================
  target_cells <- Which(r == target_value, cells = TRUE)

  if(length(target_cells) > 0){
    index_r <- raster(r)
    index_r[] <- NA
    index_r[target_cells] <- seq_len(length(target_cells))

    index_pts <- rasterToPoints(index_r, spatial = TRUE)
    index_pts <- index_pts[!is.na(index_pts$layer), ]

    combined_index_pts[[length(combined_index_pts)+1]] <<- st_as_sf(index_pts)
  }

  # ============================
  # 2. TRUE NA SAMPLING (fixed)
  # ============================
  if(process_na){

    # TRUE NA inside AOI:
    # - pixel inside AOI AND original raster was NA
    na_cells <- Which(orig_na == 1, cells = TRUE)

    if(length(na_cells) > 0){
      na_r <- raster(orig_na)
      na_r[] <- NA
      na_r[na_cells] <- seq_len(length(na_cells))

      na_pts <- rasterToPoints(na_r, spatial = TRUE)
      na_pts <- na_pts[!is.na(na_pts$layer), ]

      combined_na_pts[[length(combined_na_pts)+1]] <<- st_as_sf(na_pts)
    }
  }
}


# ------------------------------------------------
# Run extraction
# ------------------------------------------------
lapply(rasters, process_tile)

message("\nAll raster points collected – combining...\n")

# ------------------------------------------------
# Combine collected points into two objects
# ------------------------------------------------
combined_index_pts <- do.call(rbind, combined_index_pts)
combined_index_pts <- st_make_valid(combined_index_pts)

if(process_na){
  combined_na_pts <- do.call(rbind, combined_na_pts)
  combined_na_pts <- st_make_valid(combined_na_pts)
}

# ------------------------------------------------
# Sample N points from combined sets
# ------------------------------------------------
set.seed(42)

index_subset <- combined_index_pts %>% slice_sample(n = subset_n)

if(process_na){
  na_subset <- combined_na_pts %>% slice_sample(n = subset_n)
}

# ------------------------------------------------
# Transform to WGS84
# ------------------------------------------------
combined_index_pts <- st_transform(combined_index_pts, 4326)
index_subset       <- st_transform(index_subset, 4326)

if(process_na){
  combined_na_pts <- st_transform(combined_na_pts, 4326)
  na_subset       <- st_transform(na_subset, 4326)
}

# ------------------------------------------------
# WRITE OUTPUT FILES
# ------------------------------------------------
st_write(combined_index_pts,
         file.path(output_folder, "combined_index_pts.gpkg"),
         delete_layer = TRUE)

st_write(index_subset,
         file.path(output_folder, paste0("combined_index_subset_", subset_n, ".gpkg")),
         delete_layer = TRUE)

if(process_na){
  st_write(combined_na_pts,
           file.path(output_folder, "combined_na_pts.gpkg"),
           delete_layer = TRUE)

  st_write(na_subset,
           file.path(output_folder, paste0("combined_na_subset_", subset_n, ".gpkg")),
           delete_layer = TRUE)
}

message("\n### All done! AOI-restricted sampling completed. ###\n")
