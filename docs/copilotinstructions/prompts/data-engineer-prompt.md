# Data Engineer Prompt

## Task
Transform raw game data into sophisticated trend-based prediction features.

## Steps
1) **Recent Form Analysis** (last 8-12 games each team):
   - Calculate weighted scoring trends (more recent = higher weight)
   - Compute point differential momentum
   - Assess performance vs similar-strength opponents

2) **Relative Strength Assessment**:
   - Compare offensive/defensive efficiency metrics
   - Weight by strength of schedule
   - Identify performance in clutch situations

3) **Matchup Dynamics**:
   - Analyze style compatibility (run-heavy vs pass-heavy, etc.)
   - Consider contextual factors (weather, rest, etc.)
   - Historical performance in similar game situations

4) **Advanced Analytics**:
   - Use any available NFL data to enhance predictions
   - Consider player stats, team stats, situational factors
   - Apply statistical models and trend analysis

5) **Calibration**:
   - Convert feature advantages into win probabilities
   - Ensure probabilities sum to 100
   - Calculate confidence based on data clarity and consistency

6) Output engineered features following the schema

## Data Usage
- Utilize full access to nflreadr data and any other NFL data sources
- Apply advanced statistical techniques and modeling
- Consider all relevant factors that could influence game outcomes