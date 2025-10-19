# NBA Player Performance Predictor

This R script predicts NBA player point totals using past game logs and a Random Forest model.

## Features
- Fetches NBA data using the `hoopR` package
- Creates rolling averages and rest-day features
- Trains a Random Forest regression model on past performance
- Evaluates model accuracy with Mean Absolute Error (MAE)
- Visualizes actual vs predicted points with ggplot2

## Usage
1. Change `player_first_name` and `player_last_name` to your player of choice.
2. Adjust `n_seasons` and `curr_season` as needed.
3. Run the script in R.

## Dependencies
```R
install.packages(c("hoopR", "dplyr", "ggplot2", "lubridate", "caret", "randomForest", "stringr", "zoo"))
