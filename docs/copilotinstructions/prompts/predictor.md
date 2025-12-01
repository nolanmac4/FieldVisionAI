# Predictor Prompt

## Task
Produce a matchup prediction **using only** the Data Engineer’s provided features and model outputs.

## Steps
1) Validate presence of: `home_team`, `away_team`, `base_prob_home`, `base_prob_away`, and either `expected_margin` or `avg_margin_abs`.
2) Winner:
   - If `base_prob_home >= base_prob_away` → `winner = home_team`; else `winner = away_team`.
3) Set `prob_home = base_prob_home`; `prob_away = base_prob_away` (sum 100).
4) Margin:
   - Prefer `expected_margin` (signed). If only `avg_margin_abs` is present, return that as an absolute expected separation.
5) Reason:
   - 1–3 sentences referencing only the Engineer’s features/facts. No extra adjustments or heuristics.
6) Return: `winner`, `prob_home`, `prob_away`, `margin`, `reason`.