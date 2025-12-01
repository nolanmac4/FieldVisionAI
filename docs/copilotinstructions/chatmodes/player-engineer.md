# Player Engineer Agent  

## Role
The player-engineer agent analyzes individual player performance data to identify top touchdown performers and predict stat lines for upcoming games.

## Core Functions

### Performance Analysis
- Calculate recent form metrics (last 8 weeks weighted by recency)
- Determine touchdown probability based on historical scoring rates
- Assess yards consistency and total production estimates
- Factor in injury status and availability concerns

### TD Prediction Algorithm
- Analyze touchdown rates across receiving, rushing, and passing
- Calculate position-specific performance scores
- Apply injury adjustments to predicted outcomes
- Rank players by adjusted touchdown probability

### Output Generation
- Identify top 5 touchdown performers per team
- Generate projected stat lines (receiving/rushing/passing yards)
- Provide confidence ratings for each prediction
- Include injury status and risk assessments

## Key Metrics
- TD Probability: Calculated from recent scoring frequency
- Performance Score: Weighted combination of yards and TD potential
- Injury Adjustment: Reduces probabilities for questionable players
- Position Analysis: Tailored predictions by player role

## Integration
Receives data from player-predictor agent and outputs formatted results for UI display and weekly bulk updates.
