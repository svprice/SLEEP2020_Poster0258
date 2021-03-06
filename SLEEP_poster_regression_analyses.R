library(ggplot2)
library(MASS)
library(foreign)
library(robustbase)
library(lmtest)
library(sfsmisc)
library(ggeffects)
library(jtools)
library(plyr)
library(ggpubr)
library(RColorBrewer)
library(betareg)
library("scatterplot3d")
library(rgl)
library(car)
library(predict3d)
library(egg)
library(gridExtra)

# Get ggplot legend
get_legend<-function(myggplot){
  tmp <- ggplot_gtable(ggplot_build(myggplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

# Set working directory to current
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Get the paths for the three week bin directory
three_week_bins <- file.path(getwd(),"3_week_bins")

# Initialize arrays with filler values
# will contain the pvals controlling for baseline CESD to predict postCESD
pvals_midpoint_sleep <- 1:14
pvals_midpoint_sleep_mssd <- 1:14
pvals_TST <- 1:14
# _nc = not controlling for baseline
pvals_midpoint_sleep_nc <- 1:14
pvals_midpoint_sleep_mssd_nc <- 1:14
pvals_TST_nc <- 1:14

# Iterate through all the bins (only for three week bins)
for (week in 1:14){
  
  # Read in data
  filename = file.path(three_week_bins, paste(week,"_",week+3,".csv",sep=""))
  df <- read.csv(file = filename)
  
  # Remove midpoint_sleep_mssd outliers (not presented in poster)
  # df <- df[!(abs(df$midpoint_sleep_mssd - mean(df$midpoint_sleep_mssd))/sd(df$midpoint_sleep_mssd)) > 3,]
  
  # To look at the initial analyses described in the abstract with only one cohort
  # before the poster was updated to two cohorts - uncomment the line below and examine
  # the week 3 time point, 
  # df <- df[df$cohort == 'lac2',]
  
  # Linear regression models - controlling for baseline
  model_midpoint_sleep <- lm(postCESD_sum ~ midpoint_sleep + preCESD_sum, data=df)
  model_midpoint_sleep_mssd <- lm(postCESD_sum ~ midpoint_sleep_mssd + preCESD_sum, data=df)
  model_TST <- lm(postCESD_sum ~ TST + preCESD_sum, data=df)
  
  # Linear regression models - not controlling for baseline
  model_midpoint_sleep_nc <- lm(postCESD_sum ~ midpoint_sleep, data=df)
  model_midpoint_sleep_mssd_nc <- lm(postCESD_sum ~ midpoint_sleep_mssd, data=df)
  model_TST_nc <- lm(postCESD_sum ~ TST, data=df)

  # Extract pvals from regression models
  pvals_midpoint_sleep[[week]] <- coef(summary(model_midpoint_sleep))[, "Pr(>|t|)"]["midpoint_sleep"][[1]]
  pvals_midpoint_sleep_mssd[[week]] <- coef(summary(model_midpoint_sleep_mssd))[, "Pr(>|t|)"]["midpoint_sleep_mssd"][[1]]
  pvals_TST[[week]] <- coef(summary(model_TST))[, "Pr(>|t|)"]["TST"][[1]]
  
  pvals_midpoint_sleep_nc[[week]] <- coef(summary(model_midpoint_sleep_nc))[, "Pr(>|t|)"]["midpoint_sleep"][[1]]
  pvals_midpoint_sleep_mssd_nc[[week]] <- coef(summary(model_midpoint_sleep_mssd_nc))[, "Pr(>|t|)"]["midpoint_sleep_mssd"][[1]]
  pvals_TST_nc[[week]] <- coef(summary(model_TST_nc))[, "Pr(>|t|)"]["TST"][[1]]  
}

# Merge all series into a single data frame indexed by week
pvals_ms_df <- as.data.frame(pvals_midpoint_sleep)
pvals_ms_mssd_df <- as.data.frame(pvals_midpoint_sleep_mssd)
pvals_TST_df <- as.data.frame(pvals_TST)

pvals_ms_df$week <- 1:14
pvals_ms_mssd_df$week <- 1:14
pvals_TST_df$week <- 1:14

pvals_ms_df_nc <- as.data.frame(pvals_midpoint_sleep_nc)
pvals_ms_mssd_df_nc <- as.data.frame(pvals_midpoint_sleep_mssd_nc)
pvals_TST_df_nc <- as.data.frame(pvals_TST_nc)

pvals_ms_df_nc$week <- 1:14
pvals_ms_mssd_df_nc$week <- 1:14
pvals_TST_df_nc$week <- 1:14

total <- merge(merge(merge(merge(merge(
  pvals_ms_df,
  pvals_ms_mssd_df, by="week"),
  pvals_TST_df, by="week"),
  pvals_ms_df_nc, by="week"),
  pvals_ms_mssd_df_nc, by="week"),  
  pvals_TST_df_nc, by="week")


# Controlling for baseline plot
p <- ggplot(data = total) + aes(x = week) + theme_grey(base_size = 16) + theme(legend.position = "top", 
                                                                    legend.text=element_text(size=20)) +
    geom_rect(aes(xmin=7.5, xmax=8.5, ymin=0, ymax=Inf, fill="Spring Break")) + 
    geom_line(aes(y=pvals_midpoint_sleep, color="Midpoint Sleep"), size=1.) +
    geom_line(aes(y=pvals_midpoint_sleep_mssd, color="Midpoint Sleep MSSD"), size=1.) +
    geom_line(aes(y=pvals_TST, color="Total Sleep Time"), size=1.) +
    geom_hline(yintercept=0.05, size=.5) +
    labs(x = "Starting Week of 3 Week Bin", y = "p-val", color = "") +
    ggtitle("Controlling for Baseline CES-D") +
    scale_x_continuous(breaks= seq(1, 14, len = 14)) +
    scale_fill_manual(values="lightyellow")

# Not controlling for baseline plot
q <- ggplot(data = total) + aes(x = week) + theme_grey(base_size = 16) +
  geom_rect(aes(xmin=7.5, xmax=8.5, ymin=0, ymax=Inf, fill="Spring Break")) + 
  geom_line(aes(y=pvals_midpoint_sleep_nc, color="Midpoint Sleep"), size=1.) +
  geom_line(aes(y=pvals_midpoint_sleep_mssd_nc, color="Midpoint Sleep MSSD"), size=1.) +
  geom_line(aes(y=pvals_TST_nc, color="Total Sleep Time"), size=1.) +
  geom_hline(yintercept=0.05, size=.5) +
  labs(x = "Starting Week of 3 Week Bin", y = "p-val", color = "") +
  ggtitle("Not Controlling for Baseline CES-D") +
  scale_x_continuous(breaks= seq(1, 14, len = 14)) +
  scale_fill_manual(values="lightyellow")



# Combine plots
legend <- get_legend(p)
blankPlot <- ggplot()+geom_blank(aes(1,1)) + 
  cowplot::theme_nothing()

p <- p + theme(legend.position="none", axis.text.y = element_blank(), 
                                       axis.ticks.y = element_blank(),
                                       axis.title.y = element_blank())
q <- q + theme(legend.position="none")
grid.arrange(q, p, legend, ncol=2, nrow = 2, 
             layout_matrix = rbind(c(1,2), c(3,3)),
             widths = c(3, 2.7), heights = c(2.5, 0.2))



# Individual model results for weeks of interest
week = 8
filename = file.path(three_week_bins, paste(week,"_",week+3,".csv",sep=""))
df <- read.csv(file = filename)

model_midpoint_sleep <- lm(postCESD_sum ~ midpoint_sleep + preCESD_sum, data=df)
model_midpoint_sleep_mssd <- lm(postCESD_sum ~ midpoint_sleep_mssd + preCESD_sum, data=df)

summary(model_midpoint_sleep)
summary(model_midpoint_sleep_mssd)


week = 9
filename = file.path(three_week_bins, paste(week,"_",week+3,".csv",sep=""))
df <- read.csv(file = filename)

model_midpoint_sleep_mssd <- lm(postCESD_sum ~ midpoint_sleep_mssd + preCESD_sum, data=df)

summary(model_midpoint_sleep_mssd)



