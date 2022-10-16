################################################################################
# name: baker.R
# author: grant mcdermott (oregon)
# description: creates baker dataset
# last updated: february 20, 2022
################################################################################
set.seed(1234)

# Create the base dataset as a cross-join of 1,000 firms over 30 periods
baker = expand.grid(n = 1:30, id = 1:1000)

# Add additional columns
baker =
  baker |>
  within({
    year       = n + 1980 - 1
    state      = 1 + (id-1) %/% 25
    firms      = runif(id*year, 0, 5)
    group      = 1 + (state-1) %/% 10
    treat_date = 1980 + group*6
    time_til   = year - treat_date
    treat      = time_til>=0
    e          = rnorm(id*year, 0, 0.5^2)
    te         = rnorm(id*year, 10-2*(group-1), 0.2^2)
    y          = firms + n + treat*te*(year - treat_date + 1) + e
    y2         = firms + n + te*treat + e
  })
