# Test Player Predictor Functionality
# This script tests the player prediction system

# Load required libraries
library(shiny)
library(dplyr)
library(nflreadr)

# Source the main app to get access to functions
source("app.R")

# Test individual team player prediction
test_player_prediction <- function(team_a = "KC", team_b = "BUF") {
  cat("Testing player prediction for", team_a, "vs", team_b, "\n")
  cat("=" %||% rep("=", 50), "\n")
  
  # Test player-predictor agent
  cat("1. Testing player-predictor agent...\n")
  player_data <- call_agent("player-predictor", list(
    team_a = team_a, 
    team_b = team_b, 
    week = 12
  ))
  
  cat("Player data structure:\n")
  cat("- Team A players:", nrow(player_data$team_a_players), "\n")
  cat("- Team B players:", nrow(player_data$team_b_players), "\n")
  cat("- Injured players:", nrow(player_data$injured_players), "\n")
  
  # Test player-engineer agent
  cat("\n2. Testing player-engineer agent...\n")
  player_analysis <- call_agent("player-engineer", player_data)
  
  cat("Analysis results:\n")
  cat("- Top performers Team A:", nrow(player_analysis$top_performers_a), "\n")
  cat("- Top performers Team B:", nrow(player_analysis$top_performers_b), "\n")
  
  if (nrow(player_analysis$top_performers_a) > 0) {
    cat("\nTop", team_a, "performers:\n")
    for (i in 1:min(3, nrow(player_analysis$top_performers_a))) {
      player <- player_analysis$top_performers_a[i, ]
      cat(sprintf("  %d. %s (%s) - %s%% TD odds\n", 
                  i, player$player_name, player$position, player$td_probability))
    }
  }
  
  if (nrow(player_analysis$top_performers_b) > 0) {
    cat("\nTop", team_b, "performers:\n")
    for (i in 1:min(3, nrow(player_analysis$top_performers_b))) {
      player <- player_analysis$top_performers_b[i, ]
      cat(sprintf("  %d. %s (%s) - %s%% TD odds\n", 
                  i, player$player_name, player$position, player$td_probability))
    }
  }
  
  cat("\n" %||% rep("=", 50), "\n")
  return(player_analysis)
}

# Test weekly bulk update (smaller subset)
test_weekly_bulk_update <- function(week = 12, season = 2025) {
  cat("Testing weekly bulk update for Week", week, "Season", season, "\n")
  cat("=" %||% rep("=", 50), "\n")
  
  bulk_result <- call_agent("weekly-player-updater", list(
    week = week,
    season = season
  ))
  
  cat("Bulk update results:\n")
  cat("- Status:", bulk_result$status, "\n")
  cat("- Total games processed:", bulk_result$total_games, "\n")
  cat("- Message:", bulk_result$message, "\n")
  
  if (length(bulk_result$predictions_data) > 0) {
    cat("\nSample predictions:\n")
    for (i in 1:min(3, length(bulk_result$predictions_data))) {
      game <- bulk_result$predictions_data[[i]]
      cat(sprintf("  %s vs %s\n", game$home_team, game$away_team))
    }
  }
  
  cat("\n" %||% rep("=", 50), "\n")
  return(bulk_result)
}

# Run tests
if (interactive()) {
  cat("Running Player Predictor Tests\n")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
  
  # Test 1: Individual prediction
  test_result1 <- test_player_prediction("KC", "BUF")
  
  # Test 2: Different teams
  test_result2 <- test_player_prediction("DAL", "PHI")
  
  # Test 3: Weekly bulk (comment out if too slow)
  # test_result3 <- test_weekly_bulk_update(12, 2025)
  
  cat("Tests completed!\n")
}
