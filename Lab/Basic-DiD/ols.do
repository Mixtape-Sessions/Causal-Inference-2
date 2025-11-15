******************************************************************************
* name: ols.do
* author: scott cunningham adapted from code by cheng cheng and mark hoekstra
* description: TWFE on the castle doctrine analysis
* date: Tuesdsay March 9th, 2021
******************************************************************************

* load the data into memory
use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear
set scheme cleanplots
* ssc install bacondecomp

