###### Analysis-of-Energy-Power-Consumption

#This project summary is from the perspective of a data scientist working for an “Internet of Things” analytics 
consulting firm whose client is a home developer. 
#The client would like to know if insights can be found in the sub-metered energy consumption data set that could be used as an incentive to potential home buyers that may be interested in “smart home” technology.

##Objective

#The main business objective of the project is to Determine if the installation of sub-metering devices that 
measure power consumption can translate into economic incentive recommendations for homeowners.

#Turning the business problem into a data science problem, we’ll look to find the following deliverables below to support the business objective.
#Sub-metered energy consumption data that provides enough granularity to uncover trends in behavior or appliance performance.
#Peak energy usage can be identified allowing for the potential to modify behavior to take advantage of off-peak electricity rates.
#Longer-term patterns of energy usage that can be used to predict future usage with the potential to flag appliance degradation or unusual energy consumption.
#Making an App.

##How we approached the data

#Explore the Data (Visualizations of Energy Usage Across Sub-Meter)
#Establishment patterns, trends, cyclical or seasonal features, and other significant information.
#Time series and Forecasting


##General Overview of the Data

The data contains 2,075,259 measurements of electric power consumption in one household located in France with a one-minute sampling rate for the period Dec.2006 to Nov. 2010.
1.25% with missing data points have been removed from the database.
We noticed in the summary of the data set that there were missing values. 
To get a sense of how these missing values are distributed in the data, 
we’ll use the aggr() function of the VIM package to generate a visualization.

##Visualizations of Energy Usage Across Sub-Meters and Time Periods

Keeping the business objective in mind, the initial exploratory analysis will be looking for any trends or patterns in the data that would be of value to a homeowner. 
Since this is a large data set and there are quite a few visualizations to generate, the data will be 
subset and visualized without saving to a data frame or tibble object. 
This is accomplished using the pipe operator (%>%) which allows us to chain together a sequence of coded operations. 
Once the more informative time periods are identified, data sets of subset time periods can be generated for the more in-depth time series analysis.
We’ll start by visualizing the least granular of time periods (yearly) and drill down from there.
##-Year_Proportional Plot
##-Quarterly bar plot
##-Monthly bar chart
#-Week of the year- bar plot
#-Hour of day bar chart

##Compare High Energy Consumption for the Day of Week ( summer & Winter)

#Insights gleaned from energy consumption by day of the week could be of value to a homeowner as it can readily be 
related to homeowner energy consumption behaviors
##-Filter and plot data for weeks 1-8 (winter)
###-Filter and plot data for weeks 18-25 (summer)
##Summary Plot
To highlight and more readily compare energy consumption on submeter 3 in summer and winter seasons, 
we’ll prepare a line chart.

##Timeseries Analysis

Through exploratory data analysis, we were able to identify trends in energy consumption leading to insights that had the potential to save money for a homeowner through
behavior modification or by flagging an inefficient appliance. 
An additional opportunity to monitor the health of an appliance would be to compare actual energy consumption to projected consumption. 
If actual consumption fell out of the projected range, the homeowner could be alerted that maintenance may be required and 
thereby avoiding a costly and disruptive failure of an appliance. 
To do this, we’ll convert a subset of the data to a time series object and then use the forecast() function to predict energy 
consumption.
#Quarterly
#Monthly
##Convert to Time Series and Plot
#To convert our data to a time series object, we’ll use R’s ts() function on our subset time series data.
#quartely Timeseries
#Monthly Timeseries

##Linear Regression Models to Monthly Time Series & Quarterly Timeseries

For this section the focus will be on submeter 3 which accounts for a majority of the total submetered energy consumption.
We will first fit a linear model to our quarterly and monthly data. 
Before using these models to forecast future energy usage, we’ll investigate some of the assumptions of a linear regression model 
to determine if use of a linear model is appropriate for our subset time series data sets.
##Asses Model Fit
#Fitted vs Actual
#For instance, we can plot the fitted values vs. the actual values to visualize the relation
#Fitted vs Residuals
#Checkresiduals()
#Finally, we’ll use the checkresiduals() function to check several of the assumptions that are made with a time series 
linear regression model. Namely, the distribution of the residuals is normal and centered around zero, 
there is homoscedasticity or constant variance of error over time, and there is no correlation between errors.


##Forecast of Energy Consumption

With the above analysis supporting the legitimacy of our linear models, 
we can feel more confident using it to make predictions for quarterly and monthly energy consumption on submeter 3. 
We can accomplish this with the forecast() function.
#Quarterly Forecast & MOnthly Forecast
To make a forecast with the quarterly linear model, we pass the model, the number of periods to forecast,
and the confidence level for the prediction interval to the forecast function.
The plot of the resulting forecast shows a line plot of the predicted values with the 80 and 95% prediction intervals. 
The tidy() function provides a tabular summary of the point forecasts and the prediction intervals.


##Summary

In summary, this analysis was approached from the perspective of an analytics consultant working with a home-building client. 
The business objective was to determine if submetered energy data could provide insights that would incentivize homeowners 
to install submeters. We’ll go over the results of the three objectives that were identified as having potential
value to homeowners.

##Plotly Dash Board Link
https://plot.ly/organize/home/#/
https://plot.ly/dashboard/rekharchandran:26/view

















