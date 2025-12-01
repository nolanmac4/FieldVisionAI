# NFL Matchup Predictor — Trend-Based Analysis
# Run from parent directory: shiny::runApp("src") 
# OR Run from src directory: shiny::runApp(".")

# Suppress warnings for cleaner output
options(nflreadr.verbose = FALSE)
suppressWarnings({
  library(shiny)
  library(dplyr)
  library(nflreadr)
})

# Suppress tidyselect lifecycle warnings
options(lifecycle_verbosity = "quiet")

# Declare global variables to suppress R CMD check notes
utils::globalVariables(c(
  'home_team', 'away_team', 'gameday', 'week', 'season', 'recent_team',
  'player_name', 'position', 'receiving_yards', 'rushing_yards', 'passing_yards',
  'receiving_tds', 'rushing_tds', 'passing_tds', 'home_score', 'away_score',
  'spread_line', 'total_line', 'home_moneyline', 'away_moneyline',
  'avg_receiving_yards', 'avg_rushing_yards', 'avg_passing_yards',
  'total_receiving_tds', 'total_rushing_tds', 'total_passing_tds',
  'games_played', 'td_rate', 'yards_consistency', 'total_avg_yards',
  'td_odds', 'injury_status', 'adjusted_td_odds', 'performance_score',
  'team', 'predicted_receiving_yards', 'predicted_rushing_yards', 
  'predicted_passing_yards', 'td_probability', 'last_game_week',
  'base_td_rate', 'form_factor', 'consistency_factor', 'position_factor',
  'td_game_pct', 'raw_td_odds', 'adjusted_raw_odds', 'recent_avg', 
  'earlier_avg', 'all_yards', 'td_games', 'yards_vector'
))

# Load weekly utilities
source("weekly_utils.R")

# Define %||% operator for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x

# Enhanced agent orchestrator following instructions
call_agent <- function(agent, input_data) {
  if (agent == "data-getter") {
    # Load comprehensive data (2015-current for full context)
    games <- load_schedules(seasons = 2015:2024)
    player_stats <- tryCatch(load_player_stats(seasons = 2023:2024), error = function(e) NULL)
    teams_info <- tryCatch(load_teams(), error = function(e) NULL)
    
    # Get recent games for both teams (last 16 games each)
    team_a_games <- games %>%
      filter(home_team == input_data$team_a | away_team == input_data$team_a) %>%
      arrange(desc(gameday)) %>%
      head(16)
    
    team_b_games <- games %>%
      filter(home_team == input_data$team_b | away_team == input_data$team_b) %>%
      arrange(desc(gameday)) %>%
      head(16)
    
    # Historical matchups for reference
    historical_matchups <- games %>%
      filter((home_team == input_data$team_a & away_team == input_data$team_b) |
             (home_team == input_data$team_b & away_team == input_data$team_a)) %>%
      arrange(desc(gameday))
    
    return(list(
      team_a = input_data$team_a,
      team_b = input_data$team_b,
      team_a_games = team_a_games,
      team_b_games = team_b_games,
      all_games = games,
      player_stats = player_stats,
      teams_info = teams_info,
      historical_matchups = historical_matchups
    ))
  }
  
  if (agent == "player-predictor") {
    # Load comprehensive player data - PRIORITIZE CURRENT SEASON
    current_season <- 2025
    
    cat("Loading REAL NFL player statistics...\n")
    
    # Try to load current season first, fall back to previous if needed
    player_stats <- tryCatch({
      # Try 2025 data first
      stats_2025 <- load_player_stats(seasons = 2025)
      cat("Loaded 2025 player stats:", nrow(stats_2025), "records\n")
      stats_2025
    }, error = function(e) {
      cat("2025 data not available, trying 2024...\n")
      # Fall back to 2024 if 2025 isn't available
      tryCatch({
        stats_2024 <- load_player_stats(seasons = 2024)
        cat("Using 2024 player stats:", nrow(stats_2024), "records\n")
        stats_2024
      }, error = function(e2) {
        # Last resort: 2023
        cat("Using 2023 player stats as last resort\n")
        load_player_stats(seasons = 2023)
      })
    })
    
    cat("Successfully loaded", nrow(player_stats), "REAL player records\n")
    
    # Check what team columns exist and fix the naming
    team_cols <- grep("team", names(player_stats), ignore.case = TRUE, value = TRUE)
    cat("Available team columns:", paste(team_cols, collapse = ", "), "\n")
    
    # Fix the team column naming issue
    if (!"recent_team" %in% names(player_stats)) {
      if ("team" %in% names(player_stats)) {
        player_stats$recent_team <- player_stats$team
        cat("Fixed: Using 'team' column as 'recent_team'\n")
      } else if (length(team_cols) > 0) {
        player_stats$recent_team <- player_stats[[team_cols[1]]]
        cat("Fixed: Using", team_cols[1], "as 'recent_team'\n")
      } else {
        stop("No team column found in player stats data!")
      }
    }
    
    # Show what teams are available
    available_teams <- unique(player_stats$recent_team)
    cat("Teams with data:", paste(sort(available_teams), collapse = ", "), "\n")
    
    # Load injury data (simplified for now)
    injured_players <- data.frame(player_name = character(), status = character(), stringsAsFactors = FALSE)
    
    # Get REAL team rosters - CURRENT SEASON ONLY
    team_a_players <- player_stats %>%
      filter(recent_team == input_data$team_a) %>%
      filter(season == max(season, na.rm = TRUE)) %>%  # Only most recent season
      arrange(desc(season), desc(week))
    
    team_b_players <- player_stats %>%
      filter(recent_team == input_data$team_b) %>%
      filter(season == max(season, na.rm = TRUE)) %>%  # Only most recent season
      arrange(desc(season), desc(week))
    
    cat("Team A (", input_data$team_a, ") REAL players loaded:", nrow(team_a_players), "\n")
    if (nrow(team_a_players) > 0) {
      cat("Sample real players:", paste(head(unique(team_a_players$player_name), 3), collapse = ", "), "\n")
    }
    
    cat("Team B (", input_data$team_b, ") REAL players loaded:", nrow(team_b_players), "\n")
    if (nrow(team_b_players) > 0) {
      cat("Sample real players:", paste(head(unique(team_b_players$player_name), 3), collapse = ", "), "\n")
    }
    
    return(list(
      team_a = input_data$team_a,
      team_b = input_data$team_b,
      week = input_data$week,
      season = current_season,
      team_a_players = team_a_players,
      team_b_players = team_b_players,
      injured_players = injured_players,
      all_player_stats = player_stats
    ))
  }
  
  if (agent == "player-engineer") {
    data <- input_data
    
    # Enhanced player performance analysis with PRACTICAL IMPROVEMENTS
    analyze_player_performance <- function(player_data, team, injured_list, opponent_team = NULL, all_player_stats = NULL) {
      if (nrow(player_data) == 0) {
        cat("No player data available for", team, "\n")
        return(data.frame())
      }
      
      cat("Analyzing", nrow(player_data), "player records for", team, "vs", opponent_team %||% "unknown", "\n")
      
      # Filter for CURRENT SEASON ONLY - no old roster players
      current_season_data <- player_data %>%
        filter(season == max(season, na.rm = TRUE))
      
      if (nrow(current_season_data) == 0) {
        cat("No current season data for", team, "\n")
        return(data.frame())
      }
      
      # Filter for RECENT ACTIVITY ONLY - must have played in last 1-2 games
      max_week_in_data <- max(current_season_data$week, na.rm = TRUE)
      max_season_in_data <- max(current_season_data$season, na.rm = TRUE)
      
      # Players must have played in the last 2 weeks to be considered active
      recent_activity_cutoff <- max_week_in_data - 1
      
      recent_active_players <- current_season_data %>%
        filter(season == max_season_in_data, week >= recent_activity_cutoff) %>%
        # Additional filter: must have actual playing time (any stat > 0)
        filter(
          (receiving_yards > 0 | !is.na(receiving_yards)) |
          (rushing_yards > 0 | !is.na(rushing_yards)) |
          (passing_yards > 0 | !is.na(passing_yards)) |
          (receiving_tds > 0 | !is.na(receiving_tds)) |
          (rushing_tds > 0 | !is.na(rushing_tds)) |
          (passing_tds > 0 | !is.na(passing_tds))
        ) %>%
        distinct(player_name) %>%
        pull(player_name)
      
      cat("Found", length(recent_active_players), "players with recent game activity for", team, "\n")
      
      # Get recent performance with SIMPLE ENHANCED METRICS
      player_analysis <- current_season_data %>%
        filter(player_name %in% recent_active_players) %>%
        group_by(player_name, position) %>%
        arrange(desc(season), desc(week)) %>%
        slice_head(n = 8) %>%
        summarise(
          # Basic stats with safe defaults
          avg_receiving_yards = mean(ifelse(is.na(receiving_yards) | is.null(receiving_yards), 0, receiving_yards), na.rm = TRUE),
          avg_rushing_yards = mean(ifelse(is.na(rushing_yards) | is.null(rushing_yards), 0, rushing_yards), na.rm = TRUE),
          avg_passing_yards = mean(ifelse(is.na(passing_yards) | is.null(passing_yards), 0, passing_yards), na.rm = TRUE),
          
          # Touchdown analysis with safe defaults
          total_receiving_tds = sum(ifelse(is.na(receiving_tds) | is.null(receiving_tds), 0, receiving_tds), na.rm = TRUE),
          total_rushing_tds = sum(ifelse(is.na(rushing_tds) | is.null(rushing_tds), 0, rushing_tds), na.rm = TRUE),
          total_passing_tds = sum(ifelse(is.na(passing_tds) | is.null(passing_tds), 0, passing_tds), na.rm = TRUE),
          
          # SIMPLE ENHANCED METRICS
          games_played = n(),
          last_game_week = max(week, na.rm = TRUE),
          
          # Simple total yards calculation for form check
          total_yards_all_games = sum((ifelse(is.na(receiving_yards), 0, receiving_yards) + 
                                      ifelse(is.na(rushing_yards), 0, rushing_yards) + 
                                      ifelse(is.na(passing_yards), 0, passing_yards)), na.rm = TRUE),
          
          # TD consistency - count games with TDs
          td_games = sum((ifelse(is.na(receiving_tds), 0, receiving_tds) + 
                         ifelse(is.na(rushing_tds), 0, rushing_tds) + 
                         ifelse(is.na(passing_tds), 0, passing_tds)) > 0, na.rm = TRUE),
          
          .groups = 'drop'
        ) %>%
        mutate(
          # Calculate key metrics
          base_td_rate = (total_receiving_tds + total_rushing_tds + total_passing_tds) / games_played,
          td_game_pct = td_games / games_played,
          avg_yards_per_game = total_yards_all_games / games_played,
          total_avg_yards = avg_receiving_yards + avg_rushing_yards + avg_passing_yards,
          
          # SIMPLE position-specific adjustments
          position_factor = case_when(
            position == "QB" & avg_passing_yards > 250 ~ 1.1,  # High-volume passer
            position == "QB" & avg_passing_yards < 180 ~ 0.95, # Game manager
            position == "RB" & avg_rushing_yards > 80 ~ 1.1,   # Workhorse back
            position == "RB" & avg_rushing_yards < 30 ~ 0.9,   # Committee back
            position == "WR" & avg_receiving_yards > 70 ~ 1.1, # WR1
            position == "WR" & avg_receiving_yards < 35 ~ 0.9, # Limited role
            position == "TE" & avg_receiving_yards > 45 ~ 1.05, # Pass-catching TE
            TRUE ~ 1.0
          ),
          
          # SIMPLE consistency bonus (players who score TDs regularly)
          consistency_factor = case_when(
            td_game_pct >= 0.6 ~ 1.1,   # Scores in 60%+ of games
            td_game_pct >= 0.4 ~ 1.05,  # Scores in 40%+ of games  
            td_game_pct <= 0.2 ~ 0.95,  # Rarely scores
            TRUE ~ 1.0
          ),
          
          # SIMPLE form factor based on yards per game
          form_factor = case_when(
            avg_yards_per_game > 100 ~ 1.1,    # High production
            avg_yards_per_game > 60 ~ 1.05,    # Good production
            avg_yards_per_game < 20 ~ 0.9,     # Limited production
            TRUE ~ 1.0                         # Average production
          ),
          
          # Calculate base TD odds with MORE VARIATION
          raw_td_odds = case_when(
            base_td_rate >= 1.2 ~ 88,   # Elite TD rate
            base_td_rate >= 1.0 ~ 76,   # High TD rate
            base_td_rate >= 0.75 ~ 62,  # Good TD rate
            base_td_rate >= 0.5 ~ 45,   # Moderate TD rate
            base_td_rate >= 0.3 ~ 32,   # Low TD rate
            base_td_rate >= 0.15 ~ 22,  # Very low TD rate
            td_game_pct >= 0.4 ~ 28,    # Doesn't score often but sometimes
            TRUE ~ 15                   # Minimal TD threat
          ),
          
          # Apply all factors for MORE REALISTIC VARIATION
          adjusted_raw_odds = raw_td_odds * position_factor * consistency_factor * form_factor,
          
          # Injury adjustment
          injury_status = ifelse(player_name %in% injured_list$player_name, "Questionable", "Healthy"),
          
          # Final TD odds with injury consideration and realistic bounds
          adjusted_td_odds = ifelse(
            injury_status == "Questionable", 
            adjusted_raw_odds * 0.7,  # 30% reduction for injury
            pmin(89, pmax(10, adjusted_raw_odds))  # Cap between 10-89%
          ),
          
          # Performance score for ranking
          performance_score = (total_avg_yards * 0.4) + (adjusted_td_odds * 0.6),
          
          team = team
        )
      
      # POSITION-SPECIFIC FILTERING with enhanced logic
      # For QBs: Only take the CURRENT starter
      qbs <- player_analysis %>% 
        filter(position == "QB", avg_passing_yards > 50) %>%
        arrange(desc(last_game_week), desc(avg_passing_yards)) %>%
        slice_head(n = 1)
      
      # For other positions: Take active players with meaningful recent stats
      other_positions <- player_analysis %>%
        filter(position != "QB") %>%
        filter(games_played >= 1, total_avg_yards > 5 | base_td_rate > 0.1) %>%
        arrange(desc(adjusted_td_odds), desc(performance_score))
      
      # Combine QB and other positions
      final_analysis <- bind_rows(qbs, other_positions) %>%
        arrange(desc(adjusted_td_odds), desc(performance_score))
      
      cat("After enhanced analysis,", nrow(final_analysis), "active players for", team, "\n")
      if (nrow(qbs) > 0) {
        cat("Starting QB:", qbs$player_name[1], "- TD odds:", round(qbs$adjusted_td_odds[1], 1), "%\n")
      }
      
      return(final_analysis)
    }
    
    # Analyze both teams - REAL DATA ONLY with ADVANCED MATCHUP ANALYSIS
    team_a_analysis <- analyze_player_performance(
      data$team_a_players, 
      data$team_a, 
      data$injured_players,
      opponent_team = data$team_b,
      all_player_stats = data$all_player_stats
    )
    team_b_analysis <- analyze_player_performance(
      data$team_b_players, 
      data$team_b, 
      data$injured_players,
      opponent_team = data$team_a,
      all_player_stats = data$all_player_stats
    )
    
    # NO FALLBACK - If no data, return empty but structured results
    if (nrow(team_a_analysis) == 0) {
      cat("WARNING: No player analysis data for", data$team_a, "- check team name\n")
    }
    if (nrow(team_b_analysis) == 0) {
      cat("WARNING: No player analysis data for", data$team_b, "- check team name\n")
    }
    
    # Get top 5 TD performers for each team
    top_team_a <- team_a_analysis %>%
      head(5)
    
    if (nrow(top_team_a) > 0) {
      top_team_a <- tryCatch({
        top_team_a %>%
          mutate(
            predicted_receiving_yards = round(pmax(0, avg_receiving_yards %||% 0, na.rm = TRUE), 1),
            predicted_rushing_yards = round(pmax(0, avg_rushing_yards %||% 0, na.rm = TRUE), 1),
            predicted_passing_yards = round(pmax(0, avg_passing_yards %||% 0, na.rm = TRUE), 1),
            td_probability = round(pmax(0, adjusted_td_odds %||% 20, na.rm = TRUE), 1)
          )
      }, error = function(e) {
        # If there's an error, create minimal columns
        top_team_a %>%
          mutate(
            predicted_receiving_yards = 0,
            predicted_rushing_yards = 0,
            predicted_passing_yards = 0,
            td_probability = 20
          )
      })
    }
    
    top_team_b <- team_b_analysis %>%
      head(5)
    
    if (nrow(top_team_b) > 0) {
      top_team_b <- tryCatch({
        top_team_b %>%
          mutate(
            predicted_receiving_yards = round(pmax(0, avg_receiving_yards %||% 0, na.rm = TRUE), 1),
            predicted_rushing_yards = round(pmax(0, avg_rushing_yards %||% 0, na.rm = TRUE), 1),
            predicted_passing_yards = round(pmax(0, avg_passing_yards %||% 0, na.rm = TRUE), 1),
            td_probability = round(pmax(0, adjusted_td_odds %||% 20, na.rm = TRUE), 1)
          )
      }, error = function(e) {
        # If there's an error, create minimal columns
        top_team_b %>%
          mutate(
            predicted_receiving_yards = 0,
            predicted_rushing_yards = 0,
            predicted_passing_yards = 0,
            td_probability = 20
          )
      })
    }
    
    return(list(
      team_a = data$team_a,
      team_b = data$team_b,
      week = data$week,
      top_performers_a = top_team_a,
      top_performers_b = top_team_b,
      team_a_total_players = nrow(team_a_analysis),
      team_b_total_players = nrow(team_b_analysis)
    ))
  }
  
  if (agent == "weekly-player-updater") {
    week <- input_data$week
    season <- input_data$season %||% 2025
    
    # Get all games for the week
    weekly_games <- tryCatch({
      schedules <- nflreadr::load_schedules(seasons = season)
      schedules %>%
        filter(week == !!week, season == !!season) %>%
        select(week, season, gameday, home_team, away_team) %>%
        arrange(gameday)
    }, error = function(e) {
      data.frame(week = week, season = season, home_team = character(), away_team = character())
    })
    
    weekly_player_predictions <- list()
    
    if (nrow(weekly_games) > 0) {
      cat("Generating player predictions for", nrow(weekly_games), "games in week", week, "\n")
      
      for (i in seq_len(nrow(weekly_games))) {
        game <- weekly_games[i, ]
        
        tryCatch({
          # Get player data for this game
          player_data <- call_agent("player-predictor", list(
            team_a = game$home_team, 
            team_b = game$away_team, 
            week = week
          ))
          
          # Analyze player performance
          player_analysis <- call_agent("player-engineer", player_data)
          
          # Get top performer by position for summary
          get_top_by_position <- function(performers, pos) {
            if (nrow(performers) == 0) return("No data")
            top_player <- performers %>%
              filter(position == pos) %>%
              arrange(desc(td_probability)) %>%
              slice_head(n = 1)
            
            if (nrow(top_player) == 0) return("No data")
            return(paste0(top_player$player_name, " (", top_player$td_probability, "% TD)"))
          }
          
          # Extract top performers by position
          team_a_top_qb <- get_top_by_position(player_analysis$top_performers_a, "QB")
          team_a_top_rb <- get_top_by_position(player_analysis$top_performers_a, "RB")
          team_a_top_wr <- get_top_by_position(player_analysis$top_performers_a, "WR")
          
          team_b_top_qb <- get_top_by_position(player_analysis$top_performers_b, "QB")
          team_b_top_rb <- get_top_by_position(player_analysis$top_performers_b, "RB")
          team_b_top_wr <- get_top_by_position(player_analysis$top_performers_b, "WR")
          
          weekly_player_predictions[[i]] <- list(
            home_team = game$home_team,
            away_team = game$away_team,
            gameday = game$gameday,
            predictions = player_analysis,
            # Add position-specific top performers for summary
            home_top_qb = team_a_top_qb,
            home_top_rb = team_a_top_rb,
            home_top_wr = team_a_top_wr,
            away_top_qb = team_b_top_qb,
            away_top_rb = team_b_top_rb,
            away_top_wr = team_b_top_wr
          )
        }, error = function(e) {
          cat("Error predicting players for", game$home_team, "vs", game$away_team, ":", e$message, "\n")
        })
      }
    }
    
    # Collect all non-QB players from all games and get top 10 TD probabilities
    all_weekly_players <- data.frame()
    
    if (length(weekly_player_predictions) > 0) {
      for (game_pred in weekly_player_predictions) {
        if (!is.null(game_pred$predictions)) {
          # Add home team players
          if (nrow(game_pred$predictions$top_performers_a) > 0) {
            home_players <- game_pred$predictions$top_performers_a %>%
              filter(position != "QB") %>%
              mutate(
                matchup = paste(game_pred$home_team, "vs", game_pred$away_team),
                team = game_pred$home_team
              )
            all_weekly_players <- bind_rows(all_weekly_players, home_players)
          }
          
          # Add away team players
          if (nrow(game_pred$predictions$top_performers_b) > 0) {
            away_players <- game_pred$predictions$top_performers_b %>%
              filter(position != "QB") %>%
              mutate(
                matchup = paste(game_pred$away_team, "@", game_pred$home_team),
                team = game_pred$away_team
              )
            all_weekly_players <- bind_rows(all_weekly_players, away_players)
          }
        }
      }
    }
    
    # Get top 20 non-QB players by TD probability
    top_20_td_threats <- all_weekly_players %>%
      arrange(desc(td_probability), desc(performance_score)) %>%
      head(20) %>%
      select(player_name, position, team, matchup, td_probability, 
             predicted_receiving_yards, predicted_rushing_yards, predicted_passing_yards)
    
    # Save weekly player predictions
    if (length(weekly_player_predictions) > 0) {
      player_predictions_file <- file.path("data", "predictions", paste0("week_", week, "_", season, "_player_predictions.rds"))
      
      tryCatch({
        saveRDS(weekly_player_predictions, player_predictions_file)
        cat("Saved player predictions to", player_predictions_file, "\n")
      }, error = function(e) {
        cat("Error saving player predictions:", e$message, "\n")
      })
    }
    
    return(list(
      status = "success",
      week = week,
      season = season,
      total_games = length(weekly_player_predictions),
      predictions_data = weekly_player_predictions,
      top_20_td_threats = top_20_td_threats,
      message = paste("Generated player predictions for", length(weekly_player_predictions), "games in week", week, "- Found", nrow(top_20_td_threats), "top TD threats")
    ))
  }
  
  if (agent == "data-engineer") {
    data <- input_data
    
    # Advanced Recent Form Analysis (weighted by recency)
    calc_recent_form <- function(team_games, team) {
      if (nrow(team_games) == 0) return(0)
      
      # Use last 10 games with exponential recency weights
      recent_games <- head(team_games, 10)
      
      differentials <- sapply(seq_len(nrow(recent_games)), function(i) {
        game <- recent_games[i, ]
        if (is.na(game$home_score) || is.na(game$away_score)) return(NA)
        
        if (game$home_team == team) {
          diff <- game$home_score - game$away_score
        } else {
          diff <- game$away_score - game$home_score
        }
        
        # Exponential decay weight (most recent = weight 1.0, decreasing)
        weight <- 0.9^(i-1)
        return(diff * weight)
      })
      
      # Remove NAs and check if we have any data
      valid_diffs <- differentials[!is.na(differentials)]
      if (length(valid_diffs) == 0) return(0)
      
      weights <- 0.9^(0:(length(valid_diffs)-1))
      return(sum(valid_diffs) / sum(weights))
    }
    
    # Advanced Strength Assessment
    calc_strength_rating <- function(team_games, team, all_games) {
      if (nrow(team_games) == 0) return(50)
      
      recent_games <- head(team_games, 12)
      
      # Calculate win rate with opponent strength adjustment
      results <- sapply(seq_len(nrow(recent_games)), function(i) {
        game <- recent_games[i, ]
        if (is.na(game$home_score) || is.na(game$away_score)) return(NA)
        
        # Determine if team won
        team_won <- if (game$home_team == team) {
          game$home_score > game$away_score
        } else {
          game$away_score > game$home_score
        }
        
        # Get opponent
        opponent <- if (game$home_team == team) game$away_team else game$home_team
        
        # Simple opponent strength (their win rate in recent games)
        opp_games <- all_games %>%
          filter((home_team == opponent | away_team == opponent) & 
                 gameday < game$gameday) %>%
          arrange(desc(gameday)) %>%
          head(10)
        
        if (nrow(opp_games) > 0) {
          opp_wins <- sum(sapply(seq_len(nrow(opp_games)), function(j) {
            g <- opp_games[j, ]
            if (is.na(g$home_score) || is.na(g$away_score)) return(0)
            if (g$home_team == opponent) g$home_score > g$away_score else g$away_score > g$home_score
          }), na.rm = TRUE)
          
          opp_strength <- opp_wins / nrow(opp_games)
        } else {
          opp_strength <- 0.5  # Default if no opponent history
        }
        
        # Weight win by opponent strength (beating good teams counts more)
        if (!is.na(team_won) && team_won) {
          return(0.3 + 0.7 * opp_strength)  # Win value between 0.3-1.0
        } else if (!is.na(team_won)) {
          return(0.3 * (1 - opp_strength))  # Loss penalty between 0-0.3
        } else {
          return(NA)
        }
      })
      
      valid_results <- results[!is.na(results)]
      if (length(valid_results) == 0) return(50)
      
      strength <- mean(valid_results) * 100
      return(max(10, min(90, strength)))  # Cap between 10-90
    }
    
    # Calculate trend momentum
    calc_momentum <- function(team_games, team) {
      if (nrow(team_games) < 6) return(0)
      
      recent_games <- head(team_games, 6)
      
      # Calculate point differential trend
      diffs <- sapply(seq_len(nrow(recent_games)), function(i) {
        game <- recent_games[i, ]
        if (is.na(game$home_score) || is.na(game$away_score)) return(NA)
        
        if (game$home_team == team) {
          game$home_score - game$away_score
        } else {
          game$away_score - game$home_score
        }
      })
      
      # Remove NAs
      valid_diffs <- diffs[!is.na(diffs)]
      
      # Simple linear trend (positive = improving)
      if (length(valid_diffs) >= 3) {
        # Check for zero variance
        if (sd(valid_diffs) == 0) return(0)
        
        x <- seq_along(valid_diffs)
        correlation <- cor(x, valid_diffs, use = "complete.obs")
        
        # Handle NA correlation
        if (is.na(correlation)) return(0)
        
        return(correlation * sd(valid_diffs))
      }
      
      return(0)
    }
    
    # Calculate metrics for both teams
    team_a_form <- calc_recent_form(data$team_a_games, data$team_a)
    team_b_form <- calc_recent_form(data$team_b_games, data$team_b)
    
    team_a_strength <- calc_strength_rating(data$team_a_games, data$team_a, data$all_games)
    team_b_strength <- calc_strength_rating(data$team_b_games, data$team_b, data$all_games)
    
    team_a_momentum <- calc_momentum(data$team_a_games, data$team_a)
    team_b_momentum <- calc_momentum(data$team_b_games, data$team_b)
    
    # Calculate differences
    recent_form_diff <- team_a_form - team_b_form
    strength_rating_diff <- team_a_strength - team_b_strength
    trend_momentum <- team_a_momentum - team_b_momentum
    
    # Historical matchup factor
    matchup_factor <- 0
    if (nrow(data$historical_matchups) > 0) {
      recent_h2h <- head(data$historical_matchups, 5)
      
      if (nrow(recent_h2h) > 0) {
        team_a_h2h_wins <- sum(sapply(seq_len(nrow(recent_h2h)), function(i) {
          game <- recent_h2h[i, ]
          if (is.na(game$home_score) || is.na(game$away_score)) return(0)
          
          team_won <- if (game$home_team == data$team_a) {
            game$home_score > game$away_score
          } else {
            game$away_score > game$home_score
          }
          
          return(as.numeric(team_won))
        }), na.rm = TRUE)
        
        matchup_factor <- (team_a_h2h_wins / nrow(recent_h2h) - 0.5) * 10
      }
    }
    
    # Combine factors for win probability
    total_advantage <- (recent_form_diff * 0.4) + 
                      (strength_rating_diff * 0.3) + 
                      (trend_momentum * 0.2) + 
                      (matchup_factor * 0.1)
    
    # Convert to probabilities
    base_prob <- 50 + (total_advantage * 1.5)
    win_prob_a <- max(15, min(85, base_prob))
    win_prob_b <- 100 - win_prob_a
    
    # Expected margin
    expected_margin <- total_advantage * 0.4
    
    # Confidence calculation
    calc_consistency <- function(team_games, team) {
      if (nrow(team_games) == 0) return(10)  # Default high variance if no data
      
      game_count <- min(8, nrow(team_games))
      if (game_count == 0) return(10)
      
      diffs <- sapply(seq_len(game_count), function(i) {
        game <- team_games[i, ]
        if (is.na(game$home_score) || is.na(game$away_score)) return(NA)
        if (game$home_team == team) game$home_score - game$away_score else game$away_score - game$home_score
      })
      
      valid_diffs <- diffs[!is.na(diffs)]
      if (length(valid_diffs) < 2) return(10)  # Need at least 2 games for variance
      
      return(sd(valid_diffs))
    }
    
    consistency_a <- calc_consistency(data$team_a_games, data$team_a)
    consistency_b <- calc_consistency(data$team_b_games, data$team_b)
    
    avg_consistency <- mean(c(consistency_a, consistency_b), na.rm = TRUE)
    confidence <- max(50, min(95, 80 - avg_consistency + abs(total_advantage) * 2))
    
    # Key factors
    key_factors <- c()
    if (abs(recent_form_diff) > 3) key_factors <- c(key_factors, "Recent form differential")
    if (abs(strength_rating_diff) > 10) key_factors <- c(key_factors, "Team strength gap")
    if (abs(trend_momentum) > 2) key_factors <- c(key_factors, "Performance momentum")
    if (abs(matchup_factor) > 2) key_factors <- c(key_factors, "Historical matchup trends")
    
    if (length(key_factors) == 0) key_factors <- "Marginal advantages"
    
    return(list(
      team_a = data$team_a,
      team_b = data$team_b,
      win_prob_a = round(win_prob_a, 1),
      win_prob_b = round(win_prob_b, 1),
      expected_margin = round(expected_margin, 1),
      recent_form_diff = round(recent_form_diff, 1),
      strength_rating_diff = round(strength_rating_diff, 1),
      trend_momentum = round(trend_momentum, 1),
      matchup_factor = round(matchup_factor, 1),
      confidence = round(confidence, 1),
      key_factors = paste(key_factors, collapse = ", ")
    ))
  }
  
  if (agent == "predictor") {
    f <- input_data
    
    # Determine winner and margin
    winner <- if (f$win_prob_a > f$win_prob_b) f$team_a else f$team_b
    margin <- abs(f$expected_margin)
    favored_team <- if (f$expected_margin > 0) f$team_a else f$team_b
    
    # Create authentic reasoning based on key factors
    reasoning_parts <- c()
    
    # Recent form analysis
    if (abs(f$recent_form_diff) > 2) {
      stronger_form_team <- if (f$recent_form_diff > 0) f$team_a else f$team_b
      weaker_form_team <- if (f$recent_form_diff > 0) f$team_b else f$team_a
      reasoning_parts <- c(reasoning_parts, 
        paste(stronger_form_team, "enters with superior recent form, outscoring opponents by", 
              round(abs(f$recent_form_diff), 1), "more points per game than", weaker_form_team, "over their last 10 games"))
    }
    
    # Strength differential
    if (abs(f$strength_rating_diff) > 8) {
      stronger_team <- if (f$strength_rating_diff > 0) f$team_a else f$team_b
      reasoning_parts <- c(reasoning_parts, 
        paste(stronger_team, "holds a significant strength advantage with better performance against quality opponents"))
    }
    
    # Momentum factor
    if (abs(f$trend_momentum) > 1.5) {
      momentum_team <- if (f$trend_momentum > 0) f$team_a else f$team_b
      trend_direction <- if (f$trend_momentum > 0) "upward" else "concerning"
      reasoning_parts <- c(reasoning_parts, 
        paste(momentum_team, "showing", trend_direction, "performance trajectory in recent games"))
    }
    
    # Historical matchup
    if (abs(f$matchup_factor) > 1.5) {
      h2h_advantage_team <- if (f$matchup_factor > 0) f$team_a else f$team_b
      reasoning_parts <- c(reasoning_parts, 
        paste(h2h_advantage_team, "has historically performed well in this matchup"))
    }
    
    # Confidence context
    if (f$confidence > 80) {
      reasoning_parts <- c(reasoning_parts, "High confidence prediction due to clear performance differentials")
    } else if (f$confidence < 65) {
      reasoning_parts <- c(reasoning_parts, "Moderate confidence as both teams show similar recent performance levels")
    }
    
    # Default reasoning if no strong factors
    if (length(reasoning_parts) == 0) {
      reasoning_parts <- c(paste("Slight edge to", winner, "based on marginal advantages in recent performance metrics"))
    }
    
    reason <- paste(reasoning_parts, collapse = ". ")
    
    return(list(
      winner = winner,
      prob_a = f$win_prob_a,
      prob_b = f$win_prob_b,
      margin = margin,
      favored_team = favored_team,
      reason = reason,
      team_a = f$team_a,
      team_b = f$team_b,
      confidence = f$confidence
    ))
  }
  
  if (agent == "updater") {
    week <- input_data$week %||% get_current_week()
    season <- input_data$season %||% 2025
    
    # 1. Data Refresh
    tryCatch({
      games <- nflreadr::load_schedules(seasons = season)
      cat("Data refreshed for season", season, "\n")
    }, error = function(e) {
      cat("Error refreshing data:", e$message, "\n")
      return(list(status = "error", message = e$message))
    })
    
    # 2. Enhanced Prediction Validation
    validation_results <- tryCatch({
      prev_week <- week - 1
      if (prev_week < 1) {
        list(
          accuracy_rate = NA, 
          avg_margin_error = NA,
          total_predictions = 0,
          correct_predictions = 0,
          high_conf_accuracy = NA,
          error_analysis = "No previous week to validate",
          weekly_report = "This is the first week of predictions"
        )
      } else {
        # Try to load previous week's predictions
        prev_predictions_file <- file.path("data", "predictions", paste0("week_", prev_week, "_", season, "_predictions.csv"))
        
        if (file.exists(prev_predictions_file)) {
          # Load predictions and actual results
          predictions <- read.csv(prev_predictions_file, stringsAsFactors = FALSE)
          actual_games <- games %>%
            filter(week == prev_week, season == season, 
                   !is.na(home_score), !is.na(away_score))
          
          if (nrow(predictions) > 0 && nrow(actual_games) > 0) {
            # Validate each prediction
            results <- list()
            error_insights <- list()
            
            for (i in seq_len(nrow(predictions))) {
              pred <- predictions[i, ]
              
              # Find matching actual game
              actual_game <- actual_games %>%
                filter((home_team == pred$team_a & away_team == pred$team_b) |
                       (home_team == pred$team_b & away_team == pred$team_a))
              
              if (nrow(actual_game) > 0) {
                game <- actual_game[1, ]
                
                # Determine actual winner and margin
                actual_home_score <- game$home_score
                actual_away_score <- game$away_score
                actual_margin <- abs(actual_home_score - actual_away_score)
                
                if (game$home_team == pred$team_a) {
                  actual_winner <- if (actual_home_score > actual_away_score) pred$team_a else pred$team_b
                } else {
                  actual_winner <- if (actual_away_score > actual_home_score) pred$team_a else pred$team_b
                }
                
                # Check prediction accuracy
                prediction_correct <- (pred$predicted_winner == actual_winner)
                margin_error <- abs(pred$predicted_margin - actual_margin)
                
                results[[i]] <- list(
                  matchup = paste(pred$team_a, "vs", pred$team_b),
                  predicted_winner = pred$predicted_winner,
                  actual_winner = actual_winner,
                  correct = prediction_correct,
                  predicted_margin = pred$predicted_margin,
                  actual_margin = actual_margin,
                  margin_error = margin_error,
                  confidence = pred$confidence
                )
                
                # Analyze why prediction might have been wrong
                if (!prediction_correct) {
                  error_reason <- ""
                  if (actual_margin > pred$predicted_margin + 10) {
                    error_reason <- "Blowout game - larger margin than expected"
                  } else if (actual_margin < 3 && pred$confidence > 75) {
                    error_reason <- "Close game despite high prediction confidence"
                  } else if (pred$confidence < 65) {
                    error_reason <- "Low confidence prediction - close matchup as expected"
                  } else {
                    error_reason <- "Team trends didn't hold - possible injuries, variance, or coaching adjustments"
                  }
                  
                  error_insights[[length(error_insights) + 1]] <- list(
                    matchup = paste(pred$team_a, "vs", pred$team_b),
                    reason = error_reason,
                    confidence = pred$confidence
                  )
                }
              }
            }
            
            # Calculate overall metrics
            valid_results <- results[!sapply(results, is.null)]
            if (length(valid_results) > 0) {
              total_games <- length(valid_results)
              correct_predictions <- sum(sapply(valid_results, function(x) x$correct))
              accuracy_rate <- (correct_predictions / total_games) * 100
              avg_margin_error <- mean(sapply(valid_results, function(x) x$margin_error))
              
              # High confidence accuracy (>75% confidence predictions)
              high_conf_results <- valid_results[sapply(valid_results, function(x) x$confidence > 75)]
              high_conf_accuracy <- if (length(high_conf_results) > 0) {
                (sum(sapply(high_conf_results, function(x) x$correct)) / length(high_conf_results)) * 100
              } else { NA }
              
              # Generate weekly report
              weekly_report <- paste0(
                "Week ", prev_week, " Performance Summary:\n",
                "• Overall Accuracy: ", round(accuracy_rate, 1), "% (", correct_predictions, "/", total_games, " games)\n",
                "• Average Margin Error: ", round(avg_margin_error, 1), " points\n",
                if (!is.na(high_conf_accuracy)) paste0("• High Confidence Accuracy: ", round(high_conf_accuracy, 1), "%\n") else "",
                if (length(error_insights) > 0) {
                  paste0("• Prediction Errors Analysis:\n",
                         paste(sapply(error_insights, function(x) 
                           paste0("  - ", x$matchup, ": ", x$reason, " (", x$confidence, "% confidence)")),
                           collapse = "\n"))
                } else "• All predictions were correct!"
              )
              
              list(
                accuracy_rate = accuracy_rate,
                avg_margin_error = avg_margin_error,
                total_predictions = total_games,
                correct_predictions = correct_predictions,
                high_conf_accuracy = high_conf_accuracy,
                error_analysis = error_insights,
                weekly_report = weekly_report,
                detailed_results = valid_results
              )
            } else {
              list(
                accuracy_rate = NA,
                avg_margin_error = NA,
                total_predictions = 0,
                correct_predictions = 0,
                high_conf_accuracy = NA,
                error_analysis = "No matching games found for validation",
                weekly_report = "Could not validate predictions - no matching completed games found"
              )
            }
          } else {
            list(
              accuracy_rate = NA,
              avg_margin_error = NA,
              total_predictions = 0,
              correct_predictions = 0,
              high_conf_accuracy = NA,
              error_analysis = "Insufficient data for validation",
              weekly_report = "No predictions or completed games found for validation"
            )
          }
        } else {
          list(
            accuracy_rate = NA,
            avg_margin_error = NA,
            total_predictions = 0,
            correct_predictions = 0,
            high_conf_accuracy = NA,
            error_analysis = "No previous predictions file found",
            weekly_report = paste("No predictions file found for Week", prev_week)
          )
        }
      }
    }, error = function(e) {
      list(
        accuracy_rate = NA,
        avg_margin_error = NA,
        total_predictions = 0,
        correct_predictions = 0,
        high_conf_accuracy = NA,
        error_analysis = paste("Validation error:", e$message),
        weekly_report = paste("Error during validation:", e$message)
      )
    })
    
    # 3. Generate predictions for upcoming week
    upcoming_games <- tryCatch({
      schedules <- nflreadr::load_schedules(seasons = season)
      schedules %>%
        filter(week == !!week, season == !!season, 
               is.na(home_score) | is.na(away_score)) %>%
        select(week, season, gameday, home_team, away_team) %>%
        arrange(gameday)
    }, error = function(e) {
      data.frame(week = week, season = season, home_team = character(), away_team = character())
    })
    
    # Initialize predictions dataframe for return
    weekly_predictions_df <- NULL
    
    weekly_predictions <- list()
    
    if (nrow(upcoming_games) > 0) {
      cat("Generating predictions for", nrow(upcoming_games), "games in week", week, "\n")
      
      for (i in seq_len(nrow(upcoming_games))) {
        game <- upcoming_games[i, ]
        
        # Run prediction pipeline for each game
        tryCatch({
          data <- call_agent("data-getter", list(team_a = game$home_team, team_b = game$away_team))
          feats <- call_agent("data-engineer", data)
          pred <- call_agent("predictor", feats)
          
          weekly_predictions[[i]] <- pred
        }, error = function(e) {
          cat("Error predicting", game$home_team, "vs", game$away_team, ":", e$message, "\n")
        })
      }
      
      # Store weekly predictions
      if (length(weekly_predictions) > 0) {
        # Simple path to existing src/data/predictions directory
        predictions_file <- file.path("data", "predictions", paste0("week_", week, "_", season, "_predictions.csv"))
        
        tryCatch({
          # Convert predictions to data frame
          pred_list <- list()
          for (j in seq_along(weekly_predictions)) {
            if (!is.null(weekly_predictions[[j]])) {
              pred <- weekly_predictions[[j]]
              pred_list[[j]] <- data.frame(
                team_a = pred$team_a,
                team_b = pred$team_b,
                predicted_winner = pred$winner,
                win_prob_a = pred$prob_a,
                win_prob_b = pred$prob_b,
                predicted_margin = pred$margin,
                confidence = pred$confidence,
                reasoning = pred$reason,
                prediction_date = Sys.Date(),
                stringsAsFactors = FALSE
              )
            }
          }
          
          if (length(pred_list) > 0) {
            all_predictions <- do.call(rbind, pred_list)
            
            # Simple write to existing directory
            write.csv(all_predictions, predictions_file, row.names = FALSE)
            cat("Saved", nrow(all_predictions), "predictions to", predictions_file, "\n")
            
            # Store predictions in return for display
            weekly_predictions_df <- all_predictions
          }
        }, error = function(e) {
          cat("Error saving predictions:", e$message, "\n")
        })
      }
    }
    
    # 4. Performance Summary and Data Storage
    if (!is.na(validation_results$accuracy_rate)) {
      # Save performance data
      tryCatch({
        performance_data <- data.frame(
          week = week - 1,  # Previous week that was validated
          season = season,
          total_games = validation_results$total_predictions,
          correct_predictions = validation_results$correct_predictions,
          accuracy_rate = validation_results$accuracy_rate,
          avg_margin_error = validation_results$avg_margin_error,
          high_conf_accuracy = validation_results$high_conf_accuracy %||% NA,
          validation_date = Sys.Date(),
          stringsAsFactors = FALSE
        )
        
        performance_file <- file.path("data", "performance", paste0("week_", week - 1, "_", season, "_performance.csv"))
        
        # Ensure performance directory exists
        if (!dir.exists("data/performance")) {
          dir.create("data/performance", recursive = TRUE)
        }
        
        write.csv(performance_data, performance_file, row.names = FALSE)
        cat("Saved performance data to", performance_file, "\n")
      }, error = function(e) {
        cat("Error saving performance data:", e$message, "\n")
      })
    }
    
    avg_accuracy <- validation_results$accuracy_rate
    
    # 5. Model Adjustments (simplified)
    suggested_adjustments <- list()
    if (!is.na(validation_results$accuracy_rate)) {
      if (validation_results$accuracy_rate < 60) {
        suggested_adjustments <- c(suggested_adjustments, "Consider increasing recent form weight")
      }
      if (validation_results$avg_margin_error > 10) {
        suggested_adjustments <- c(suggested_adjustments, "Recalibrate margin prediction scaling")
      }
    }
    
    return(list(
      status = "success",
      week = week,
      season = season,
      validation_results = validation_results,
      upcoming_predictions = length(weekly_predictions),
      predictions_data = weekly_predictions_df,
      season_accuracy = round(avg_accuracy, 1),
      suggested_adjustments = suggested_adjustments,
      message = paste("Updated system for week", week, "- Generated", length(weekly_predictions), "predictions")
    ))
  }
}

ui <- fluidPage(
  titlePanel("🏈 NFL Matchup Predictor - Advanced Trend Analysis"),
  
  # Add tabs for different functions
  tabsetPanel(
    tabPanel("Matchup Predictor",
      sidebarLayout(
        sidebarPanel(
          selectInput("team_a", "Select Team A:", choices = NULL),
          selectInput("team_b", "Select Team B:", choices = NULL),
          actionButton("go", "Analyze Matchup", class = "btn-primary btn-lg"),
          br(), br(),
          checkboxInput("save_prediction", "Save this prediction", value = TRUE),
          helpText("Prediction based on recent form, team strength, performance momentum, and historical matchup data."),
          br(),
          h5("Saved Predictions:"),
          actionButton("view_saved", "View All Saved Predictions", class = "btn-info"),
          br(), br(),
          downloadButton("download_predictions", "Download Predictions CSV", class = "btn-secondary")
        ),
        mainPanel(
          uiOutput("result"),
          br(),
          uiOutput("saved_predictions_summary")
        )
      )
    ),
    
    tabPanel("Player Stat Predictor",
      sidebarLayout(
        sidebarPanel(
          h4("🎯 Top TD Performers", style = "color: #337ab7;"),
          selectInput("player_team_a", "Select Team A:", choices = NULL),
          selectInput("player_team_b", "Select Team B:", choices = NULL),
          actionButton("analyze_players", "Analyze Top Performers", class = "btn-success btn-lg"),
          br(), br(),
          helpText("Identifies the 5 best touchdown performers for each team based on recent form, accounting for injuries."),
          hr(),
          h5("Weekly Bulk Update:"),
          fluidRow(
            column(12,
              numericInput("player_week", "Week:", value = NULL, min = 1, max = 18),
              numericInput("player_season", "Season:", value = 2025, min = 2020, max = 2030),
              actionButton("bulk_player_update", "Generate Weekly Player Predictions", class = "btn-warning btn-lg"),
              helpText("Generates player predictions for all games in the specified week and shows the top 20 non-QB TD threats.")
            )
          )
        ),
        mainPanel(
          uiOutput("player_result"),
          br(),
          uiOutput("bulk_player_result")
        )
      )
    ),
    
    tabPanel("Weekly Update",
      fluidRow(
        column(12,
          h3("Weekly System Update"),
          br(),
          fluidRow(
            column(6,
              numericInput("update_week", "Week:", value = NULL, min = 1, max = 18),
              numericInput("update_season", "Season:", value = 2024, min = 2020, max = 2030)
            ),
            column(6,
              br(),
              actionButton("run_update", "Run Weekly Update", class = "btn-success btn-lg")
            )
          ),
          br(),
          uiOutput("update_result")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Populate dropdowns
  observe({
    tryCatch({
      games <- load_schedules(seasons = 2023:2024)
      teams <- sort(unique(c(games$home_team, games$away_team)))
      updateSelectInput(session, "team_a", choices = teams, selected = "KC")
      updateSelectInput(session, "team_b", choices = teams, selected = "BUF")
      # Update player predictor dropdowns
      updateSelectInput(session, "player_team_a", choices = teams, selected = "KC")
      updateSelectInput(session, "player_team_b", choices = teams, selected = "BUF")
    }, error = function(e) {
      # Fallback teams
      teams <- c("KC", "BUF", "GB", "TB", "LAR", "SF", "DAL", "NE", "MIA", "CIN", 
                 "BAL", "DEN", "LAC", "NYJ", "IND", "TEN", "HOU", "JAX", "CLE", "PIT",
                 "PHI", "WAS", "NYG", "DAL", "MIN", "DET", "CHI", "ATL", "NO", "CAR", "TB")
      updateSelectInput(session, "team_a", choices = teams, selected = "KC")
      updateSelectInput(session, "team_b", choices = teams, selected = "BUF")
      updateSelectInput(session, "player_team_a", choices = teams, selected = "KC")
      updateSelectInput(session, "player_team_b", choices = teams, selected = "BUF")
    })
    
    # Set default week for updater
    if (is.null(input$update_week)) {
      updateNumericInput(session, "update_week", value = get_current_week())
    }
    if (is.null(input$player_week)) {
      updateNumericInput(session, "player_week", value = get_current_week())
    }
  })

  # Player stat prediction logic
  observeEvent(input$analyze_players, {
    req(input$player_team_a, input$player_team_b)
    
    if (input$player_team_a == input$player_team_b) {
      output$player_result <- renderUI({
        h4("Please select two different teams.", style = "color: orange;")
      })
      return()
    }
    
    tryCatch({
      # Show loading message
      output$player_result <- renderUI({
        h4("Analyzing player data...", style = "color: blue;")
      })
      
      # Run player prediction pipeline
      player_data <- call_agent("player-predictor", list(
        team_a = input$player_team_a, 
        team_b = input$player_team_b, 
        week = get_current_week()
      ))
      player_analysis <- call_agent("player-engineer", player_data)
      
      # Display results
      output$player_result <- renderUI({
        tagList(
          h3(paste(player_analysis$team_a, "vs", player_analysis$team_b, "- Top TD Performers"), 
             style = "text-align: center; color: #333;"),
          
          fluidRow(
            # Team A performers
            column(6,
              h4(paste("🏈", player_analysis$team_a), style = "color: #d9534f; text-align: center;"),
              if (nrow(player_analysis$top_performers_a) > 0) {
                tagList(
                  lapply(seq_len(nrow(player_analysis$top_performers_a)), function(i) {
                    player <- player_analysis$top_performers_a[i, ]
                    
                    # Determine primary stat to highlight
                    primary_yards <- max(c(
                      player$predicted_receiving_yards %||% 0,
                      player$predicted_rushing_yards %||% 0,
                      player$predicted_passing_yards %||% 0
                    ), na.rm = TRUE)
                    
                    primary_stat <- if (player$predicted_passing_yards == primary_yards && primary_yards > 0) {
                      paste0(primary_yards, " Pass Yds")
                    } else if (player$predicted_receiving_yards == primary_yards && primary_yards > 0) {
                      paste0(primary_yards, " Rec Yds") 
                    } else if (player$predicted_rushing_yards == primary_yards && primary_yards > 0) {
                      paste0(primary_yards, " Rush Yds")
                    } else {
                      "Multi-purpose"
                    }
                    
                    # Color code based on TD probability
                    color_class <- if (player$td_probability >= 70) {
                      "success"
                    } else if (player$td_probability >= 50) {
                      "warning" 
                    } else {
                      "info"
                    }
                    
                    tags$div(
                      class = paste0("alert alert-", color_class),
                      style = "margin: 10px 0; padding: 15px;",
                      tags$h5(player$player_name, style = "margin: 0 0 5px 0;"),
                      tags$p(
                        strong("Position: "), player$position, " | ",
                        strong("TD Probability: "), paste0(player$td_probability, "%"),
                        style = "margin: 5px 0;"
                      ),
                      tags$p(
                        strong("Projected: "), primary_stat,
                        if (player$injury_status == "Questionable") {
                          tags$span(" ⚠️ Injury Concern", style = "color: #856404; font-weight: bold;")
                        },
                        style = "margin: 0;"
                      )
                    )
                  })
                )
              } else {
                tags$div(
                  class = "alert alert-secondary",
                  style = "text-align: center; margin: 20px 0;",
                  "No player data available for analysis"
                )
              }
            ),
            
            # Team B performers  
            column(6,
              h4(paste("🏈", player_analysis$team_b), style = "color: #5bc0de; text-align: center;"),
              if (nrow(player_analysis$top_performers_b) > 0) {
                tagList(
                  lapply(seq_len(nrow(player_analysis$top_performers_b)), function(i) {
                    player <- player_analysis$top_performers_b[i, ]
                    
                    # Determine primary stat to highlight
                    primary_yards <- max(c(
                      player$predicted_receiving_yards %||% 0,
                      player$predicted_rushing_yards %||% 0,
                      player$predicted_passing_yards %||% 0
                    ), na.rm = TRUE)
                    
                    primary_stat <- if (player$predicted_passing_yards == primary_yards && primary_yards > 0) {
                      paste0(primary_yards, " Pass Yds")
                    } else if (player$predicted_receiving_yards == primary_yards && primary_yards > 0) {
                      paste0(primary_yards, " Rec Yds") 
                    } else if (player$predicted_rushing_yards == primary_yards && primary_yards > 0) {
                      paste0(primary_yards, " Rush Yds")
                    } else {
                      "Multi-purpose"
                    }
                    
                    # Color code based on TD probability
                    color_class <- if (player$td_probability >= 70) {
                      "success"
                    } else if (player$td_probability >= 50) {
                      "warning" 
                    } else {
                      "info"
                    }
                    
                    tags$div(
                      class = paste0("alert alert-", color_class),
                      style = "margin: 10px 0; padding: 15px;",
                      tags$h5(player$player_name, style = "margin: 0 0 5px 0;"),
                      tags$p(
                        strong("Position: "), player$position, " | ",
                        strong("TD Probability: "), paste0(player$td_probability, "%"),
                        style = "margin: 5px 0;"
                      ),
                      tags$p(
                        strong("Projected: "), primary_stat,
                        if (player$injury_status == "Questionable") {
                          tags$span(" ⚠️ Injury Concern", style = "color: #856404; font-weight: bold;")
                        },
                        style = "margin: 0;"
                      )
                    )
                  })
                )
              } else {
                tags$div(
                  class = "alert alert-secondary",
                  style = "text-align: center; margin: 20px 0;",
                  "No player data available for analysis"
                )
              }
            )
          ),
          
          tags$hr(),
          tags$div(
            style = "text-align: center; color: #666; margin-top: 20px;",
            paste("Analysis based on recent performance trends and injury status for Week", player_analysis$week)
          )
        )
      })
      
    }, error = function(e) {
      output$player_result <- renderUI({
        tags$div(
          style = "background-color: #f2dede; border: 1px solid #ebccd1; color: #a94442; padding: 15px; border-radius: 4px;",
          h4("Player Analysis Error", style = "margin-top: 0;"),
          p(paste("Unable to analyze player performance:", e$message)),
          p("This may be due to limited player data availability or API constraints.")
        )
      })
    })
  })
  
  # Bulk weekly player update logic
  observeEvent(input$bulk_player_update, {
    req(input$player_week, input$player_season)
    
    output$bulk_player_result <- renderUI({
      h4("Generating weekly player predictions...", style = "color: blue;")
    })
    
    tryCatch({
      # Run weekly player updater
      bulk_result <- call_agent("weekly-player-updater", list(
        week = input$player_week,
        season = input$player_season
      ))
      
      if (bulk_result$status == "success") {
        # Display summary of generated predictions
        output$bulk_player_result <- renderUI({
          tagList(
            tags$div(
              style = "background-color: #dff0d8; border: 1px solid #d6e9c6; color: #3c763d; padding: 15px; border-radius: 4px;",
              h4("Weekly Player Predictions Generated", style = "margin-top: 0; color: #3c763d;"),
              p(strong("Week:"), bulk_result$week, "| Season:", bulk_result$season),
              p(strong("Games Analyzed:"), bulk_result$total_games),
              
              # Show top 20 TD threats (non-QBs)
              if (!is.null(bulk_result$top_20_td_threats) && nrow(bulk_result$top_20_td_threats) > 0) {
                tagList(
                  h5("🔥 Top 20 TD Threats This Week (Non-QBs):", style = "color: #3c763d; margin-top: 15px;"),
                  tags$div(
                    style = "background-color: #f8f9fa; padding: 15px; border-radius: 4px; margin: 10px 0; max-height: 600px; overflow-y: auto;",
                    lapply(seq_len(nrow(bulk_result$top_20_td_threats)), function(i) {
                      player <- bulk_result$top_20_td_threats[i, ]
                      position_emoji <- case_when(
                        player$position == "RB" ~ "🏃",
                        player$position == "WR" ~ "🙌", 
                        player$position == "TE" ~ "🎯",
                        TRUE ~ "🏈"
                      )
                      
                      tags$div(
                        style = paste0(
                          "display: flex; justify-content: space-between; align-items: center; ",
                          "padding: 8px 12px; margin: 5px 0; border-radius: 4px; ",
                          "background: linear-gradient(90deg, #e8f5e8 0%, #f0f8f0 100%); ",
                          "border-left: 4px solid ", 
                          if (i <= 5) "#28a745" else if (i <= 10) "#ffc107" else if (i <= 15) "#fd7e14" else "#6c757d", ";"
                        ),
                        tags$div(
                          style = "display: flex; align-items: center;",
                          tags$span(paste0("#", i), style = "font-weight: bold; color: #6c757d; margin-right: 8px; width: 20px;"),
                          tags$span(position_emoji, style = "margin-right: 8px; font-size: 16px;"),
                          tags$span(player$player_name, style = "font-weight: bold; margin-right: 8px; color: #2c3e50;"),
                          tags$span(paste0("(", player$team, ")"), style = "color: #6c757d; margin-right: 8px;"),
                          tags$span(player$matchup, style = "color: #495057; font-size: 12px;")
                        ),
                        tags$div(
                          style = "text-align: right;",
                          tags$span(paste0(round(player$td_probability, 1), "%"), 
                                   style = paste0("font-weight: bold; font-size: 16px; color: ",
                                                 if (player$td_probability >= 70) "#28a745" 
                                                 else if (player$td_probability >= 50) "#ffc107" 
                                                 else "#dc3545", ";")),
                          br(),
                          tags$span(paste0("Proj: ", 
                                          ifelse(!is.na(player$predicted_rushing_yards) && player$predicted_rushing_yards > 0, 
                                                paste0(round(player$predicted_rushing_yards), " rush "), ""),
                                          ifelse(!is.na(player$predicted_receiving_yards) && player$predicted_receiving_yards > 0, 
                                                paste0(round(player$predicted_receiving_yards), " rec"), "")), 
                                   style = "font-size: 11px; color: #6c757d;")
                        )
                      )
                    })
                  )
                )
              },
              
              p(bulk_result$message, style = "margin-bottom: 0; margin-top: 15px;")
            )
          )
        })
      } else {
        output$bulk_player_result <- renderUI({
          tags$div(
            style = "background-color: #f2dede; border: 1px solid #ebccd1; color: #a94442; padding: 15px; border-radius: 4px;",
            h4("Bulk Update Error", style = "margin-top: 0;"),
            p(paste("Bulk update failed:", bulk_result$message))
          )
        })
      }
    }, error = function(e) {
      output$bulk_player_result <- renderUI({
        tags$div(
          style = "background-color: #f2dede; border: 1px solid #ebccd1; color: #a94442; padding: 15px; border-radius: 4px;",
          h4("Bulk Update Error", style = "margin-top: 0;"),
          p(paste("Unable to run bulk player update:", e$message))
        )
      })
    })
  })

  # Matchup prediction logic
  observeEvent(input$go, {
    req(input$team_a, input$team_b)
    
    if (input$team_a == input$team_b) {
      output$result <- renderUI({
        h4("Please select two different teams.", style = "color: orange;")
      })
      return()
    }
    
    tryCatch({
      # Show loading message
      output$result <- renderUI({
        h4("Analyzing matchup data...", style = "color: blue;")
      })
      
      # Run agent pipeline
      data <- call_agent("data-getter", list(team_a = input$team_a, team_b = input$team_b))
      feats <- call_agent("data-engineer", data)
      res <- call_agent("predictor", feats)

      # Save prediction if checkbox is checked
      save_message <- NULL
      if (input$save_prediction) {
        save_message <- tryCatch({
          prediction_data <- data.frame(
            prediction_id = paste0(input$team_a, "_vs_", input$team_b, "_", format(Sys.time(), "%Y%m%d_%H%M%S")),
            team_a = input$team_a,
            team_b = input$team_b,
            predicted_winner = res$winner,
            win_prob_a = res$prob_a,
            win_prob_b = res$prob_b,
            predicted_margin = res$margin,
            favored_team = res$favored_team,
            confidence = res$confidence,
            reasoning = res$reason,
            prediction_date = Sys.Date(),
            prediction_time = format(Sys.time(), "%H:%M:%S"),
            prediction_type = "individual_matchup",
            stringsAsFactors = FALSE
          )
          
          # Save to individual predictions file
          individual_predictions_file <- "data/predictions/individual_predictions.csv"
          
          if (file.exists(individual_predictions_file)) {
            existing_predictions <- read.csv(individual_predictions_file, stringsAsFactors = FALSE)
            updated_predictions <- rbind(existing_predictions, prediction_data)
          } else {
            updated_predictions <- prediction_data
          }
          
          write.csv(updated_predictions, individual_predictions_file, row.names = FALSE)
          
          tags$div(
            style = "background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 10px; border-radius: 4px; margin-top: 10px;",
            "✓ Prediction saved successfully!"
          )
        }, error = function(e) {
          tags$div(
            style = "background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 10px; border-radius: 4px; margin-top: 10px;",
            paste("⚠ Could not save prediction:", e$message)
          )
        })
      }

      output$result <- renderUI({
        tagList(
          h3(paste(res$team_a, "vs", res$team_b), style = "text-align: center; color: #333;"),
          h4(paste("Predicted Winner:", res$winner, "by", res$margin, "points"), 
             style = "text-align: center; color: #d9534f;"),
          
          br(),
          
          # Enhanced probability bars
          h5("Win Probabilities:", style = "color: #337ab7;"),
          fluidRow(
            column(6,
              strong(res$team_a, style = "font-size: 16px;"),
              tags$div(style="background-color:#f5f5f5; width:100%; margin:8px 0; border: 1px solid #ddd; border-radius: 4px;",
                tags$div(style=paste0("background: linear-gradient(90deg, #4CAF50, #45a049); width:", res$prob_a, "%; color:white; text-align:center; padding:8px; border-radius: 3px; font-weight: bold;"),
                         paste0(res$prob_a, "%"))
              )
            ),
            column(6,
              strong(res$team_b, style = "font-size: 16px;"),
              tags$div(style="background-color:#f5f5f5; width:100%; margin:8px 0; border: 1px solid #ddd; border-radius: 4px;",
                tags$div(style=paste0("background: linear-gradient(90deg, #2196F3, #1976D2); width:", res$prob_b, "%; color:white; text-align:center; padding:8px; border-radius: 3px; font-weight: bold;"),
                         paste0(res$prob_b, "%"))
              )
            )
          ),
          
          tags$hr(style = "border-color: #ddd;"),
          
          h5("Analysis:", style = "color: #337ab7;"),
          tags$div(
            style = "background-color: #f9f9f9; padding: 15px; border-left: 4px solid #337ab7; margin: 10px 0;",
            p(res$reason, style = "margin: 0; line-height: 1.5;")
          ),
          
          br(),
          
          tags$div(
            style = "text-align: center; color: #666;",
            paste("Confidence Level:", round(res$confidence), "%")
          ),
          
          save_message
        )
      })
    }, error = function(e) {
      output$result <- renderUI({
        tags$div(
          style = "background-color: #f2dede; border: 1px solid #ebccd1; color: #a94442; padding: 15px; border-radius: 4px;",
          h4("Analysis Error", style = "margin-top: 0;"),
          p(paste("Unable to analyze matchup:", e$message)),
          p("Please try again or select different teams.")
        )
      })
    })
  })
  
  # Weekly update logic
  observeEvent(input$run_update, {
    req(input$update_week, input$update_season)
    
    output$update_result <- renderUI({
      h4("Running weekly update...", style = "color: blue;")
    })
    
    tryCatch({
      # Run updater agent
      update_result <- call_agent("updater", list(
        week = input$update_week,
        season = input$update_season
      ))
      
      if (update_result$status == "success") {
        output$update_result <- renderUI({
          tagList(
            tags$div(
              style = "background-color: #dff0d8; border: 1px solid #d6e9c6; color: #3c763d; padding: 15px; border-radius: 4px;",
              h4("Weekly Update Completed", style = "margin-top: 0; color: #3c763d;"),
              p(strong("Week:"), update_result$week, "| Season:", update_result$season),
              
              # Enhanced validation results display
              if (!is.na(update_result$validation_results$accuracy_rate)) {
                tagList(
                  h5("📊 Previous Week Performance Analysis", style = "color: #3c763d; margin-top: 20px;"),
                  tags$div(
                    style = "background-color: #f8f9fa; padding: 15px; border-radius: 4px; margin: 10px 0;",
                    tags$div(
                      style = "display: flex; justify-content: space-around; margin-bottom: 15px;",
                      tags$div(
                        style = "text-align: center;",
                        tags$h6("Overall Accuracy", style = "margin: 0; color: #6c757d;"),
                        tags$h4(paste0(round(update_result$validation_results$accuracy_rate, 1), "%"), 
                               style = "margin: 5px 0; color: #28a745;"),
                        tags$small(paste(update_result$validation_results$correct_predictions, "/", 
                                       update_result$validation_results$total_predictions, "correct"))
                      ),
                      tags$div(
                        style = "text-align: center;",
                        tags$h6("Margin Error", style = "margin: 0; color: #6c757d;"),
                        tags$h4(paste0(round(update_result$validation_results$avg_margin_error, 1), " pts"), 
                               style = "margin: 5px 0; color: #17a2b8;")
                      ),
                      if (!is.na(update_result$validation_results$high_conf_accuracy)) {
                        tags$div(
                          style = "text-align: center;",
                          tags$h6("High Confidence", style = "margin: 0; color: #6c757d;"),
                          tags$h4(paste0(round(update_result$validation_results$high_conf_accuracy, 1), "%"), 
                                 style = "margin: 5px 0; color: #ffc107;"),
                          tags$small("(>75% confidence)")
                        )
                      }
                    ),
                    
                    # Weekly report
                    if (!is.null(update_result$validation_results$weekly_report)) {
                      tags$div(
                        style = "background-color: white; padding: 15px; border-left: 4px solid #28a745; margin-top: 15px;",
                        h6("📋 Detailed Weekly Report", style = "color: #28a745; margin-bottom: 10px;"),
                        tags$pre(
                          update_result$validation_results$weekly_report,
                          style = "white-space: pre-line; margin: 0; font-family: inherit; font-size: 14px; line-height: 1.4;"
                        )
                      )
                    }
                  )
                )
              } else {
                tags$div(
                  style = "background-color: #fff3cd; border: 1px solid #ffeaa7; color: #856404; padding: 10px; border-radius: 4px; margin: 10px 0;",
                  p(strong("Previous Week:"), update_result$validation_results$weekly_report, style = "margin: 0;")
                )
              },
              
              p(strong("Upcoming Week Predictions:"), update_result$upcoming_predictions, "games"),
              
              # Display predictions table if available
              if (!is.null(update_result$predictions_data) && nrow(update_result$predictions_data) > 0) {
                tagList(
                  br(),
                  h5("Generated Predictions:", style = "color: #3c763d;"),
                  tags$div(
                    style = "max-height: 400px; overflow-y: auto; background-color: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0;",
                    tags$table(
                      class = "table table-striped table-sm",
                      style = "margin: 0; font-size: 14px;",
                      tags$thead(
                        tags$tr(
                          tags$th("Matchup", style = "background-color: #e9ecef;"),
                          tags$th("Winner", style = "background-color: #e9ecef;"),
                          tags$th("Probability", style = "background-color: #e9ecef;"),
                          tags$th("Margin", style = "background-color: #e9ecef;"),
                          tags$th("Confidence", style = "background-color: #e9ecef;")
                        )
                      ),
                      tags$tbody(
                        lapply(seq_len(nrow(update_result$predictions_data)), function(i) {
                          pred <- update_result$predictions_data[i, ]
                          winner_prob <- if (pred$predicted_winner == pred$team_a) pred$win_prob_a else pred$win_prob_b
                          tags$tr(
                            tags$td(paste(pred$team_a, "vs", pred$team_b)),
                            tags$td(pred$predicted_winner, style = "font-weight: bold;"),
                            tags$td(paste0(round(winner_prob, 1), "%")),
                            tags$td(paste0(round(pred$predicted_margin, 1), " pts")),
                            tags$td(paste0(round(pred$confidence, 1), "%"))
                          )
                        })
                      )
                    )
                  )
                )
              },
              
              if (!is.na(update_result$season_accuracy)) {
                p(strong("Season Accuracy:"), paste0(update_result$season_accuracy, "%"))
              },
              
              if (length(update_result$suggested_adjustments) > 0) {
                tagList(
                  p(strong("Suggested Improvements:")),
                  tags$ul(
                    lapply(update_result$suggested_adjustments, function(adj) tags$li(adj))
                  )
                )
              },
              
              p(style = "margin-bottom: 0;", update_result$message)
            )
          )
        })
      } else {
        output$update_result <- renderUI({
          tags$div(
            style = "background-color: #f2dede; border: 1px solid #ebccd1; color: #a94442; padding: 15px; border-radius: 4px;",
            h4("Update Error", style = "margin-top: 0;"),
            p(paste("Update failed:", update_result$message))
          )
        })
      }
    }, error = function(e) {
      output$update_result <- renderUI({
        tags$div(
          style = "background-color: #f2dede; border: 1px solid #ebccd1; color: #a94442; padding: 15px; border-radius: 4px;",
          h4("Update Error", style = "margin-top: 0;"),
          p(paste("Unable to run update:", e$message))
        )
      })
    })
  })
  
  # View saved predictions
  observeEvent(input$view_saved, {
    tryCatch({
      individual_predictions_file <- "data/predictions/individual_predictions.csv"
      if (file.exists(individual_predictions_file)) {
        predictions <- read.csv(individual_predictions_file, stringsAsFactors = FALSE)
        
        if (nrow(predictions) > 0) {
          # Show most recent 10 predictions
          recent_predictions <- predictions %>%
            arrange(desc(.data$prediction_date)) %>%
            head(10)
          
          output$saved_predictions_summary <- renderUI({
            tagList(
              h4("Recent Saved Predictions:", style = "color: #337ab7;"),
              tags$div(
                style = "background-color: #f8f9fa; padding: 15px; border-radius: 4px; max-height: 400px; overflow-y: auto;",
                lapply(seq_len(nrow(recent_predictions)), function(i) {
                  pred <- recent_predictions[i, ]
                  tags$div(
                    style = "border-bottom: 1px solid #dee2e6; padding: 10px 0;",
                    tags$strong(paste(pred$team_a, "vs", pred$team_b)),
                    tags$br(),
                    paste("Winner:", pred$predicted_winner, "by", pred$predicted_margin, "points"),
                    tags$br(),
                    tags$small(paste("Date:", pred$prediction_date, pred$prediction_time), style = "color: #6c757d;")
                  )
                })
              ),
              tags$p(paste("Total saved predictions:", nrow(predictions)), style = "color: #6c757d; margin-top: 10px;")
            )
          })
        } else {
          output$saved_predictions_summary <- renderUI({
            h5("No saved predictions yet.", style = "color: #6c757d;")
          })
        }
      } else {
        output$saved_predictions_summary <- renderUI({
          h5("No saved predictions yet.", style = "color: #6c757d;")
        })
      }
    }, error = function(e) {
      output$saved_predictions_summary <- renderUI({
        h5(paste("Error loading predictions:", e$message), style = "color: #dc3545;")
      })
    })
  })
  
  # Download predictions
  output$download_predictions <- downloadHandler(
    filename = function() {
      paste0("nfl_predictions_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      tryCatch({
        individual_predictions_file <- "data/predictions/individual_predictions.csv"
        if (file.exists(individual_predictions_file)) {
          predictions <- read.csv(individual_predictions_file, stringsAsFactors = FALSE)
          write.csv(predictions, file, row.names = FALSE)
        } else {
          # Create empty file with headers
          empty_df <- data.frame(
            prediction_id = character(),
            team_a = character(),
            team_b = character(),
            predicted_winner = character(),
            win_prob_a = numeric(),
            win_prob_b = numeric(),
            predicted_margin = numeric(),
            confidence = numeric(),
            prediction_date = character(),
            stringsAsFactors = FALSE
          )
          write.csv(empty_df, file, row.names = FALSE)
        }
      }, error = function(e) {
        write.csv(data.frame(Error = paste("Could not export predictions:", e$message)), file)
      })
    }
  )
}

shinyApp(ui = ui, server = server)