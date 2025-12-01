# Weekly Update Automation Script
# Schedule: Run every Tuesday at 9 AM EST
# Purpose: Automatically update predictions after Monday Night Football

library(shiny)
library(dplyr)
library(nflreadr)

# Source main app functions
source("app.R")

# Run weekly update
run_automated_update <- function() {
  current_week <- get_current_week()
  current_season <- 2025  # Updated to current season
  
  cat("Starting automated weekly update for Week", current_week, "Season", current_season, "\n")
  cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  
  # Run the updater agent
  tryCatch({
    update_result <- call_agent("updater", list(
      week = current_week,
      season = current_season
    ))
    
    if (update_result$status == "success") {
      cat("✓ Update completed successfully\n")
      cat("  - Week:", update_result$week, "\n")
      cat("  - Predictions generated:", update_result$upcoming_predictions, "\n")
      
      if (!is.na(update_result$validation_results$accuracy_rate)) {
        cat("  - Previous week accuracy:", round(update_result$validation_results$accuracy_rate, 1), "%\n")
      }
      
      if (!is.na(update_result$season_accuracy)) {
        cat("  - Season accuracy:", update_result$season_accuracy, "%\n")
      }
      
      # Log performance to file
      log_entry <- data.frame(
        timestamp = Sys.time(),
        week = update_result$week,
        season = update_result$season,
        status = "success",
        predictions_generated = update_result$upcoming_predictions,
        accuracy = update_result$validation_results$accuracy_rate %||% NA,
        season_accuracy = update_result$season_accuracy %||% NA,
        stringsAsFactors = FALSE
      )
      
      # Append to log file
      log_file <- "data/update_automation_log.csv"
      if (file.exists(log_file)) {
        existing_log <- read.csv(log_file, stringsAsFactors = FALSE)
        updated_log <- rbind(existing_log, log_entry)
      } else {
        updated_log <- log_entry
      }
      write.csv(updated_log, log_file, row.names = FALSE)
      
    } else {
      cat("✗ Update failed:", update_result$message, "\n")
    }
    
  }, error = function(e) {
    cat("✗ Error during automated update:", e$message, "\n")
  })
  
  cat("Automated update completed at", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("=" %||% rep("=", 50), "\n")
}

# Manual execution
if (interactive()) {
  cat("Running manual weekly update...\n")
  run_automated_update()
} else {
  # Scheduled execution
  run_automated_update()
}
