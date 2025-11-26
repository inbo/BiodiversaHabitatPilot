# ==============================================================================
# 04. Batch Synthesis Report (Multi-Model Version)
# ==============================================================================
# Aggregates results from all sites/years/models into global summary plots.
# 
# Outputs:
# 1. Global Seasonality Plot (Comparison of Models over time)
# 2. Global Input Data Counts (Reference data distribution)
# 3. Global Confusion Matrix (Side-by-side Model comparison)
# 4. Grand Overall Performance Table (Console Output)

library(dplyr)
library(ggplot2)
library(purrr)
library(readr)
library(stringr)
library(lubridate)
library(tidyr)
library(scales)

# --- Load Project Configuration & Utilities ---
source("source/config.R")
source("source/viz_constants.R")

# Setup Output Directory
synthesis_dir <- file.path(DIRS$OUTPUT, "synthesis_plots")
if(!dir.exists(synthesis_dir)) dir.create(synthesis_dir, recursive=TRUE)

message("\n📈 Starting Synthesis Report...")

# ==============================================================================
# 1. LOAD ALL DATA
# ==============================================================================

# --- A. Load Dates (for Time Series plots) ---
dates_lookup <- read_csv(DIRS$LOOKUP_TABLE, show_col_types = FALSE) %>%
  rename(site_abbr = `study site`, date = `date`) %>%
  mutate(date = as.Date(date), julian_date = yday(date))

# --- B. Harvest Metrics & Pixel Data ---
all_metrics_list <- list()
all_pixels_list  <- list()

for (site in ALL_SITE_NAMES) {
  for (year in ALL_YEARS) {
    
    pixel_dir <- file.path(DIRS$PIXEL_DATA_DIR, site, year)
    pixel_csv_path <- file.path(pixel_dir, paste0(site, "_", year, "_final_pixel_attributes.csv"))
    
    # 1. Load Metrics (Find all model files: e.g., "_metrics_Jussila.csv", "_metrics_WiW.csv")
    metric_files <- list.files(pixel_dir, pattern = "_metrics_.*\\.csv$", full.names = TRUE)
    
    for (f in metric_files) {
      # Extract Model Name from filename (assumes format: ..._metrics_ModelName.csv)
      fname <- basename(f)
      model_name <- str_match(fname, "_metrics_(.*)\\.csv")[,2]
      
      m <- read.csv(f) %>% 
        mutate(study_site = site, year = year, model_name = model_name)
      
      all_metrics_list[[paste(site, year, model_name)]] <- m
    }
    
    # 2. Load Pixels (Load once per site/year)
    if(file.exists(pixel_csv_path)) {
      # Load only necessary columns: Reference + All Prediction columns
      p_raw <- read.csv(pixel_csv_path)
      
      # Select dominant_label, mixture_category, and any column starting with "pred_"
      cols_to_keep <- c("dominant_label", "mixture_category", names(p_raw)[grep("^pred_", names(p_raw))])
      
      p <- p_raw %>% 
        select(all_of(cols_to_keep)) %>%
        mutate(study_site = site, year = year)
      
      all_pixels_list[[paste(site, year)]] <- p
    }
  }
}

# Combine into huge dataframes
full_metrics_df <- bind_rows(all_metrics_list)
full_pixels_df  <- bind_rows(all_pixels_list)

message(paste("   Loaded metrics for:", paste(unique(full_metrics_df$model_name), collapse=", ")))
message(paste("   Loaded", format(nrow(full_pixels_df), big.mark=","), "total pixels."))

# ==============================================================================
# 2. PLOT: Global Seasonality (Model Comparison)
# ==============================================================================
message("   Generating Seasonality Comparison Plots...")

if (nrow(full_metrics_df) > 0) {
  # Join metrics with dates
  plot_data <- full_metrics_df %>%
    filter(mixture_category == "pure") %>%
    mutate(site_abbr = unlist(SITE_ABBREVIATIONS[study_site])) %>%
    left_join(dates_lookup, by = c("site_abbr", "year")) %>%
    filter(!is.na(julian_date)) %>%
    pivot_longer(cols = c(recall_water, precision_water, f1_water), 
                 names_to = "metric", values_to = "value")
  
  # Plot: Facet Grid (Rows = Metric, Cols = Model)
  p_time <- ggplot(plot_data, aes(x = julian_date, y = value, color = study_site)) +
    geom_jitter(size = 3, width = 1.5, height = 0, alpha=0.8) +
    facet_grid(metric ~ model_name) + 
    scale_x_continuous(limits=c(0, 365), breaks=seq(0,365,60)) +
    ylim(0, 1) +
    theme_jussila() +
    labs(title = "Model Comparison: Seasonality (Pure Pixels)",
         subtitle = "Performance metrics vs. Julian Date",
         x = "Day of Year", y = "Score")
  
  ggsave(file.path(synthesis_dir, "1_Global_Seasonality_Comparison.png"), p_time, width = 12, height = 10)
} else {
  warning("No metrics data found. Skipping Seasonality Plot.")
}

# ==============================================================================
# 3. PLOT: Global Input Data Counts (Model Independent)
# ==============================================================================
message("   Generating Global Counts Plot...")

if (nrow(full_pixels_df) > 0) {
  # Apply Factors
  full_pixels_df$dominant_label <- factor(full_pixels_df$dominant_label, levels = LABEL_ORDER_PLOT)
  full_pixels_df$mixture_category <- factor(full_pixels_df$mixture_category, levels = PURITY_ORDER_STD)
  
  plot_counts <- full_pixels_df %>%
    count(dominant_label, mixture_category, name = "count") %>%
    complete(dominant_label, mixture_category, fill=list(count=0))
  
  p_global_counts <- ggplot(plot_counts, aes(y = dominant_label, x = count, fill = dominant_label, alpha = mixture_category)) +
    geom_bar(stat = "identity", position = "stack") +
    scale_fill_manual(values = JUSSILA_COLORS, drop=FALSE) +
    scale_alpha_manual(values = c("pure"=1, "mixed"=0.6, "very_mixed"=0.3), drop=FALSE) +
    scale_x_continuous(labels = comma) +
    theme_jussila() +
    labs(title = "Global Input Data Composition",
         subtitle = "Aggregated counts across all sites and years")
  
  ggsave(file.path(synthesis_dir, "2_Global_Input_Counts.png"), p_global_counts, width = 12, height = 7)
}

# ==============================================================================
# 4. PLOT: Global Confusion Matrix (Model Comparison)
# ==============================================================================
message("   Generating Global Confusion Matrix Comparison...")

if (nrow(full_pixels_df) > 0) {
  # Reshape wide pixel data (pred_Jussila, pred_WiW) to long format (Model, Prediction)
  long_preds <- full_pixels_df %>%
    select(dominant_label, starts_with("pred_")) %>%
    pivot_longer(cols = starts_with("pred_"), names_to = "Model", values_to = "Prediction") %>%
    mutate(Model = gsub("pred_", "", Model))
  
  # Calculate Counts per Model
  cm_global <- long_preds %>%
    count(Model, dominant_label, Prediction) %>%
    rename(Reference = dominant_label, Freq = n)
  
  # Categorize for Heatmap Colors
  cm_global <- cm_global %>% mutate(Category = case_when(
    (Reference == "Inundated" & Prediction == "water") ~ "Correct",
    (Reference == "Not inundated" & Prediction == "dry") ~ "Correct",
    (Reference == "Inundated" & Prediction == "dry") ~ "Incorrect",
    (Reference == "Not inundated" & Prediction == "water") ~ "Incorrect",
    TRUE ~ "Other_Cat"
  ))
  
  # Plot Faceted by Model
  p_global_cm <- ggplot(cm_global, aes(x = Prediction, y = Reference)) +
    geom_tile(aes(fill = Category), color = "black") +
    geom_text(aes(label = comma(Freq)), size = 4) +
    facet_wrap(~Model) + 
    scale_fill_manual(values = JUSSILA_COLORS, guide = "none") +
    theme_jussila() +
    labs(title = "Global Confusion Matrix Comparison")
  
  ggsave(file.path(synthesis_dir, "3_Global_Confusion_Matrix_Comparison.png"), p_global_cm, width = 12, height = 7)
}

# ==============================================================================
# 5. GRAND OVERALL PERFORMANCE TABLE
# ==============================================================================
message("\n--- Calculating Grand Overall Performance (Across all pixels) ---")

if (exists("long_preds")) {
  grand_summary <- long_preds %>%
    # Filter for binary classes
    filter(dominant_label %in% c("Inundated", "Not inundated")) %>%
    mutate(ref_class = if_else(dominant_label == "Inundated", "water", "dry")) %>%
    
    # Group by Model to get stats for each
    group_by(Model) %>%
    summarise(
      tp_w = sum(ref_class=="water" & Prediction=="water"),
      fp_w = sum(ref_class=="dry"   & Prediction=="water"),
      fn_w = sum(ref_class=="water" & Prediction=="dry"),
      tp_d = sum(ref_class=="dry"   & Prediction=="dry"),
      fp_d = sum(ref_class=="water" & Prediction=="dry"),
      fn_d = sum(ref_class=="dry"   & Prediction=="water")
    ) %>%
    mutate(
      recall_water    = tp_w / (tp_w + fn_w),
      precision_water = tp_w / (tp_w + fp_w),
      f1_water        = 2 * (precision_water * recall_water) / (precision_water + recall_water),
      macro_f1        = (f1_water + (2 * (tp_d / (tp_d + fp_d) * tp_d / (tp_d + fn_d)) / (tp_d / (tp_d + fp_d) + tp_d / (tp_d + fn_d)))) / 2
    ) %>%
    select(Model, recall_water, precision_water, f1_water, macro_f1)
  
  print(grand_summary)
  
  # Optional: Save table
  write.csv(grand_summary, file.path(synthesis_dir, "4_Grand_Performance_Summary.csv"), row.names=FALSE)
}

message("\n✅ Synthesis Complete. Check 'output/synthesis_plots'.")

