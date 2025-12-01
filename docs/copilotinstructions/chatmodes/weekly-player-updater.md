# Weekly Player Updater Agent

## Role  
The weekly-player-updater agent handles bulk generation of player predictions for all games in a specified week, enabling efficient weekly updates and analysis.

## Core Functions

### Weekly Game Processing
- Identify all games scheduled for the target week
- Process each matchup through the player prediction pipeline
- Handle errors gracefully for individual game failures  
- Aggregate results across all weekly games

### Bulk Prediction Generation
- Execute player-predictor and player-engineer agents for each game
- Compile comprehensive weekly player performance forecasts
- Generate summary reports of top performers across all matchups
- Save predictions to structured data files for future reference

### Data Management
- Store weekly player predictions in organized file structure
- Maintain prediction history for performance tracking
- Generate summary statistics and insights
- Handle data persistence and retrieval operations

## Error Handling
- Robust error management for individual game prediction failures
- Continues processing remaining games if errors occur
- Provides detailed logging of successful and failed predictions
- Graceful degradation when player data is unavailable

## Output Structure
Returns comprehensive weekly update results including:
- Total games processed successfully
- Summary of top performers by team and game
- Prediction counts and success rates
- Saved file locations and data persistence confirmations

## Integration
Orchestrates player-predictor and player-engineer agents across multiple games, providing bulk update capabilities for the weekly automation system.
