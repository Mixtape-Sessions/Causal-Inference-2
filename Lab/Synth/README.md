# Synthetic control -- Castle Doctrine

We are going to revisit the analysis performed by Cheng and Hoekstra on the effect of "Stand Your Ground" gun laws on homicides but this time using only Florida's 2005 `Stand your Ground` law as our treatment.  We will drop all states that were treated from 2009 to 2009 which are Alabama, Alaska, Arizona, Georgia, Indiana, Kansas, Louisiana, Michigan, Mississippi, Missouri, Montana, North Dakota, Ohio, Oklahoma, South Carolina, South Dakota, Tennessee, Texas and West Virginia.  You will need to drop these variables using the `state` variable.  Also, the do file and R file associated with the Texas subdirectory may be useful guides.

## Question 1 

To begin, load the data from github by accessing it here: `https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Lab/Synthetic%20Control/crime_19602009.dta?raw=true”`. These data are aggregate crime counts for all participating jurisdictions from 1960 to 2009 for 8 index crimes.  We have data therefore from 1960 to 2004 for pre-treatment, and 2005 to 2009 for post-treatment.  You will need to generate a new panel variable called `sid` with numbers associated with each `state` name as Stata and R use both a variable list of numbers (`sid`) to identify a treatment date, as well as a name (`state`). Our treatment date is 2005 and our treatment group is Florida.  We have five outcomes:

1. Generate new variables. Escalation of violence outcome: natural log of murders per 100,000. Take the natural log of `murderrate`. Deterrence outcomes: natural log of burglaries per 100,000, as well as robberies and assaults. Take the natural log of all three rates as with `murderrate`. 

2. Following [Ferman, Pinto and Possbaum (2020)](https://onlinelibrary.wiley.com/doi/abs/10.1002/pam.22206), "Cherry Picking with Synthetic Controls", estimate 7 specifications (listed on p. 519): all pre-treatment outcome values, the first three-fourths of pre-treatment outcome values, the first half, odd, even, pretreatment outcome mean and three outcome values (first one, middle one and last one).  Include one of your own.  Calculate an ATT as the post-treatment RMSPE and a p-value associated with each specification in a Table like their Table 3, as well as figures associated with each one. 

   - How different are the weights used across specifications?
   - How different is the quality of the pre-treatment fit across specifications?
   - How robust do you consider the effects to be for Florida acorss specifications?

3. Produce "spaghetti plots" for the placebos across all specifications. If you can create a Figure like their Figure 1, great. If not, produce separate Figures.  How robust are these results?

## Question 2

Compare your analysis to that done using diff-in-diff analysis from earlier. How has this analysis changed your thoughts, if at all, about the effect of Stand Your Ground on Florida's homicide rate?  

