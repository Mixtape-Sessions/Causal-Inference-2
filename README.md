<img src="img/banner.png" alt="Mixtape Sessions Banner" width="100%"> 
<br/>

<img src="img/readme_about.png" alt="About" width="100%">
<br/>

Causal inference Part II is a 4-day workshop in design based causal inference series. It will cover three contemporary research designs in causal inference -- difference-in-differences, synthetic control and matching/weighting methods -- as well as introduce participants to causal graphs developed by Judea Pearl and others. Each day is 8 hours with 15 minute breaks on the hour plus an hour for lunch. We will review the theory behind each design, go into detail on the intuition of the estimation strategies and identification itself, as well as explore code in R and Stata and applications using these methods. The goal as always is that participants leave the workshop with competency and confidence. This class will be a sequel to the 4-day workshop on Causal Inference Part I.
<br />

<img src="img/readme_schedule.png" alt="Schedule" width="100%"> 
<br/>

<details open><summary><b>Basic Difference-in-Differences</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/01-Basics.pdf">Introducing the fundamentals of DiD</a>

<b>Code</b>

[Google Spreadsheet for simple DiD Calculations](https://docs.google.com/spreadsheets/d/1onabpc14JdrGo6NFv0zCWo-nuWDLLV2L1qNogDT9SBw/edit?usp=sharing)

<b>Readings</b>

<a href="https://mixtape.scunning.com">Causal Inference: the Mixtape (ch. 9)</a>

</details><br />



<details open><summary><b>Difference-in-Differences Estimation with and without Covariates</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/02-Covariates.pdf">Introducing OLS and various estmators with covariate adjustments</a>

<b>Code</b>

[did in R](https://bcallaway11.github.io/did/); 

[drdid in Stata](https://friosavila.github.io/playingwithstata/main_drdid.html)

<b>Readings</b>

[Cunningham (2021 ch. 9)](https://mixtape.scunning.com/09-difference_in_differences), 

Outcome regression [(Heckman, Ichimura and Todd 1997)](http://jenni.uchicago.edu/papers/Heckman_Ichimura-Todd_REStud_v64-4_1997.pdf), 

Inverse probability weight estimator [(Abadie 2005)](https://academic.oup.com/restud/article-abstract/72/1/1/1581053?redirectedFrom=fulltext), 

Doubly robust [(Sant'Anna and Zhao 2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620301901)           


</details><br />

<details open><summary><b>Twoway Fixed Effects and Bacon-Decomposition</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/03-ATTGT.pdf">Bacon decomposition</a>

<b>Code</b>

[Fixed effects and Pooled OLS example](https://mixtape.scunning.com/08-panel_data#data-exercise-survey-of-adult-service-providers), 

[bacondecomp in Stata](https://asjadnaqvi.github.io/DiD/docs/01_stata/), 

[bacondecomp in R](https://github.com/evanjflack/bacondecomp), 

[ddtiming in Stata](https://tgoldring.github.io/projects/ddtiming.html), 

[Shiny App for Bacon Decomposition](https://mixtape.shinyapps.io/Bacon-Decomposition/)

<b>Readings</b>

<a href="https://mixtape.scunning.com/08-panel_data">Causal Inference: the Mixtape (chapter 8 and 9)</a>, 

[Goodman-Bacon (2021)](https://www.sciencedirect.com/science/article/abs/pii/S0304407621001445)

</details><br />



<details open><summary><b>Callaway and Sant'Anna</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/03-ATTGT.pdf">Callaway and Sant'Anna (2021)</a>

<b>Code</b>

[did in R](https://bcallaway11.github.io/did/), 

[csdid in Stata](https://friosavila.github.io/playingwithstata/main_csdid.html)           

<b>Readings</b>

[Callaway and Sant'Anna (2021)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948?via%3Dihub)

</details><br />



<details open><summary><b>Sun and Abraham</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/03-ATTGT.pdf">Sun and Abraham (2021)</a>

<b>Code</b>

[eventstudyinteract in Stata](https://github.com/lsun20/EventStudyInteract), 

[fixest in R](https://lrberge.github.io/fixest/), 

[Shiny App for Event Study](https://mixtape.shinyapps.io/Event-Study/)

<b>Readings</b>

[Sun and Abraham (2021)](https://www.sciencedirect.com/science/article/abs/pii/S030440762030378X)

</details><br />



<details open><summary><b>Imputation Estimators</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/05-Imputation.pdf">Various imputation estimators</a>

<b>Code</b>

Two-stage DID

[did2s in Stata](https://github.com/kylebutts/did2s_stata)

[did2s in R](https://www.kylebutts.com/open-source/did2s/)

Robust efficient imputation estimator

[did_imputation in Stata](https://github.com/borusyak/did_imputation)

[didimputation in R](https://github.com/kylebutts/didimputation)
           

<b>Readings</b>

[Borusyak, et al. (2022)](https://arxiv.org/abs/2108.12419)

[Gardner (2021)](https://jrgcmu.github.io/2sdd_current.pdf)
</details><br />



<details open><summary><b>Stacking</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/04-Stacking.pdf">Cengiz, et al. (2019)</a>

<b>Code</b>

[stackdev in Stata (under development)](https://asjadnaqvi.github.io/DiD/docs/code/06_stackedev/)           

<b>Readings</b>

[Cengiz, et al. (2019)](https://academic.oup.com/qje/article/134/3/1405/5484905)
</details><br />



<details open><summary><b>Continuous Treatment Diff-in-Diff</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/07-Non-binary.pdf">Callaway, Goodman-Bacon and Sant'Anna (2021)</a>

<b>Code</b>
           

<b>Readings</b>

[Callaway, Goodman-Bacon and Sant'Anna (2021)](https://arxiv.org/abs/2107.02637)

</details><br />

<details open><summary><b>Synthetic Control</b></summary><br/>

<b>Slides</b>
           
<a href="https://github.com/Mixtape-Sessions/Causal-Inference-2/blob/main/Slides/06-Synthetic.pdf">Abadie, Diamond and Hainmueller (2010)</a>

<b>Code</b>

[synth in Stata](https://ideas.repec.org/c/boc/bocode/s457334.html)  

[synth in R](https://cran.r-project.org/web/packages/Synth/Synth.pdf)      

<b>Readings</b>

[Abadie and Gardeazabal (2003)](https://www.aeaweb.org/articles?id=10.1257/000282803321455188)

[Abadie, Diamond and Hainmueller (2010)](https://web.stanford.edu/~jhain/Paper/JASA2010.pdf)


</details><br />


