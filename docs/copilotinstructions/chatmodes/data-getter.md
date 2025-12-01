# Data Getter Agent Directions

## Objective
Fetch comprehensive team performance data for trend-based matchup analysis.

## Responsibilities
- Load recent seasons of schedule/game data (2020-current for primary analysis, 2015+ for context)
- Retrieve both teams' recent game history (last 10-16 games each)
- Gather season-long performance metrics for context
- Access full NFL dataset for comprehensive analysis
- Return raw data structured for trend analysis

## Data Sources
- Team schedules & results: `nflreadr::load_schedules(seasons = 2015:CURRENT)`
- Player stats: `nflreadr::load_player_stats()` for context
- Team stats: `nflreadr::load_teams()` for reference
- Focus on: game results, point differentials, opponent strength, game dates

## Output
- Recent games for both teams (structured chronologically)
- Season context for current year
- Historical matchup data (if exists) for reference only
- Full access to nflreadr data for comprehensive analysis