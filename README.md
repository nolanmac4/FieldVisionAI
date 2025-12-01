# NFL Matchup Predictor with Weekly Updates

A sophisticated multi-agent NFL prediction system that analyzes team trends, validates predictions, and automatically updates for upcoming weeks.

## Features

### 🏈 Matchup Predictor
- **Trend-based analysis**: Recent form, team strength, performance momentum
- **Authentic reasoning**: Real football insights instead of generic predictions
- **Confidence scoring**: Data-driven confidence levels for each prediction
- **Visual probabilities**: Interactive probability displays

### 📊 Weekly Update System
- **Automatic validation**: Compare predictions against actual game results
- **Performance tracking**: Track accuracy and improvement over time
- **Error analysis**: Detailed insights into why predictions failed
- **Weekly reports**: Comprehensive performance summaries
- **Model refinement**: Adjust prediction weights based on performance
- **Batch predictions**: Generate predictions for all upcoming week's games

## Agent Architecture

### 1. Data Getter Agent
- Fetches comprehensive NFL data (2015-current)
- Loads recent game history (last 16 games per team)
- Accesses player stats, team info, and historical matchups
- **Full nflreadr access** for comprehensive analysis

### 2. Data Engineer Agent  
- **Recent form analysis**: Weighted performance trends
- **Strength metrics**: Opponent-adjusted team ratings
- **Momentum tracking**: Performance trajectory analysis
- **Matchup dynamics**: Style compatibility and situational factors

### 3. Predictor Agent
- **Consume-only**: Uses engineered features without modification
- **Authentic reasoning**: Translates metrics into genuine football insights
- **Contextual predictions**: References specific trends and matchup advantages

### 4. Updater Agent ✨ NEW
- **Weekly validation**: Compare predictions vs actual results
- **Performance metrics**: Accuracy, margin errors, confidence calibration
- **Model optimization**: Adjust weights based on validation results
- **Batch processing**: Generate full week's predictions automatically

## Usage

### Running the App
& "C:\Program Files\R\R-4.5.1\bin\R.exe"

# First time setup (creates directories and installs packages)
source("setup.R")

# Or install packages manually
install.packages(c("shiny", "dplyr", "nflreadr", "readr", "lubridate"))

# Run the application
shiny::runApp("src")
```

### Making and Saving Predictions

#### Individual Matchup Predictions
1. **Select Teams**: Choose Team A and Team B from the dropdowns
2. **Enable Saving**: Check "Save this prediction" (enabled by default)
3. **Analyze**: Click "Analyze Matchup"
4. **Review**: View prediction with probabilities and reasoning
5. **Access Saved**: Click "View All Saved Predictions" to see your history

#### Batch Weekly Predictions
1. Navigate to "Weekly Update" tab
2. Set the current week and season
3. Click "Run Weekly Update"
4. Review detailed validation report from previous week
5. Analyze prediction errors and insights
6. View new predictions for upcoming week
7. System automatically saves predictions and performance data

#### Exporting Predictions
- **Download CSV**: Use the "Download Predictions CSV" button on the Matchup Predictor tab
- **File Location**: Individual predictions saved to `src/data/predictions/individual_predictions.csv`
- **Weekly Predictions**: Saved to `src/data/predictions/week_X_YYYY_predictions.csv`

### Manual Weekly Update
1. Open the app and navigate to the "Weekly Update" tab
2. Set the week and season
3. Click "Run Weekly Update"
4. Review validation results and new predictions

### Automated Updates
```r
# Run automated update script
source("src/weekly_automation.R")
```

## Data Storage

### Predictions Archive
- **Location**: `src/data/predictions/`
- **Format**: `week_X_YYYY_predictions.csv`
- **Contains**: Team matchups, predicted winners, probabilities, margins

### Performance History
- **Location**: `src/data/performance/`
- **Format**: `week_X_YYYY_performance.csv`
- **Contains**: Accuracy rates, margin errors, confidence calibration

### Automation Logs
- **Location**: `src/data/update_automation_log.csv`
- **Contains**: Timestamp, status, performance metrics for each automated update

## Key Features

### Trend-Based Analysis
- **Recency weighting**: More recent games have higher impact
- **Opponent strength**: Adjust for quality of opposition
- **Momentum tracking**: Identify improving/declining teams
- **Contextual factors**: Home field can be a factor but isn't the primary focus

### Performance Validation
- **Accuracy tracking**: Percentage of correct winner predictions
- **Margin analysis**: How close predicted point spreads are to actual
- **Confidence calibration**: Whether high-confidence predictions are more accurate
- **Model refinement**: Automatic adjustment of prediction weights

### Agent Customization
Use GitHub Copilot chat modes for agent-specific assistance:
- `@data-getter` - Data fetching and preprocessing
- `@data-engineer` - Feature engineering and trend analysis  
- `@predictor` - Prediction logic and reasoning
- `@updater` - Weekly validation and system updates

## Example Workflow

1. **Monday**: Games complete, results available
2. **Tuesday**: Run weekly update to validate previous predictions
3. **Tuesday**: Generate new predictions for upcoming week
4. **Throughout week**: Use matchup predictor for individual game analysis
5. **Next Monday**: Cycle repeats

## Advanced Features

### Model Performance Tracking
The system tracks multiple performance metrics:
- Overall prediction accuracy
- Accuracy by confidence level
- Margin prediction errors
- Trend factor effectiveness

### Automatic Model Tuning
Based on validation results, the system can:
- Adjust recent form vs strength weighting
- Modify confidence calculation parameters
- Update recency weights for trend analysis
- Calibrate margin prediction scaling

This creates a self-improving prediction system that gets better over time based on actual NFL results.
