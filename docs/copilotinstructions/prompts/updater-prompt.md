# Updater Agent Prompt

## Task
Execute weekly update cycle: validate previous predictions, refresh data, and prepare for upcoming week.

## Steps
1) **Data Refresh**:
   - Pull latest NFL schedules and results using `nflreadr::load_schedules()`
   - Update team statistics and player data
   - Identify completed games from previous week

2) **Prediction Validation**:
   - Load stored predictions from previous week
   - Compare predicted winners vs actual winners
   - Calculate margin prediction errors
   - Assess confidence calibration accuracy

3) **Performance Analysis**:
   - Calculate overall prediction accuracy rate
   - Identify which trend factors were most/least effective
   - Analyze prediction confidence vs actual accuracy correlation
   - Track weekly performance trends

4) **Model Refinement**:
   - Adjust weighting factors based on recent performance
   - Update recency weights for trend analysis
   - Calibrate confidence calculation parameters
   - Optimize feature importance based on validation results

5) **Weekly Predictions Generation**:
   - Identify upcoming week's games
   - Generate predictions for all matchups using updated models
   - Store predictions with timestamps for future validation
   - Create summary report of predictions and confidence levels

6) **Reporting**:
   - Generate performance summary for previous week
   - Provide updated predictions for upcoming games
   - Recommend any model adjustments
   - Archive all data for historical tracking

## Data Management
- Store predictions in structured format with timestamps
- Maintain historical performance metrics
- Cache updated team data for faster access
- Log all model parameter changes

## Output
- Performance validation report
- Updated model parameters
- Upcoming week predictions
- Recommended system improvements
