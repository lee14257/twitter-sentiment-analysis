# Author: LEE, Woochan
# Date: 2021
library(quanteda)
library(quanteda.textstats)
library(tidyverse)
library(cluster)
library(factoextra)
library(cmu.textstat)
library(stringr)
library(anytime)
library(stringr)
library(dendextend)
library(ggdendro)
library(janitor)
library(data.table)

# PART 1: Preprocessing

# Read raw twitter data and metadata
twt <- read_csv("PATH_TO_RAW_CSV_DATASET")

# Change "GOOGL" ticker to "GOOG" for consistency
meta$ticker_symbol[meta$ticker_symbol == "GOOGL"] <- "GOOG"

# Merge ticker_symbol meta data to twt
twt <- merge(x = twt, y = meta, by = "tweet_id", all.x = TRUE)

# Drop NA values
twt <- twt[!is.na(twt$ticker_symbol), ] %>%
  mutate(post_date = format(anytime(post_date), "%Y-%m"))
head(twt)

# Create a twitter table by company tickers
 twt_tkn <- twt %>%
   dplyr::select(ticker_symbol, body) %>%
   group_by(ticker_symbol) %>%
   summarise(text = paste(body, collapse=" ")) %>%
   mutate(
     doc_id = ticker_symbol,
     text = tolower(text)
     )
names(twt_bytickers)[1] <- 'doc_id'
names(twt_bytickers)[2] <- 'text'
twt_bytickers$text <- tolower(twt_bytickers$text)

# Create token object
twt_tkn <- twt_bytickers %>%
  corpus() %>%
  tokens(what="fastestword", remove_numbers=TRUE, remove_punct = TRUE, 
         remove_symbols = TRUE, remove_url=TRUE) %>%
  tokens_remove(c('\\$[a-z0-9]+', '\\#[a-z0-9]+', '[0-9]+\\%', '\\@[a-z0-9]+'), 
                valuetype='regex') %>%
  tokens_remove(c(stopwords("english"), "apple", "appl", "aapl", "apple's", 
                  "amazon's", "amzn", "amazon", "google's", "google", "googl", 
                  "goog", "microsoft", "microsoft's", "msft", "tsla", "tesla", 
                  "tesla's"))

# Create docvar for the tokens
doc_ticker <- names(twt_tkn) %>%
  data.frame(ticker = .)
docvars(twt_tkn) = doc_ticker

# Create dfm using tokens
twt_dfm <- twt_tkn %>% dfm()


# PART 2: Corpus Composition and Keyness Tables

# Corpus composition table
twt_comp <- ntoken(twt_dfm) %>%
  data.frame(Tokens = .) %>%
  rownames_to_column("Company Ticker") %>%
  janitor::adorn_totals("row")

# Create keyness tables for the 5 company tickers
aapl_kw <- textstat_keyness(twt_dfm, docvars(twt_dfm, "ticker") == "AAPL", 
                            measure = "lr") %>%
  as_tibble() %>% dplyr::select(feature, G2) %>% rename(LL = G2, Token = feature)
amzn_kw <- textstat_keyness(twt_dfm, docvars(twt_dfm, "ticker") == "AMZN", 
                            measure = "lr") %>%
  as_tibble() %>% dplyr::select(feature, G2) %>% rename(LL = G2, Token = feature) 
goog_kw <- textstat_keyness(twt_dfm, docvars(twt_dfm, "ticker") == "GOOG", 
                            measure = "lr") %>%
  as_tibble() %>% dplyr::select(feature, G2) %>% rename(LL = G2, Token = feature)
msft_kw <- textstat_keyness(twt_dfm, docvars(twt_dfm, "ticker") == "MSFT", 
                            measure = "lr") %>%
  as_tibble() %>% dplyr::select(feature, G2) %>% rename(LL = G2, Token = feature)
tsla_kw <- textstat_keyness(twt_dfm, docvars(twt_dfm, "ticker") == "TSLA", 
                            measure = "lr") %>%
  as_tibble() %>% dplyr::select(feature, G2) %>% rename(LL = G2, Token = feature)


# PART 3: Sentiment Analysis and Time Series Graph

# Add docuscope dictionary
ds_dict <- dictionary(file = "PATH_TO_DOCUSCOPE_DICTIONARY(ds_dict.yml)")

# Preprocessing twitter token table for time series analysis
twt_time_tkn <- twt %>%
  dplyr::select(ticker_symbol, post_date, body) %>%
  group_by(ticker_symbol, post_date) %>%
  summarise(text = paste(body, collapse=" ")) %>%
  mutate(
    doc_id = paste0(ticker_symbol, "_", post_date),
    text = tolower(text)
  ) %>%
  corpus() %>%
  tokens(what="fastestword", remove_numbers=TRUE, remove_punct = TRUE, 
         remove_symbols = TRUE, remove_url=TRUE) %>%
  tokens_remove(c(stopwords("english"), "apple", "appl", "aapl", "apple's", 
                  "amazon's", "amzn", "amazon", "google's", "google", "googl", 
                  "goog", "microsoft", "microsoft's", "msft", "tsla", "tesla", 
                  "tesla's")) %>%
  tokens_remove(c('\\$[a-z]+', '\\#[a-z]+', '[0-9]+\\%', '\\@[a-z0-9]+'), 
                valuetype='regex')

# Tag the tokens using docuscope
ds_counts <- twt_time_tkn %>%
  tokens_lookup(dictionary = ds_dict, levels = 1, valuetype = "fixed") %>%
  dfm() %>%
  convert(to = "data.frame") %>%
  as_tibble() %>%
  mutate(
    # Add sentiment score
    sentiment_score = positive - negative
  )

# Normalize the counts
tot_counts <- quanteda::ntoken(twt_time_tkn) %>%
  data.frame(tot_counts = .) %>%
  tibble::rownames_to_column("doc_id") %>%
  dplyr::as_tibble()

ds_counts <- dplyr::full_join(ds_counts, tot_counts, by = "doc_id")

ds_counts <- ds_counts %>%
  dplyr::mutate_if(is.numeric, list(~./tot_counts), na.rm = TRUE) %>%
  dplyr::mutate_if(is.numeric, list(~.*100), na.rm = TRUE)

ds_counts$tot_counts <- NULL

# Simplify table to ticker_symbol, date and sentiment_score
twt_sentiment <- ds_counts %>%
  mutate(
    ticker_symbol = str_extract(doc_id, "^[A-Z]+"),
    date = as.Date(paste0(word(doc_id, 2, sep = "_"), '-01'), format='%Y-%m-%d')
  ) %>%
  dplyr::select(ticker_symbol, date, sentiment_score) %>%
  filter(date >= "2015-01-01")

# Graphing the time series plot
ggplot(twt_sentiment, aes(x=date, y=sentiment_score, color=ticker_symbol)) +
  geom_point(size = .5) +
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"), size=1, 
              level=0.95, se=T) +
  labs(x="Date", y = "Sentiment Score", title="Sentiment scores for 5 
         tech companies over time (2015~2020)")+ 
  theme(panel.grid.minor.x=element_blank(),
        panel.grid.major.x=element_blank()) +
  theme(panel.grid.minor.y =   element_blank(),
        panel.grid.major.y =   element_line(colour = "gray",size=0.25)) +
  theme(rect = element_blank()) +
  theme(legend.title=element_blank()) +
  scale_color_manual(values = c("black",
                                "orange",
                                "blue",
                                "red",
                                "darkgreen"))

# Graphing the time series plot with confidence intervals
ggplot(twt_sentiment, aes(x=date, y=sentiment_score, color=ticker_symbol)) +
  geom_point(size = .5) +
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"), size=1, 
              level=0.95, se=F) +
  labs(x="Date", y = "Sentiment Score", title="Sentiment scores for 5 
         tech companies over time (2015~2020)")+ 
  theme(panel.grid.minor.x=element_blank(),
        panel.grid.major.x=element_blank()) +
  theme(panel.grid.minor.y =   element_blank(),
        panel.grid.major.y =   element_line(colour = "gray",size=0.25)) +
  theme(rect = element_blank()) +
  theme(legend.title=element_blank()) +
  scale_color_manual(values = c("black",
                                "orange",
                                "blue",
                                "red",
                                "darkgreen"))
