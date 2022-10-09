
A first code block:

``` stata
sysuse auto
generate gpm = 1/mpg
summarize price gpm
```

    ## 
    ## . sysuse a(1978 Automobile Data)
    ## 
    ## . generate gpm = 1/mpg
    ## 
    ## . summarize price gpm
    ## 
    ##     Variable |        Obs        Mean    Std. Dev.       Min        Max
    ## -------------+---------------------------------------------------------
    ##        price |         74    6165.257    2949.496       3291      15906
    ##          gpm |         74    .0501928    .0127986   .0243902   .0833333

A second, later code block:

``` stata
regress price gpm
```

    ## 
    ## . regress price no variables defined
    ## r(111);
    ## 
    ## end of do-file
    ## r(111);
