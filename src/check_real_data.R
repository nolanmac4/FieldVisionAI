# Quick test to see available teams and players
library(nflreadr)
library(dplyr)

cat("Loading real NFL player data...\n")

# Load player stats
player_stats <- load_player_stats(seasons = c(2023, 2024))

cat("Total player records:", nrow(player_stats), "\n")
cat("Seasons:", paste(unique(player_stats$season), collapse = ", "), "\n")

# Show all available teams
available_teams <- sort(unique(player_stats$recent_team))
cat("\nAvailable teams in player data:\n")
cat(paste(available_teams, collapse = ", "), "\n")

# Test specific teams
test_teams <- c("KC", "BUF", "DAL", "PHI")
cat("\nTesting sample teams:\n")

for (team in test_teams) {
  team_players <- player_stats %>%
    filter(recent_team == team) %>%
    filter(season >= 2023) %>%
    distinct(player_name, position) %>%
    arrange(position, player_name)
  
  cat("\n", team, "- Total unique players:", nrow(team_players), "\n")
  if (nrow(team_players) > 0) {
    cat("Sample players:\n")
    sample_players <- head(team_players, 5)
    for (i in 1:nrow(sample_players)) {
      cat("  ", sample_players$player_name[i], "(", sample_players$position[i], ")\n")
    }
  }
}
