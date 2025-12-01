# Data Getter Prompt

## Task
Fetch comprehensive team performance data for both teams in the requested matchup.

## Steps
1) Load recent seasons: `nflreadr::load_schedules(seasons = 2015:CURRENT)`
2) For each team, extract:
   - Last 10-16 games (chronological order)
   - Current season performance context
   - Opponent information for strength analysis
3) Include any direct historical matchups for reference
4) Access additional data sources as needed:
   - `nflreadr::load_player_stats()` for player context
   - `nflreadr::load_teams()` for team reference data
   - Any other nflreadr functions that provide relevant data
5) Return structured data ready for trend analysis

## Output
- Team A recent games with dates, opponents, scores, point differentials
- Team B recent games with dates, opponents, scores, point differentials
- Season context and opponent strength indicators
- Full access to any NFL data that could inform predictions