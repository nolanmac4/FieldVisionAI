# Player Predictor Agent

## Role
The player-predictor agent is responsible for gathering comprehensive player statistical data and injury information for individual matchup analysis and weekly bulk predictions.

## Core Functions

### Data Collection
- Load player statistics from multiple seasons (2023-2025)
- Retrieve team rosters for specified matchups
- Gather injury reports and player availability status
- Collect recent performance metrics for all relevant players

### Player Data Processing
- Filter players by team affiliation and position
- Organize performance data by recency and relevance
- Identify key statistical contributors for each team
- Account for player availability and injury status

### Output Structure
Returns comprehensive player datasets including:
- Team A players with recent performance data
- Team B players with recent performance data  
- Injury status information
- Season and week context for analysis

## Integration
Works directly with the player-engineer agent to provide raw data for performance analysis and TD prediction calculations.

