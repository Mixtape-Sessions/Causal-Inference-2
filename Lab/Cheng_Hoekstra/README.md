# Cheng and Hoekstra (2013)

We are going to revisit the analysis performed by Cheng and Hoekstra on the effect of "Stand Your Ground" gun laws on homicides. To begin, load the data from `https://github.com/scunning1975/mixtape/raw/master/castle.dta`. The main variables of interest are: the state id, denoted by `sid`; the `year` of the observation; the log of the number of homocides in the state denoted `l_homicide`; and `effyear` which measures the year in which the Stand Your Ground law was implemented in a state. 

Before we begin, we need to do some data work to prepare for estimation. For estimators, we need to change `effyear` to 0 for the control states. They are in the data as `NA` in R or `.` in Stata. Then, Take the variable `effyear` and `year` and construct an event-time variable (i.e. `year` - `effyear` or $t - g$ in Callaway and Sant'Anna's syntax). For the control units, you should set the relative year indicator to `-1`. More, create a variable `treat` that denotes when treatment is active, i.e. when `year` is greater than or equal to `effyear`. 

1. Now that our data is in the correct order, we will estimate the standard TWFE event-study.

2. Use the Callaway and Sant'Anna estimator to estimate the group-time average treatment effects, $ATT(g,t)$. Then aggregate these to event-study treatment effects. *Note:* use `did` package in R or the `csdid` package in Stata. 

  a. In R you will receive the following error:

  ```
  Warning messages:
  1: In pre_process_did(yname = yname, tname = tname, idname = idname,  :
    Be aware that there are some small groups in your dataset.
    Check groups: 2005,2007,2008,2009.
  ```

  Describe why you might be getting this error

3. Then, use the imputation-estimator to estimate event-study coefficients. Note that BJS, Gardner, and Wooldridge's Mundlak estimators will produce the same exact point estimate. *Note:* use `did2s` package in R or Stata. 

4. Next, use the Sun and Abraham event-study estimator. *Note:* use `sunab` function within the `fixest` package in R or the `eventstudyinteract` package in Stata. 

5. As a bonus exercise, construct a stacked estimator where for each group, you keep all not-yet-treated observations and the never treated obserations. Keep observations only for event-time between -5 and +4. Make sure to properly stack the data and cluster at the `sid` x stack_id level.

