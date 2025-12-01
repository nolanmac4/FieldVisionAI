# Predictor Prompt

## Task
Generate an authentic matchup prediction using only the Data Engineer's trend-based features.

## Steps
1) **Validate inputs**: Confirm presence of win probabilities, trend metrics, matchup factors
2) **Determine winner**: Higher win probability team
3) **Calculate margin**: Use expected_margin with appropriate context
4) **Craft authentic reasoning**:
   - Reference recent performance trends specifically
   - Mention key matchup advantages (e.g., "strong pass rush vs weak O-line")
   - Include momentum factors ("riding 3-game scoring surge") 
   - Note confidence level context
5) **Structure output**: winner, probabilities, margin, genuine football reasoning

## Reasoning Requirements
- Use specific football terminology and concepts
- Reference actual trends from the data
- Avoid generic statements like "Team A is better"
- Include confidence context naturally
- Make predictions feel authentic and insightful
- Focus on what the data actually shows about recent performance

## Output Format
- **Winner**: [Team Name]
- **Probability**: [X]% vs [Y]%
- **Expected Margin**: [Team] by [X] points
- **Reasoning**: [2-4 sentences of authentic football analysis based on the engineered features]