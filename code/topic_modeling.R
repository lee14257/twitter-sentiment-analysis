# Author: LEE, Woochan
# Date: 2021
library(cluster)
library(factoextra)
library(tidyverse)
library(quanteda)
library(seededlda)
library(lubridate)
library(cmu.textstat)

# PART 1: LDA for TSLA (Tesla)
# Load full twitter dataset grouped by tickers and quarterly (date)
twt_q <- read_csv("PATH_TO_TWITTER_DATASET")

# Create new column doc_id, which represents the ticker symbol + date
twt_q$doc_id <- paste0(twt_q$ticker_symbol, "_", twt_q$post_date)
twt_q <- twt_q %>%
  rename('text' = 'body')

# Subset the MSFT and TSLA tickers
twt_msft <- twt_q %>% subset(ticker_symbol == "MSFT")
twt_tsla <- twt_q %>% subset(ticker_symbol == "TSLA")

# Create token object for TSLA
twt_tsla_tkn <- twt_tsla %>%
  corpus() %>%
  tokens(what="fastestword", remove_punct = TRUE, remove_symbols = TRUE, 
         remove_numbers=TRUE, remove_url=TRUE, remove_separators=TRUE, 
         split_hyphens=TRUE  
  ) %>%
  tokens_remove(c('\\$[a-z0-9]+', '\\#[a-z0-9]+', '[0-9]+\\%', '\\@[a-z0-9]+'), 
                valuetype='regex') %>%
  tokens_remove(c(stopwords("english"), "tsla", "tesla", 
                  "tesla's", "btindle:", "200:1", "10:45", "w/code", "4x,", 
                  "5x,", "leech-boy"))

# Create dfm for TSLA
# Define min_termfreq and max_termfreq to restrict dfm
twt_tsla_dfm <- twt_tsla_tkn %>% dfm() %>% 
  dfm_trim(min_termfreq = 30, max_termfreq = 85)

# Latent Dirichlet Allocation (LDA) for TSLA
set.seed(2023)
tsla_lda <- textmodel_lda(twt_tsla_dfm, k = 6)

# Print overview of top 30 words for each topic
tsla_30 <- as.data.frame(terms(tsla_lda, 30))
print(tsla_30)

# Assign each doc_id to the topics
data.frame(doc_id = twt_tsla$doc_id, Topic = topics(tsla_lda))

# Plotting topic in the time-series graph for TSLA
# Read in docuscope-tagged dfm, and filter TSLA
tsla_docuscope <- read_csv("PATH_TO_NORMALIZED_DATA") %>%
  filter(ticker == "TSLA")

# Transform dfm to feed to ggplot
tsla_sentiment <- tsla_docuscope %>%
  mutate(
    ticker_symbol = str_extract(doc_id, "^[A-Z]+"),
    date = as.Date(paste0(word(doc_id, 2, sep = "_"), '-01'), format='%Y-%m-%d')
  ) %>%
  dplyr::select(ticker_symbol, date, sentiment_score) %>%
  filter(date >= "2015-01-01")

# Graphing the time series plot for TSLA
ggplot(tsla_sentiment, aes(x=date, y=sentiment_score)) +
  geom_point(size = .5) +
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"), size=1, 
              level=0.95, se=T, colour="darkgreen") +
  labs(x="Date", y = "Sentiment Score", 
       title="Sentiment scores for TSLA over time (2015~2020)")+ 
  theme(panel.grid.minor.x=element_blank(),
        panel.grid.major.x=element_blank()) +
  theme(panel.grid.minor.y=element_blank(),
        panel.grid.major.y=element_line(colour = "gray",size=0.25)) +
  theme(rect = element_blank()) +
  theme(legend.title=element_blank()) + 
  geom_vline(xintercept = c(ymd("2016/06/30"),
                            ymd("2017/06/30"), 
                            ymd("2018/06/30")), linetype = 2)


# PART 2: LDA for MSFT (Microsoft)

# Create token for MSFT
twt_msft_tkn <- twt_msft %>%
  corpus() %>%
  tokens(what="fastestword", remove_punct = TRUE, remove_symbols = TRUE, 
         remove_numbers=TRUE, remove_url=TRUE, remove_separators=TRUE, 
         split_hyphens=TRUE  
  ) %>%
  tokens_remove(c('\\$[a-z0-9]+', '\\#[a-z0-9]+', '[0-9]+\\%', '\\@[a-z0-9]+'), 
                valuetype='regex') %>%
  tokens_remove(c(stopwords("english"), "microsoft", "microsoft's", "msft"))

# Create dfm for msft
twt_msft_dfm <- twt_msft_tkn %>% dfm() %>% 
  dfm_trim(min_termfreq = 25, max_termfreq = 95)

# LDA model
set.seed(222)
msft_lda <- textmodel_lda(twt_msft_dfm, k = 6)

# Overview of top 30 words for each topic
msft_30 <- as.data.frame(terms(msft_lda, 30))
print(msft_30)

# Assign each doc_id to the topics
data.frame(doc_id = twt_msft$doc_id, Topic = topics(msft_lda))

# Load docuscope-tagged dfm for MSFT
msft_docuscope <- read_csv("PATH_TO_NORMALIZED_DATASET") %>%
  filter(ticker == "MSFT")

# Transform dfm to feed to ggplot
msft_sentiment <- msft_docuscope %>%
  mutate(
    ticker_symbol = str_extract(doc_id, "^[A-Z]+"),
    date = as.Date(paste0(word(doc_id, 2, sep = "_"), '-01'), format='%Y-%m-%d')
  ) %>%
  dplyr::select(ticker_symbol, date, sentiment_score) %>%
  filter(date >= "2015-01-01")

# Graphing the time series plot for MSFT
ggplot(msft_sentiment, aes(x=date, y=sentiment_score)) +
  geom_point(size = .5) +
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"), size=1, 
              level=0.95, se=T, colour="red") +
  labs(x="Date", y = "Sentiment Score", title="Sentiment scores for MSFT 
         over time (2015~2020)")+ 
  theme(panel.grid.minor.x=element_blank(),
        panel.grid.major.x=element_blank()) +
  theme(panel.grid.minor.y=element_blank(),
        panel.grid.major.y=element_line(colour = "gray",size=0.25)) +
  theme(rect = element_blank()) +
  theme(legend.title=element_blank()) + 
  geom_vline(xintercept = c(ymd("2016/06/30"),
                            ymd("2017/01/01"), ymd("2017/06/30"), 
                            ymd("2018/01/01"), ymd("2018/06/30")), 
             linetype = 2)






