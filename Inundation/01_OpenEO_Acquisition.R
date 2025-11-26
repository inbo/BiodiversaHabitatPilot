# ==============================================================================
# 01. Batch OpenEO Acquisition
# ==============================================================================
library(sf)
library(openeo)
library(readr)
library(dplyr)
library(stringr)

source("source/config.R")

# 1. Connect to OpenEO (Do this once)
message("Connecting to OpenEO...")
con <- connect(OPENEO_URL)
login()

# 2. Load Lookup Table
dates_lookup <- read_csv(DIRS$LOOKUP_TABLE, show_col_types = FALSE)

# 3. Start The Big Loop
for (site_name in ALL_SITE_NAMES) {
  for (year in ALL_YEARS) {
    
    # --- Check if file already exists ---
    expected_filename <- paste0(site_name, "_Sen2_", year, ".tif")
    local_path <- file.path(DIRS$SEN2_DIR, expected_filename)
    
    if (file.exists(local_path)) {
      message(paste("⏭️  Skipping", site_name, year, "- File already exists."))
      next
    }
    
    message(paste("\n🚀 Processing OpenEO Job:", site_name, year))
    
    tryCatch({
      # --- A. Preparation ---
      site_abbr <- SITE_ABBREVIATIONS[[site_name]]
      
      # Get Date
      date_row <- dates_lookup %>% filter(`study site` == site_abbr, year == !!year)
      if(nrow(date_row) == 0) stop("Date not found in lookup CSV")
      temporal_date <- as.character(date_row$`date`[1])
      
      # Get Boundary
      shp_name <- paste0("Extent_", str_replace_all(site_name, " ", ""), ".shp") # Adjust logic if specific filenames differ
      shp_path <- file.path(DIRS$EXTENT_SHP_DIR, shp_name)
      
      if(!file.exists(shp_path)) stop(paste("Shapefile not found:", shp_path))
      
      aoi <- st_read(shp_path, quiet = TRUE) %>% st_transform(4326)
      bbox <- st_bbox(aoi)
      
      # --- B. OpenEO Process ---
      p <- processes()
      datacube <- p$load_collection(
        id = "SENTINEL2_L2A",
        spatial_extent = list(west=bbox["xmin"], east=bbox["xmax"], south=bbox["ymin"], north=bbox["ymax"]),
        temporal_extent = c(temporal_date, temporal_date)
      )
      
      # --- C. Run Job ---
      job_title <- paste0("JOB_", site_name, "_", year)
      job <- create_job(graph = datacube, title = job_title, job_options = list(output_format = "GTiff"))
      start_job(job)
      
      message("   Waiting for job to finish...")
      # Note: For a truly parallel workflow, we would start all jobs first, then wait. 
      # Here we wait sequentially to keep logic simple.
      while(status(job) %in% c("created", "queued", "running")) { Sys.sleep(10) }
      
      # --- D. Download ---
      if (status(job) == "finished") {
        temp_dl <- download_results(job, folder = tempdir())
        file.copy(temp_dl[[1]], local_path, overwrite = TRUE)
        message(paste("✅ Downloaded:", expected_filename))
      } else {
        warning(paste("❌ Job failed for", site_name, year))
      }
      
    }, error = function(e) {
      message(paste("❌ Error processing", site_name, year, ":", e$message))
    })
  }
}
