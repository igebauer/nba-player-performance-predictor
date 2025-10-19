library(hoopR)
library(dplyr)
library(ggplot2)
library(lubridate)
library(caret)
library(randomForest)
library(stringr)

get_player_id <- function(first, last, season = 2024) {
  players <- nba_playerindex(season = season)$PlayerIndex
  row <- subset(players, (grepl(first, PLAYER_FIRST_NAME , ignore.case = T) & 
                            grepl(last, PLAYER_LAST_NAME, ignore.case = T)))
  return(row$PERSON_ID)
}

# Player stats for model
player_first_name = "Giannis"
player_last_name = "Antetokounmpo"
player_id = get_player_id(player_first_name, player_last_name) # Must manually put in player_id if two players share same name
n_seasons = 3 # Must be greater than or equal to 1
curr_season = 2023 # Current NBA Season


player_df <- nba_playergamelog(player_id = player_id, season = curr_season)$PlayerGameLog
if (n_seasons > 1) {
  for (i in 1:(n_seasons - 1)) {
    player_df <- rbind(
      player_df,
      nba_playergamelog(player_id = player_id, season = (curr_season - i))$PlayerGameLog
    )
  }
}

player_df <- player_df %>% 
  mutate(
    OPP_TEAM = ifelse(
      str_detect(MATCHUP, "@"), 
      str_extract(MATCHUP, "(?<=@ )\\w+"),
      str_extract(MATCHUP, "(?<=vs\\. )\\w+")
    ),
    GAME_DATE = mdy(GAME_DATE),
    HOME = ifelse(grepl("@", MATCHUP), 0, 1),
    PTS = as.numeric(PTS),
    REB = as.numeric(REB),
    AST = as.numeric(AST),
    MIN = as.numeric(MIN),
    STL = as.numeric(STL),
    BLK = as.numeric(BLK),
    TOV = as.numeric(TOV),
    FG_PCT = as.numeric(FG_PCT)
  ) %>% 
  arrange(GAME_DATE) %>% 
  mutate(
    AVG_PTS_LAST5 = zoo::rollapply(PTS, 5, mean, align = "right", fill = NA),
    AVG_MIN_LAST5 = zoo::rollapply(MIN, 5, mean, align = "right", fill = NA),
    REST_DAYS = as.numeric(GAME_DATE - lag(GAME_DATE)),
  ) %>% 
  filter(!is.na(AVG_PTS_LAST5))


# Features
model_data <- player_df %>% 
  select(PTS, REB, AST, STL, BLK, TOV, FG_PCT, AVG_PTS_LAST5, AVG_MIN_LAST5, REST_DAYS, HOME)

set.seed(123)
train_idx <- createDataPartition(model_data$PTS, p = 0.8, list = F)
train <- model_data[train_idx, ]
test <- model_data[-train_idx, ]

rf_model <- randomForest(PTS ~ ., data = train, ntree = 2000, importance = T)

preds <- predict(rf_model, newdata = test)

mae <- mean(abs(preds - test$PTS))
cat("Mean Absolute Error: ", round(mae, 2), "points\n")


ggplot(data.frame(Actual = test$PTS, Predicted = preds), aes(x = Actual, y = Predicted)) +
  geom_point(color = "blue", size = 3) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed", size = 2) +
  theme_minimal() +
  labs(
    title = paste0(paste(player_first_name, player_last_name), ": Predicted vs Actual Points"),
    x = "Actual Points",
    y = "Predicted Points"
  )



