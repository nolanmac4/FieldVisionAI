# Data Engineer Prompt

## Task
Consume the Getter rows and output calibrated model features for the Predictor.

## Steps
1) Compute head-to-head stats:
   - `h2h_n`, `home_wins`, `away_wins`.
   - `expected_margin = mean(home_score - away_score)` (signed; NA → 0).
   - `avg_margin_abs = mean(abs(home_score - away_score))` (NA → 0).
2) Produce base probabilities from head-to-head results (simple calibration OK):
   - If `h2h_n > 0`: `base_prob_home = round(100 * home_wins / h2h_n, 1)`; `base_prob_away = 100 - base_prob_home`.
   - If `h2h_n == 0`: set `base_prob_home = 50.0`, `base_prob_away = 50.0`, `expected_margin = 0`.
3) You may incorporate any additional engineered features you created (trends/SoS/etc.) **but must finalize** a single pair of calibrated probabilities that sum to 100.
4) Output the schema listed in the chatmode file, unchanged.