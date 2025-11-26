# ==============================================================================
# UTILITIES: Jussila Model Handling
# ==============================================================================
# This script centralizes the loading and application of the decision tree model.

library(rpart)
library(dplyr)

# 1. LOAD MODEL
load_model_object <- function(model_name, model_path) {
  
  if (model_name == "WiW") {
    # WiW doesn't need a file loaded, it's just logic.
    # Return a dummy object or string to signal this.
    return("WiW_Logic")
    
  } else {
    # For Jussila (or other RData models)
    if (!file.exists(model_path)) stop(paste("Model file not found:", model_path))
    
    e <- new.env()
    load(model_path, envir = e)
    
    # Assume object is named 'tree_jussila' based on previous scripts
    if(exists("tree_jussila", envir=e)) return(e$tree_jussila)
    
    stop("Loaded .RData but could not find 'tree_jussila' object.")
  }
}

# 2. PREDICT WRAPPER
predict_class_wrapper <- function(model_obj, data, model_name) {
  
  if (model_name == "WiW") {
    # --- WiW Logic Implementation ---
    # Rule: Water if (B8A <= 0.1804 AND B12 <= 0.1131)
    
    # Check required columns (lowercase assumed due to standardization step)
    if (!all(c("b8a_scaled", "b12_scaled") %in% names(data))) {
      stop("WiW requires 'b8a_scaled' and 'b12_scaled' columns.")
    }
    
    preds <- ifelse(
      data$b8a_scaled <= 0.1804 & data$b12_scaled <= 0.1131,
      "water",
      "dry"
    )
    return(preds)
    
  } else {
    # --- Jussila (Decision Tree) Logic ---
    # Check predictors
    required_vars <- attr(model_obj$terms, "term.labels")
    missing <- setdiff(required_vars, names(data))
    if(length(missing) > 0) stop(paste("Missing vars for Jussila:", paste(missing, collapse=", ")))
    
    return(predict(model_obj, newdata = data, type = "class"))
  }
}