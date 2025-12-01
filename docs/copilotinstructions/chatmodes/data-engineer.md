<!-- filepath: c:\Users\nmacneil\Desktop\NFL_agent_full\docs\copilotinstructions\chatmodes\data-engineer.md -->
# Data Engineer Agent Directions

## Objective
Engineer trend-based features and team strength metrics from raw game data.

## Responsibilities
- **Recent Form Analysis**: Compute weighted performance trends (last 8-12 games)
  - Points scored/allowed trends with recency weights
  - Point differential momentum 
  - Performance against similar-strength opponents
- **Strength Metrics**: Calculate relative team strength
  - Adjusted offensive/defensive efficiency 
  - Strength of schedule considerations
  - Performance in similar game contexts
- **Matchup Dynamics**: Identify relevant style matchups
  - Offensive/defensive style compatibility
  - Historical performance in similar scenarios
- **Calibrated Probabilities**: Convert engineered features into win probabilities

## Key Features to Engineer
- `recent_form_diff`: Weighted form differential between teams
- `strength_rating_diff`: Relative strength advantage  
- `trend_momentum`: Recent performance trajectory
- `matchup_factor`: Style/context advantage
- `confidence_level`: Prediction confidence based on data quality

## Output Schema
```
team_a, team_b (no home/away designation)
win_prob_a, win_prob_b          # 0-100, sum to 100
expected_margin                  # positive = team_a favored
trend_strength                   # recent form indicator
matchup_edge                     # stylistic advantage
confidence                       # prediction confidence 0-100
key_factors                      # 2-3 main driving factors
```