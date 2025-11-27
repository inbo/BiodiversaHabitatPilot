# ==============================================================================
# UTILITIES: Visualization Constants & Themes
# ==============================================================================
# This script centralizes color palettes, factor orders, and plot themes 
# to ensure consistency across all analysis and synthesis plots.

library(ggplot2)
library(grDevices)

# ==============================================================================
# 1. COLOR PALETTES
# ==============================================================================

# Main categorical colors for Land Cover classes
JUSSILA_COLORS <- c(
  "Inundated"     = "#4cd2de",
  "Not inundated" = "#dc5199",
  "Other"         = "#86eb79",
  "Uncertain"     = "#ff7f00",
  "Reed"          = "#c49c02",
  
  # Binary classes (used in performance metric plots)
  "water"         = "#4cd2de",
  "dry"           = "#dc5199",
  
  # Confusion Matrix Categories
  "Correct"       = "#22c55e",
  "Incorrect"     = "#ef4444",
  "Other_Cat"     = "white"
)

# ==============================================================================
# 2. FACTOR ORDERS (For Plotting)
# ==============================================================================
# These match the 'rev()' logic used in your original scripts to ensure
# stacked bars and axes appear in the desired visual order.

# Order for Dominant Label (Inundated at top/bottom depending on coord_flip)
LABEL_ORDER_PLOT <- rev(c('Inundated', 'Not inundated', 'Other', 'Reed', 'Uncertain'))

# Order for Mixture Category (Pure vs Mixed)
PURITY_ORDER_PLOT <- rev(c("pure", "mixed", "very_mixed"))

# Standard Purity Order (for standard text tables)
PURITY_ORDER_STD <- c("pure", "mixed", "very_mixed")


# ==============================================================================
# 3. HELPER FUNCTIONS
# ==============================================================================

#' Lighten a color
#' @param color Hex string
#' @param amount Numeric 0-1
lighten_color <- function(color, amount = 0.3) {
  if (amount < 0 || amount > 1) stop("Amount must be between 0 and 1.")
  rgb <- grDevices::col2rgb(color)
  hsv <- grDevices::rgb2hsv(rgb)
  hsv["v",] <- pmin(1, hsv["v",] + amount) # Increase V, cap at 1
  return(grDevices::hsv(hsv["h",], hsv["s",], hsv["v",]))
}

#' Darken a color
#' @param color Hex string
#' @param amount Numeric 0-1
darken_color <- function(color, amount = 0.3) {
  if (amount < 0 || amount > 1) stop("Amount must be between 0 and 1.")
  rgb <- grDevices::col2rgb(color)
  hsv <- grDevices::rgb2hsv(rgb)
  hsv["v",] <- pmax(0, hsv["v",] - amount) # Decrease V, cap at 0
  return(grDevices::hsv(hsv["h",], hsv["s",], hsv["v",]))
}

# ==============================================================================
# 4. STANDARD THEME
# ==============================================================================

#' Standard Project Theme
#' Applies theme_bw with centered titles and bottom legends
theme_jussila <- function(base_size = 14) {
  theme_bw(base_size = base_size) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5),
      legend.position = "bottom",
      legend.box = "vertical",
      strip.background = element_rect(fill = "grey95")
    )
}