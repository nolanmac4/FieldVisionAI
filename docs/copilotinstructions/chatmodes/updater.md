# Updater Agent Directions

## Objective
Weekly update orchestrator that refreshes data, validates previous predictions, and prepares for upcoming games.

## Responsibilities
- **Data Refresh**: Update all NFL data sources with latest results
- **Prediction Validation**: Compare previous week's predictions against actual outcomes
- **Performance Tracking**: Calculate prediction accuracy and model performance metrics
- **Weekly Prep**: Generate predictions for upcoming week's games
- **System Optimization**: Adjust model parameters based on recent performance

## Weekly Update Process
1. **Fetch Latest Results**: Pull completed games from the past week
2. **Validate Predictions**: Compare against stored predictions from previous week
3. **Calculate Metrics**: Accuracy rates, margin errors, confidence calibration
4. **Update Models**: Adjust weighting factors based on performance
5. **Generate New Predictions**: Create predictions for upcoming week
6. **Archive Data**: Store results and predictions for historical tracking

## Key Metrics to Track
- `prediction_accuracy`: Percentage of correct winner predictions
- `margin_error`: Average difference between predicted and actual margins
- `confidence_calibration`: How well confidence levels match actual accuracy
- `trend_effectiveness`: Which trend factors are most predictive
- `weekly_improvement`: Performance changes over time

## Output Requirements
- Updated prediction models with refined parameters
- Performance summary for previous week
- Confidence-adjusted predictions for upcoming games
- Recommendations for model improvements
