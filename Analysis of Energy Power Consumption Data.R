
#-Load packages
library(caret)      #R modeling workhorse & ggplot2
library(tidyverse)  #Package for tidying data
library(lubridate)  #For working with dates/times of a time series
library(VIM)        #Visualizing and imputing missing values
library(Hmisc)      #for descriptive statistics
library(forecast)   #forcasting package
library(kableExtra) #fancy table generator
library(broom)      #Tidy statistical summary output
library(knitr)      #report generation
library(plotly)
library(dplyr)

#-Load data set
if(file.exists("household_power_consumption.txt")){
  Housepowerdata <- read.table("household_power_consumption.txt",
                          sep = ';', header = TRUE, stringsAsFactors = FALSE)}
summary(Housepowerdata)

house_pwrData <- read_delim('household_power_consumption.txt',
                            col_names = TRUE,
                            col_types = cols(Global_active_power='d',
                                             Global_reactive_power='d',
                                             Voltage='d', 
                                             Global_intensity='d', 
                                             Sub_metering_1='d', 
                                             Sub_metering_2='d', 
                                             Sub_metering_3='d'), 
                            delim=';',
                            na='?')

summary(house_pwrData)



#-Read in CSV file of data feature definitions
def_table <- read.csv('Energy_submeter_defs.csv')

#-create table of feature definitions
kable(def_table, align = 'l',
      col.names=c('Feature', 'Definition', 'Sub-Meter-Coverage'), caption='Data Set Feature Definitions') %>% 
  kable_styling('striped')

#-Create new DateTime feature by combining Date and Time 
house_pwr <- unite(house_pwrData, Date, Time, col='DateTime', sep=' ')

#-Convert data type of new DateTime feature
house_pwr$DateTime <- as.POSIXct(house_pwr$DateTime,
                                 format="%d/%m/%Y %T",
                                 tz="GMT")

#-Check class of new DateTime feature
class(house_pwr$DateTime)

#-check range of time covered by data set
range(house_pwr$DateTime)

#The output tells us that the data set contains energy measurements starting on Dec 16, 2006 
#and ending on Nov.26, 2010. Since 2006 contains only two weeks of data, the data set is filtered to remove data for 2006.

#-remove data from year 2006
house_pwr <- filter(house_pwr, year(DateTime) != 2006)

#Rename Independent Variable
#-change feature names
colnames(house_pwr)[2] <- 'Glbl_actvPwr'
colnames(house_pwr)[3] <- 'Glbl_ractvPwr'
colnames(house_pwr)[6] <- 'Sub-Meter-1'
colnames(house_pwr)[7] <- 'Sub-Meter-2'
colnames(house_pwr)[8] <- 'Sub-Meter-3'

#Assess Missing Values

#-Visualize extent and pattern of missing data
aggr(house_pwr, col=c('navyblue','red'),
     numbers=TRUE, 
     sortVars=TRUE, 
     labels=names(house_pwr),
     cex.axis=.7, 
     gap=3, 
     ylab=c("Histogram of missing data","Pattern"), 
     digits=2)

#-Remove rows with NA's
house_pwr <- na.omit(house_pwr)

#-Check that there are no missing values remaining
sum(is.na(house_pwr))

#-Create long form of data set
house_pwr_tidy <- house_pwr %>%
  gather(Meter, Watt_hr, `Sub-Meter-1`, `Sub-Meter-2`, `Sub-Meter-3`) 

house_pwr_tidy

#-Convert meter feature to categorical
house_pwr_tidy$Meter <- factor(house_pwr_tidy$Meter)

#-peak at data 
glimpse(house_pwr_tidy)

#Visualizations of Energy Usage Across Sub-Meters and Time Periods

#-Yearly Time Period
ytp <- house_pwr_tidy %>%
  group_by(year(DateTime), Meter) %>%
  summarise(sum=sum(Watt_hr)) %>%
  ggplot(aes(x=factor(`year(DateTime)`), sum, group=Meter,fill=Meter)) +
  labs(x='Year', y='Proportion of Energy Usage') +
  ggtitle('Proportion of Total Yearly Energy Consumption') +
  geom_bar(stat='identity', position='fill', color='black') +
  theme(panel.border=element_rect(colour='black', fill=NA)) +
  theme(text = element_text(size = 14))
ggplotly(ytp)

yearlytimeperiod <- ggplotly(ytp)
yearlytimeperiod

#Updating Plotly profiles
Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")
api_create(yearlytimeperiod, filename = "r-docs-ytp")

#Quarterly Time Period

#-Quarterly bar plot
qtp<- house_pwr_tidy %>%
  filter(year(DateTime)<2010) %>%
  group_by(quarter(DateTime), Meter) %>%
  summarise(sum=round(sum(Watt_hr/1000),3)) %>%
  ggplot(aes(x=factor(`quarter(DateTime)`), y=sum)) +
  labs(x='Quarter of the Year', y='kWh') +
  ggtitle('Total Quarterly Energy Consumption') +
  geom_bar(stat='identity', aes(fill = Meter), color='black') +
  theme(panel.border=element_rect(colour='black', fill=NA)) +
  theme(text = element_text(size = 14))
ggplotly(qtp)

Quaterlytp <- ggplotly(qtp)
Quaterlytp

#Updating Plotly profiles
Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")
api_create(Quaterlytp, filename = "r-docs-qtp")


#Monthly bar plot

#-Monthly bar chart
mtp <- house_pwr_tidy %>%
  filter(year(DateTime)<2010) %>%
  mutate(Month=lubridate::month(DateTime, label=TRUE, abbr=TRUE)) %>%
  group_by(Month, Meter) %>%
  summarise(sum=round(sum(Watt_hr)/1000),3) %>%
  ggplot(aes(x=factor(Month), y=sum)) +
  labs(x='Month of the Year', y='kWh') +
  ggtitle('Total Energy Usage by Month of the Year') +
  geom_bar(stat='identity', aes(fill = Meter), colour='black') +
  theme(panel.border=element_rect(colour='black', fill=NA)) +
  theme(text = element_text(size = 14))
ggplotly(mtp)

monthlytimeperiods <- ggplotly (mtp)
monthlytimeperiods
#Updating Plotly profiles
Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")
api_create(monthlytimeperiods, filename = "r-docs-mtp")


#-Week of the year- bar plot
wytp <- house_pwr_tidy %>%
  group_by(week(DateTime), Meter) %>%
  summarise(sum=sum(Watt_hr/1000)) %>%
  ggplot(aes(x=factor(`week(DateTime)`), y=sum)) +
  labs(x='Week of the Year', y='kWh') +
  ggtitle('Total Energy Usage by Week of the Year') +
  theme(axis.text.x = element_text(angle=90)) +
  geom_bar(stat='identity', aes(fill=Meter), colour='black') +
  theme(panel.border=element_rect(colour='black', fill=NA)) +
  theme(text = element_text(size = 14))
ggplotly(wytp)
weekytp <- ggplotly(wytp)
weekytp

#Updating Plotly profiles
Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")
api_create(weekytp, filename = "r-docs-wkytp")

#-Hour of day bar chart
htp <- house_pwr_tidy %>%
  filter(month(DateTime) == c(1,2,11,12)) %>%
  group_by(hour(DateTime), Meter) %>%
  summarise(sum=round(sum(Watt_hr)/1000),3) %>%
  ggplot(aes(x=factor(`hour(DateTime)`), y=sum)) +
  labs(x='Hour of the Day', y='kWh') +
  ggtitle('Total Energy Usage by Hour of the Day') +
  geom_bar(stat='identity', aes(fill = Meter), colour='black') +
  theme(panel.border=element_rect(colour='black', fill=NA)) +
  theme(text = element_text(size = 14))
hourtp <- ggplotly(htp)
hourtp
#Updating Plotly profiles
Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")
api_create(hourtp, filename = "r-docs-hourly")

#Compare High Energy Consumption for Day of Week (Summer & Winter)

#Winter
#-Filter and plot data for weeks 1-8
wp <- house_pwr_tidy %>%
  filter(week(DateTime) == c(1:8)) %>%
  mutate(Day=lubridate::wday(DateTime, label=TRUE, abbr=TRUE)) %>%
  group_by(Day, Meter) %>%
  summarise(sum=sum(Watt_hr/1000)) %>%
  ggplot(aes(x=factor(Day), y=sum)) +
  labs(x='Day of the Week', y='kWh') +
  ylim(0,85) +
  ggtitle('Total Energy Usage by Day for Weeks of \nHigh Consumption in Winter Months') +
  geom_bar(stat='identity', aes(fill = Meter), colour='black') +
  theme(panel.border=element_rect(colour='black', fill=NA)) +
  theme(text = element_text(size = 14))
winter <- ggplotly(wp)
winter
#Updating Plotly profiles
Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")
api_create(winter, filename = "r-docs-wintertime")

#Summer
#-Filter and plot data for weeks 18-25
sp <- house_pwr_tidy %>%
  filter(week(DateTime) == c(18:25)) %>%
  mutate(Day=lubridate::wday(DateTime, label=TRUE, abbr=TRUE)) %>%
  group_by(Day, Meter) %>%
  summarise(sum=sum(Watt_hr/1000)) %>%
  ggplot(aes(x=factor(Day), y=sum)) +
  labs(x='Day of the Week', y='kWh') +
  ylim(0,85) +
  ggtitle('Total Energy Usage by Day for Weeks of \nHigh Consumptionin Summer Months') +
  geom_bar(stat='identity', aes(fill = Meter), colour='black') +
  theme(panel.border=element_rect(colour='black', fill=NA)) +
  theme(text = element_text(size = 14))
summer <- ggplotly(sp)
summer
#Updating Plotly profiles
Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")
api_create(summer, filename = "r-docs-summertime")

#Summary Plot
#-Subset data for weeks 1-8 and assign to variable w
w <- house_pwr_tidy %>%
  filter(week(DateTime) == c(1:8)) %>%
  filter(Meter == 'Sub-Meter-3') %>% 
  mutate(Day=lubridate::wday(DateTime, label=TRUE, abbr=TRUE)) %>%
  group_by(Day, Meter) %>%
  summarise(sum=sum(Watt_hr/1000))
w

#-Subset data for weeks 18-25 and assign to variable ww
ww <- house_pwr_tidy %>%
  filter(week(DateTime) == c(18:25)) %>%
  filter(Meter == 'Sub-Meter-3') %>% 
  mutate(Day=lubridate::wday(DateTime, label=TRUE, abbr=TRUE)) %>%
  group_by(Day, Meter) %>%
  summarise(sum=sum(Watt_hr/1000))
ww
#overlay the line plots of the data to highlight 
#what appears to be conuterintuitive energy consumption on submeter 3.
#-Overlay line plots of the two 8-week time periods
sumplot <- ggplot(w) +
  labs(x='Day of the Week', y='kWh') +
  ylim(0,65) +
  ggtitle('Total Energy Usage on Submeter 3 for High\n Consumption Period in Winter and Summer Months') +
  geom_line(aes(x=Day, y=sum, group=1,colour='winter')) +
  geom_line(data = ww, aes(x=Day, y=sum, group=1, color='summer')) +
  scale_colour_manual(values=c('winter'='blue', 'summer'='red')) +
  labs(colour='Season') +
  guides(colour=guide_legend(reverse=TRUE)) +
  theme(panel.border=element_rect(colour='black', fill=NA))+
  theme(text = element_text(size = 14))
summaryplot <- ggplotly(sumplot)
summaryplot

#Updating Plotly profiles
Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")
api_create(summaryplot, filename = "r-docs-Totalenergy")


#Subset Data Set by Time Periods of Interest

#-Subset data by month and summarise total energy usage across submeters
housePWR_mnth <- house_pwr %>%
  group_by(year(DateTime), month(DateTime)) %>%
  summarise(Sub_Meter_1=round(sum(`Sub-Meter-1`/1000), 3),
            Sub_Meter_2=round(sum(`Sub-Meter-2`/1000), 3),
            Sub_Meter_3=round(sum(`Sub-Meter-3`/1000), 3))

#-Look at top several rows of new monthly data set
head(housePWR_mnth)

#-Subset data by quarter and summarise total usage across the 3 submeters
housePWR_qtr <- house_pwr %>%
  group_by(year(DateTime), quarter(DateTime)) %>%
  summarise(Sub_Meter_1=round(sum(`Sub-Meter-1`/1000), 3),
            Sub_Meter_2=round(sum(`Sub-Meter-2`/1000), 3),
            Sub_Meter_3=round(sum(`Sub-Meter-3`/1000), 3))

#-Look at top several rows of new quarterly data set 
head(housePWR_qtr)


#Convert to Time Series and Plot
#Quarterly time series

#-Create quarterly time series 
housePWR_qtrTS <- ts(housePWR_qtr[,3:5],
                     frequency=4,
                     start=c(2007,1),
                     end=c(2010,3))
housePWR_qtrTS
View(housePWR_qtrTS)


#-Plot quarterly time series
ts <- plot(housePWR_qtrTS, 
     plot.type='s',
     col=c('red', 'green', 'blue'),
     main='Total Quarterly kWh Consumption',
     xlab='Year', ylab = 'kWh')
minor.tick(nx=4)
view(ts)



#-Create legend
b <- c('Sub-meter-1', 'Sub-meter-2', 'Sub-meter-3')
legend('topleft', b, col=c('red', 'green', 'blue'), lwd=2, bty='n')

#-Plot monthly time series
#-Create monthly time series
housePWR_mnthTS <- ts(housePWR_mnth[,3:5],
                      frequency = 12,
                      start=c(2007,1),
                      end=c(2010,11))

#-Plot monthly time series
plot(housePWR_mnthTS, 
     plot.type='s',
     xlim=c(2007, 2011),
     col=c('red', 'green', 'blue'),
     main='Total Monthly kWh Consumption',
     xlab='Year/Month', ylab = 'kWh')
minor.tick(nx=12)

#-Create legend
b <- c('Sub-meter-1', 'Sub-meter-2', 'Sub-meter-3')
legend('topleft', b, col=c('red', 'green', 'blue'), lwd=2, bty='n')

#Fit Linear Regression Model to Quarterly Time Series

#-Fit linear model to quarterly time series for submeter 3
fit1 <- tslm(housePWR_qtrTS[,3] ~ trend + season)

summary(fit1)

View(fit1)

#-One-line statistical summary for quarterly linear model.
glance(fit1)

#-Tabular summary of quarterly linear model.
tidy(fit1)

# Assess Model Fit
#Fitted vs Actual

#-Plot fitted vs actual for quarterly linear model.
newdata <- data.frame(
  fit = fit1$fitted.values,
  qtr = housePWR_qtrTS[,3])
newdata

actual_quaterly <-  ggplot(newdata, aes(x=fit, y=qtr)) +
  geom_point(color='blue', size=4) +
  labs(x='Fitted Value', y='Actual') +
  geom_abline(intercept = 0, slope=1,  linetype='dashed') +
  ggtitle('Fitted vs. Actual Values for Quarterly Linear Model') +
  theme(panel.border=element_rect(colour='black', fill=NA))+
  theme(text = element_text(size = 14))
 
ggplotly(actual_quaterly)
 
 P1 <- ggplotly(actual_quaterly)
 
 api_create(P1, filename = "r-docs-enrgy")

#-Plot fitted vs residuals for quarterly linear model.

newdata1 <- data.frame(
    fit = fit1$fitted.values,
    fit1 = fit1$residuals)

residuals_quarterly <- ggplot(newdata1, aes(x=fit, y=fit1)) +
  geom_point(color='blue', size=4) +
  labs(x='Fitted Values', y='Residuals') +
  geom_hline(yintercept = 0, linetype='dashed') +
  ggtitle('Residuals Plot of Quarterly Linear Model') +
  theme(panel.border=element_rect(colour='black', fill=NA))+
  theme(text = element_text(size = 14))
P <- ggplotly(residuals_quarterly)
P


Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")


api_create(P, filename = "r-docs-enrgy1")

#-Summary analysis of residuals for quarterly linear model
checkresiduals(fit1)

# Fit Linear Regression Model to Monthly Time Series

# 8.1 Fit Model
#-Fit linear model to montly time series for submeter 3
fit2 <- tslm(housePWR_mnthTS[,3] ~ trend + season)

#-One-row statistical summary of monthly linear model
glance(fit2)

#8.2 Assess Model Fit

#Fitted vs. Actual
#-Plot fitted vs actual for monthly linear model

monthlydata <- data.frame(
  fit = fit2$fitted.values,
 mtd = housePWR_mnthTS[,3])
monthlydata

actual_monthly <- ggplot(monthlydata, aes(x=fit, y=mtd)) +
  geom_point(color='blue', size=4) +
  labs(x='Fitted Value', y='Actual') +
  geom_abline(intercept = 0, slope=1,  linetype='dashed') +
  ggtitle('Fitted vs. Actual Values for Monthly Linear Model') +
  theme(panel.border=element_rect(colour='black', fill=NA))+
  theme(text = element_text(size = 14))
amts <- ggplotly(actual_monthly)
amts

Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")


api_create(amts, filename = "r-docs-monthlytimeseries")

#Fitted vs. Residuals
#-Plot fitted vs residuals for monthly linear model

mtdre <- data.frame(
  fit = fit2$fitted.values,
  fit1 = fit2$residuals)
mtdre

mresutime <- ggplot(mtdre, aes(x=fit, y=fit1)) +
  geom_point(color='blue', size=4) +
  labs(x='Fitted Values', y='Residuals') +
  geom_hline(yintercept = 0, linetype='dashed') +
  ggtitle('Residual Plot of Monthly Linear Model') +
  theme(panel.border=element_rect(colour='black', fill=NA))+
  theme(text = element_text(size = 14))

monthlyrtp <- ggplotly (mresutime)
monthlyrtp

Sys.setenv("plotly_username"="rekharchandran")
Sys.setenv("plotly_api_key"="7p89M3k8GFVCAOFpDTNH")


api_create(monthlyrtp, filename = "r-docs-mon_ts_residual")

#Checkresiduals()
#-Summary analysis of residuals for monthly linear model
checkresiduals(fit2)

#Forecast of Energy Consumption
#9.1 Quarterly Forecast

#-Forecast 4-quarters of energy usage 
x <- forecast(fit1, h=4, level=c(80,95))
x

#-Plot 4-quarter forecast of energy usage
plot(x, showgap=FALSE, include=3,
     shadecols=c('slategray3','slategray'),
     xlab='Year', ylab='kWh',
     main='4-Quarter Forecast of Quartlerly Energy Consumption \nfor Submeter-3')
minor.tick(nx=2)

#-Summary of 4-quarter forecast
tidy(x)

#9.2 Monthly Forecast

#-Forecast 6-months of energy usage
y <- forecast(fit2,h=6, level=c(80,95))
y

#-Plot 6-month forecast of energy usage
plot(y, showgap=FALSE, include=4,
     shadecols=c('slategray3','slategray'),
     xlab ='Year',
     ylab=' kWh',
     main='6-Month Forecast of Monthly Energy Consumption')
minor.tick(nx=6)
#-Summary of 6-month forecast
tidy(y)

#Decomposing a Seasonal Time Series

## Decompose Sub-meter 3 into trend, seasonal and remainder
#Monthly Series
componentshousePWR_mnthTS <- decompose(housePWR_mnthTS[,3])
## Plot decomposed sub-meter 3 
plot(componentshousePWR_mnthTS)
## Check summary statistics for decomposed sub-meter 3 
summary(componentshousePWR_mnthTS)

#Quarterly Time Series
componentshousePWR_qtrTS <- decompose(housePWR_qtrTS[,3])
componentshousePWR_qtrTS
plot(componentshousePWR_qtrTS)

#Holt-Wintersforecasting
#Monthly
## Seasonal adjusting sub-meter 3 by subtracting the seasonal component & plot
housePWR_mnthTSAdjusted <- housePWR_mnthTS - componentshousePWR_mnthTS$seasonal
housePWR_mnthTSAdjusted
autoplot(housePWR_mnthTSAdjusted)

#Quarterly

housePWR_qtrTSAdjusted <- housePWR_qtrTS - componentshousePWR_qtrTS$seasonal
housePWR_qtrTSAdjusted
autoplot(housePWR_qtrTSAdjusted)








