#---------------------------------------------------
#     Template to run triple differences
#     Developed by Pedro Sant'Anna as part of
#     Causal Solutions' DiD course
#     The code below is not robust to the inclusion of covariates
#     It will run but the results are not valid under conditional PT for DDD!
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# Load packages
#-----------------------------------------------------------------------------
# install.packages("devtools")
devtools::install_github("pedrohcgs/DRDID", dependencies = TRUE)
devtools::install_github("bcallaway11/did", dependencies = TRUE)
library(did)
library(dplyr)
library(ggplot2)
library(ggthemes)
library(here)
#-----------------------------------------------------------------------------
# Load example data
# Load data
min_wage <- readRDS((here("data",'min_wage_CS.rds')))
# This dataset from Callaway and Sant'Anna (2021, JoE) does not really fall into 
# triple differences setup.
# However, the steps below would be exactly the same under triple differences
# Recall that in triple difference, we have a partition of the units that
# are not exposed to treatment. In this example, I will artificially create such
# partition using the log population of the counties. 
# Again, this is *artificial* to this example. 
# The main goal here is to just illustrate HOW would you "hack" the did package
# to run a triple differences (without covariates).
#-----------------------------------------------------------------------------
# Split data into two groups - I will use lpop just for example to split into 
# " big" and "small" counties within each state. Will create a dummy variable
# where big = 1 if a county is big and 0 otherwise.
min_wage <- min_wage %>%
  group_by(state_name)%>%
  mutate(big = lpop > median(lpop))

# Filter the data among "big counties" (those who are affected by a policy)
min_wage_B <- filter(min_wage, big==TRUE)
# Filter the data among "small counties" (those who are not affected by a policy)
min_wage_A <- filter(min_wage, big==FALSE)
# Important part: these two groups above are non-nested
#-----------------------------------------------------------------------------
# Get pseudo-ATT(g,t)'s for each subset of the data
# These subsets do not have a causal interpretation under our PT for DDD.
# I am turning off bootstrap for speed gains

# Get the pseudo-ATT(g,t) for those "big" counties, using not-yet-treated as
# comparison group
out_B <- att_gt(yname = "lemp",
                gname = "first.treat",
                idname = "countyreal",
                tname = "year",
                xformla = NULL,
                data = min_wage_B,
                est_method = "reg",
                panel = TRUE,
                allow_unbalanced_panel = FALSE,
                control_group = "notyettreated",
                bstrap = FALSE,
                cband = FALSE
)
# Get the pseudo-ATT(g,t) for those "small" counties, using not-yet-treated as
# comparison group

out_A <- att_gt(yname = "lemp",
                gname = "first.treat",
                idname = "countyreal",
                tname = "year",
                xformla = NULL,
                data = min_wage_A,
                est_method = "reg",
                panel = TRUE,
                allow_unbalanced_panel = FALSE,
                control_group = "notyettreated",
                bstrap = FALSE,
                cband = FALSE
)
#-----------------------------------------------------------------------------
# I am assuming we do not care about the ATT(g,t) per se but rather
# that we want an event-study plot to study how treatment effects
# vary with ellapsed treatment timing.

# Now get the event study estimate for each subset of the data.
# Again, I am turning bootstrap off to gain speed
es_B <- aggte(out_B, 
              type = "dynamic", 
              cband = FALSE,
              bstrap = FALSE,
              alp = 0.05,
              biters = 999)
es_A <- aggte(out_A, 
              type = "dynamic", 
              cband = FALSE,
              bstrap = FALSE,
              alp = 0.05, 
              biters = 999)
#-----------------------------------------------------------------------------
# Now, we are ready to compute the difference of event studies!
es_diff_point_estimate <- es_A$att.egt - es_B$att.egt

# Get the influence function for the bootstrap
es_diff_IF <- rbind(es_B$inf.function$dynamic.inf.func.e, 
                    - es_A$inf.function$dynamic.inf.func.e)

# Now we are ready for the bootstrap procedure
# We will cluster at unit id level
set.seed(123)
es_diff_boot <- mboot(es_diff_IF, es_B$DIDparams)
#-----------------------------------------------------------------------------
# Now we are ready to go! Let me put all this into a table
event_study_diff <-  data.frame(
  type          = "dynamic",
  term = paste0('ATT(', es_B$egt, ")"),
  event.time= es_B$egt,
  estimate  = es_diff_point_estimate,
  std.error = es_diff_boot$se,
  conf.low  = es_diff_point_estimate - es_diff_boot$crit.val * es_diff_boot$se,
  conf.high = es_diff_point_estimate + es_diff_boot$crit.val * es_diff_boot$se,
  point.conf.low  = es_diff_point_estimate - 
    stats::qnorm(1 - es_B$DIDparams$alp/2) * es_diff_boot$se,
  point.conf.high = es_diff_point_estimate + 
    stats::qnorm(1 - es_B$DIDparams$alp/2) * es_diff_boot$se
)

# You can now plot them as you want
# ggplot2 theme
theme_set(
  #theme_clean() + 
  theme_classic() +
    theme(plot.background = element_blank(),
          legend.background = element_rect(color = "white"),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.spacing = unit(10, "lines"))
)

# This is one option that I sometimes use when the number of event times is relatively large
p_es_diff1 <- ggplot(data = event_study_diff,
                 mapping = aes(x = event.time, y = estimate)) +
  geom_ribbon(aes(ymin= point.conf.low, ymax=  point.conf.high), alpha = 0.5, size = 1, fill = "steelblue")+
  geom_ribbon(aes(ymin=  conf.low, ymax =  conf.high), alpha =  0.3, size = 1, fill = "steelblue")+
  geom_line(mapping = aes(x = event.time, y=estimate), colour = "black", size = 0.6, linetype = "dashed") +
  geom_line(size = 1.2, alpha = 2, colour = "darkblue") +
  geom_hline(yintercept = 0, colour="black", size = 0.25, linetype = "dotted")+
  xlab('Event time') +
  ylab("Triple-Differences Event-Study Estimate") +
  theme(axis.text.y = element_text(size = 9))+
  theme(axis.text.x = element_text(size = 9)) +
  theme(axis.title = element_text(color="black",  size = 9))+
  theme(plot.title=ggtext::element_markdown(size=9,
                                            #face = "bold",
                                            color="black",
                                            hjust=0,
                                            lineheight=1.2)
  )

p_es_diff1

# This is another one that I use when event times is not that large

p_es_diff2 <- ggplot(data = event_study_diff,
                     mapping = aes(x = event.time, y = estimate)) +
  geom_line(size = 0.5, alpha = 2, colour = "black") +
  geom_hline(yintercept = 0, colour="black",  linetype = "dotted")+
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high), show.legend = FALSE, linetype= 1, size = 0.5,
                  color = "red")+
  geom_pointrange(aes(ymin = point.conf.low, ymax = point.conf.high), show.legend = FALSE, size = 0.5)+
  geom_vline(xintercept = 0-0.1, color = 'grey', size = .05, linetype = "dotted") + 
  xlab("Event time") +
  ylab("Triple-Differences Event Study Estimate") +
  
  #scale_y_continuous(breaks = seq(-600, 200, 200), limits = c(-700,200))+
  theme(axis.text.y = element_text(size = 9))+
  theme(axis.text.x = element_text(size = 9)) +
  theme(axis.title = element_text(color="black",  size = 9))+
  theme(plot.title=ggtext::element_markdown(size=9,
                                            #face = "bold",
                                            color="black",
                                            hjust=0,
                                            lineheight=1.2)
  )

p_es_diff2





