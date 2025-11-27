# ==============================================================================
# 03. Batch Analysis & Mapping (Multi-Model Support)
# ==============================================================================
library(dplyr)
library(ggplot2)
library(terra)
library(rpart)
library(tidyr)
library(scales)

source("source/config.R")
source("source/viz_constants.R") 
source("source/model_utils.R")   # <--- Updated file
source("source/spatial_processing_utils.R")

# 1. Load Models (Logic vs File)
loaded_models <- list()
for (m_name in names(MODELS)) {
  message(paste("Initializing model:", m_name))
  loaded_models[[m_name]] <- load_model_object(m_name, MODELS[[m_name]])
}

for (site_name in ALL_SITE_NAMES) {
  for (year in ALL_YEARS) {
    
    message(paste("\n📊 Analyzing:", site_name, year))
    
    tryCatch({
      # --- Setup Paths ---
      pixel_dir <- file.path(DIRS$PIXEL_DATA_DIR, site_name, year)
      csv_path  <- file.path(pixel_dir, paste0(site_name, "_", year, "_final_pixel_attributes.csv"))
      plot_dir  <- file.path(DIRS$PLOTS_DIR, site_name, year)
      if(!dir.exists(plot_dir)) dir.create(plot_dir, recursive=TRUE)
      
      if (!file.exists(csv_path)) {
        message("   ⏭️ Skipping (Input CSV missing)")
        next
      }
      
      # Load & Standardize Data
      df <- read.csv(csv_path)
      names(df) <- tolower(names(df)) 
      
      # Set Factors
      df$dominant_label   <- factor(df$dominant_label, levels = LABEL_ORDER_PLOT)
      df$mixture_category <- factor(df$mixture_category, levels = PURITY_ORDER_STD)
      
      # --- LOOP THROUGH EACH MODEL ---
      for (model_name in names(loaded_models)) {
        
        current_model_obj <- loaded_models[[model_name]]
        col_pred_name <- paste0("pred_", model_name) # e.g. pred_Jussila, pred_WiW
        
        message(paste("   -> Running Model:", model_name))
        
        # 1. Predict (Using Wrapper)
        df[[col_pred_name]] <- predict_class_wrapper(current_model_obj, df, model_name)
        
        # 2. Confusion Matrix Heatmap
        cm_df <- as.data.frame(table(Reference = df$dominant_label, Prediction = df[[col_pred_name]]))
        cm_df <- cm_df %>% mutate(Category = case_when(
          (Reference == "Inundated" & Prediction == "water") ~ "Correct",
          (Reference == "Not inundated" & Prediction == "dry") ~ "Correct",
          (Reference == "Inundated" & Prediction == "dry") ~ "Incorrect",
          (Reference == "Not inundated" & Prediction == "water") ~ "Incorrect",
          TRUE ~ "Other_Cat"
        ))
        
        p_cm <- ggplot(cm_df, aes(x = Prediction, y = Reference)) +
          geom_tile(aes(fill = Category), color = "black") +
          geom_text(aes(label = comma(Freq)), size = 5) +
          scale_fill_manual(values = JUSSILA_COLORS, guide = "none") +
          theme_jussila() +
          labs(title = paste("Confusion Matrix:", model_name),
               subtitle = paste(site_name, year))
        
        ggsave(file.path(plot_dir, paste0(model_name, "_Confusion_Matrix.png")), p_cm, width = 8, height = 7)
        
        # 3. Metrics Calculation
        eval_df <- df %>% mutate(ref_class = case_when(
          dominant_label == 'Inundated' ~ 'water',
          dominant_label == 'Not inundated'~ 'dry',
          TRUE ~ NA_character_
        )) %>% filter(!is.na(ref_class))
        
        perf_summary <- eval_df %>%
          group_by(mixture_category) %>%
          summarise(
            tp_w = sum(ref_class=="water" & .data[[col_pred_name]]=="water"),
            fp_w = sum(ref_class=="dry"   & .data[[col_pred_name]]=="water"),
            fn_w = sum(ref_class=="water" & .data[[col_pred_name]]=="dry"),
            tp_d = sum(ref_class=="dry"   & .data[[col_pred_name]]=="dry"),
            fp_d = sum(ref_class=="water" & .data[[col_pred_name]]=="dry"),
            fn_d = sum(ref_class=="dry"   & .data[[col_pred_name]]=="water"), 
            .groups = 'drop'
          ) %>%
          mutate(
            recall_water    = tp_w / (tp_w + fn_w),
            precision_water = tp_w / (tp_w + fp_w),
            f1_water        = 2 * (precision_water * recall_water) / (precision_water + recall_water),
            model_name      = model_name
          ) %>%
          mutate(across(where(is.numeric), ~replace_na(., 0)))
        
        # Save Metrics CSV (Specific to Model)
        write.csv(perf_summary, file.path(pixel_dir, paste0(site_name, "_", year, "_metrics_", model_name, ".csv")), row.names=FALSE)
        
        # 4. Trend Plot
        trend_data <- perf_summary %>%
          select(mixture_category, recall_water, precision_water, f1_water) %>%
          pivot_longer(-mixture_category, names_to = "metric", values_to = "score")
        
        trend_data$mixture_category <- factor(trend_data$mixture_category, levels = PURITY_ORDER_STD)
        
        p_trend <- ggplot(trend_data, aes(x = mixture_category, y = score, group = metric, color = metric)) +
          geom_line(linewidth = 1) + geom_point(size = 3) +
          ylim(0, 1) + theme_jussila() +
          labs(title = paste("Performance Trend:", model_name),
               subtitle = paste(site_name, year))
        
        ggsave(file.path(plot_dir, paste0(model_name, "_Performance_Trend.png")), p_trend, width = 10, height = 6)
        
        # 5. Spatial Map
        frac_path <- file.path(DIRS$FRACTIONS_DIR, site_name, year, paste0(site_name, "_", year, "_fractions.tif"))
        if(file.exists(frac_path)) {
          template  <- rast(frac_path)
          pred_rast <- rasterize_attributes(df, col_pred_name, template)
          map_out_dir <- file.path(DIRS$FINAL_MAPS_DIR, site_name, year)
          if(!dir.exists(map_out_dir)) dir.create(map_out_dir, recursive=TRUE)
          writeRaster(pred_rast, file.path(map_out_dir, paste0("Map_", model_name, ".tif")), overwrite=TRUE)
        }
      } # End Loop over Models
      
      # Optional: Save CSV with all predictions added
      write.csv(df, csv_path, row.names=FALSE)
      
    }, error = function(e) {
      message(paste("❌ Error in analysis:", e$message))
    })
  }
}

