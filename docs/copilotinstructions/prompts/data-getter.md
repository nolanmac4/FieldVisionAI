# Data Getter Prompt

## Task
Return all historical rows for the requested (home_team, away_team) pairing.

## Steps
1) Load schedules: `nflreadr::load_schedules(seasons = 2010:CURRENT)`.
2) Filter where `home_team == <home>` AND `away_team == <away>`.
3) Return the unmodified rows: season, week, game_id, home/away teams, scores, game_date.