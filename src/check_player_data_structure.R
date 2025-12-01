# Quick test to check nflreadr player stats column names

library(nflreadr)
library(dplyr)

cat("Testing nflreadr player stats structure...\n")

# Load player stats
player_data <- load_player_stats(seasons = 2024)

cat("Total records:", nrow(player_data), "\n")
cat("Column names:\n")
print(names(player_data))

cat("\nSample of team-related columns:\n")
team_cols <- grep("team", names(player_data), ignore.case = TRUE, value = TRUE)
cat("Team columns found:", paste(team_cols, collapse = ", "), "\n")

if (length(team_cols) > 0) {
  cat("\nSample values from first team column (", team_cols[1], "):\n")
  sample_teams <- unique(player_data[[team_cols[1]]])[1:10]
  cat(paste(sample_teams, collapse = ", "), "\n")
}

cat("\nFirst few player names:\n")
if ("player_name" %in% names(player_data)) {
  sample_players <- unique(player_data$player_name)[1:10]
  cat(paste(sample_players, collapse = ", "), "\n")
} else {
  # Find the player name column
  name_cols <- grep("name|player", names(player_data), ignore.case = TRUE, value = TRUE)
  cat("Name-related columns:", paste(name_cols, collapse = ", "), "\n")
}
