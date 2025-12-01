# Weekly Updater Functions
# Data storage and retrieval functions for the updater agent

library(dplyr)
library(readr)
library(lubridate)

# Create directories if they don't exist - EXPORTED FUNCTION
create_data_dirs <- function() {
  dirs <- c("data", "data/predictions", "data/performance")
  for (dir in dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
    }
  }
}

# Make function available globally
assign("create_data_dirs", create_data_dirs, envir = .GlobalEnv)

# Get current NFL week
get_current_week <- function() {
  # Simple approximation - can be refined with actual NFL calendar
  start_date <- as.Date("2024-09-05")  # Approximate NFL season start
  current_date <- Sys.Date()
  week_diff <- as.numeric(difftime(current_date, start_date, units = "weeks"))
  return(max(1, min(18, floor(week_diff) + 1)))
}

# Store weekly predictions
store_predictions <- function(predictions, week, season = 2024) {
  predictions_df <- data.frame(
    week = week,
    season = season,
    team_a = predictions$team_a,
    team_b = predictions$team_b,
    predicted_winner = predictions$winner,
    win_prob_a = predictions$prob_a,
    win_prob_b = predictions$prob_b,
    expected_margin = predictions$margin,
    favored_team = predictions$favored_team,
    confidence = predictions$confidence,
    prediction_date = Sys.Date(),
    stringsAsFactors = FALSE
  )
  
  filename <- paste0("data/predictions/week_", week, "_", season, "_predictions.csv")
  write_csv(predictions_df, filename)
  return(filename)
}

# Load previous predictions for validation
load_previous_predictions <- function(week, season = 2024) {
  filename <- paste0("data/predictions/week_", week, "_", season, "_predictions.csv")
  if (file.exists(filename)) {
    return(read_csv(filename, show_col_types = FALSE))
  }
  return(NULL)
}

# Store performance metrics
store_performance_metrics <- function(metrics, week, season = 2024) {
  metrics_df <- data.frame(
    week = week,
    season = season,
    accuracy_rate = metrics$accuracy_rate,
    avg_margin_error = metrics$avg_margin_error,
    confidence_calibration = metrics$confidence_calibration,
    total_predictions = metrics$total_predictions,
    correct_predictions = metrics$correct_predictions,
    update_date = Sys.Date(),
    stringsAsFactors = FALSE
  )
  
  filename <- paste0("data/performance/week_", week, "_", season, "_performance.csv")
  write_csv(metrics_df, filename)
  return(filename)
}

# Load historical performance
load_performance_history <- function(season = 2024) {
  files <- list.files("data/performance", pattern = paste0("_", season, "_performance.csv"), full.names = TRUE)
  if (length(files) > 0) {
    all_metrics <- lapply(files, read_csv, show_col_types = FALSE)
    return(bind_rows(all_metrics))
  }
  return(NULL)
}

# Get upcoming games for the week
get_upcoming_games <- function(week, season = 2024) {
  tryCatch({
    games <- nflreadr::load_schedules(seasons = season)
    upcoming <- games %>%
      filter(week == !!week, season == !!season, is.na(result)) %>%
      select(week, season, gameday, home_team, away_team)
    return(upcoming)
  }, error = function(e) {
    return(data.frame())
  })
}

# Validate predictions against actual results
validate_predictions <- function(predictions, week, season = 2024) {
  tryCatch({
    games <- nflreadr::load_schedules(seasons = season)
    completed_games <- games %>%
      filter(week == !!week, season == !!season, !is.na(result)) %>%
      select(week, season, home_team, away_team, home_score, away_score, result)
    
    if (nrow(completed_games) == 0) {
      return(list(accuracy_rate = NA, avg_margin_error = NA, total_predictions = 0))
    }
    
    # Match predictions with results
    validation_results <- c()
    margin_errors <- c()
    
    for (i in 1:nrow(predictions)) {
      pred <- predictions[i, ]
      
      # Find matching game
      game_result <- completed_games %>%
        filter((home_team == pred$team_a & away_team == pred$team_b) |
               (home_team == pred$team_b & away_team == pred$team_a))
      
      if (nrow(game_result) == 1) {
        game <- game_result[1, ]
        
        # Determine actual winner
        actual_winner <- if (game$home_score > game$away_score) game$home_team else game$away_team
        
        # Check if prediction was correct
        prediction_correct <- (pred$predicted_winner == actual_winner)
        validation_results <- c(validation_results, prediction_correct)
        
        # Calculate margin error
        actual_margin <- abs(game$home_score - game$away_score)
        predicted_margin <- pred$expected_margin
        margin_error <- abs(actual_margin - predicted_margin)
        margin_errors <- c(margin_errors, margin_error)
      }
    }
    
    accuracy_rate <- if (length(validation_results) > 0) mean(validation_results) * 100 else 0
    avg_margin_error <- if (length(margin_errors) > 0) mean(margin_errors) else 0
    confidence_calibration <- if (length(validation_results) > 0) {
      # Simple calibration: compare average confidence to accuracy
      avg_confidence <- mean(predictions$confidence, na.rm = TRUE)
      abs(avg_confidence - accuracy_rate)
    } else 0
    
    return(list(
      accuracy_rate = accuracy_rate,
      avg_margin_error = avg_margin_error,
      confidence_calibration = confidence_calibration,
      total_predictions = nrow(predictions),
      correct_predictions = sum(validation_results)
    ))
    
  }, error = function(e) {
    return(list(accuracy_rate = NA, avg_margin_error = NA, total_predictions = 0))
  })
}
