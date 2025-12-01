# Engineered Feature Definitions

## Core Prediction Features
- **win_prob_a/win_prob_b**: Calibrated win probabilities (sum to 100)
- **expected_margin**: Point spread prediction (positive = team_a favored)
- **confidence**: Prediction confidence 0-100 based on data clarity

## Trend Analysis Features  
- **recent_form_diff**: Weighted performance differential (last 8-12 games)
- **trend_momentum**: Recent trajectory indicator (improving/declining)
- **strength_rating_diff**: Relative team strength advantage

## Matchup Analysis Features
- **matchup_edge**: Stylistic/schematic advantage factor
- **sos_factor**: Strength of schedule adjustment
- **context_factor**: Situational advantages (rest, weather, etc.)

## Supporting Metrics
- **offensive_trend**: Recent scoring/yardage patterns  
- **defensive_trend**: Recent defensive performance patterns
- **clutch_factor**: Performance in close/important games
- **key_factors**: 2-3 main prediction drivers for explanation