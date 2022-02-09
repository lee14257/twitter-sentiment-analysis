# Sentimental and Topical Trend Analysis of Big-Tech Tweets

Short excerpt from the paper is provided below:

## Abstract
> In this paper we address questions related to sentimental and topical trends, as well as linguistic variations found within tweets. We examine Twitter data related to 5 Big-Tech companies, and later restrict our attention to tweets for Tesla and Microsoft, both of which reasonably represent two opposite ends of the sentimental polarity. Statistical methodologies such as topic modeling and factor analysis are utilized to address the research questions, and are accompanied by corpus linguistic techniques like part-of-speech tagging to prepare the data for analysis. We find that topical tendencies generally provide good context for understanding distinct sentimental trends in tweets. Positive and negative tweets also tend to have clear differences in linguistic characteristics, but the findings may need to be taken with a grain of salt. In the future, it would be worthwhile to put in more effort to filter out non-human generated noise as they tend to contaminate and skew the data.

## Data
The dataset was part of a paper published in the 2020 IEEE International Conference under the Intelligent Data Mining track (Mustafa Do ̆gan, Et al. 2020), primarily to determine possible speculators and influencers in the stock market. The dataset contains over 3 million unique tweets with features such as tweet id, post date, text body, and the number of comments and likes matched with the related company ticker.

## Code
This repository contains the code components used to conduct analysis and produce the research report. 
- **Time_series.Rmd:** Demonstrates sentimental time-series plots for the 5 Big-Tech companies over time (2014 December ~ 2019 December)
- **MDA_Topic_modeling.Rmd:** Displays the Latent Dirichlet Allocation (LDA) topic model used for analyzing topical tendencies of the tweets. Also shows how Multidimensional Analysis (MDA) is used to investigate linguistic characteristics of tweets differing in sentimental polarity.
- **ds_dict.yml:** Docuscope dictionary used for part-of-speech (POS) tagging and calculation of sentiment scores.
