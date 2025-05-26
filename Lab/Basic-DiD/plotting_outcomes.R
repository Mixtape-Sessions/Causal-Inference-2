# ── libraries ──────────────────────────────────────────────────────────────────
library(dplyr)
library(ggplot2)
library(stringr)

# ── 1. Start with your county‑year panel ──────────────────────────────────────
#   df should have: county_id, year, treat_date (or treat_date5), br1544, …
#   ---------------------------------------------------------------------------
# Example:  df <- readRDS("your_data.rds")

# ── 2. Collapse to cohort‑year means (Stata's 'collapse (mean) … , by()') ────
birth_means <- df %>% 
  group_by(treat_date, year) %>% 
  summarise(br1544 = mean(br1544, na.rm = TRUE), .groups = "drop")

# ── 3. Create nice labels and the red vertical reference line for each cohort ─
birth_means <- birth_means %>% 
  mutate(label = case_when(
    treat_date == 2020 ~ "never treated",
    treat_date == 2030 ~ "2008‑2010 cohorts",
    TRUE               ~ str_c(treat_date, " cohort")
  ),
  rline = case_when(                # red dashed line
    treat_date == 2020 ~ NA_real_,  # none for never‑treated
    treat_date == 2030 ~ 2008,      # midpoint of 2008‑10
    TRUE               ~ treat_date # treatment start year
  ))

# ── 4. Build the plot ─────────────────────────────────────────────────────────
#   two layers: (i) all cohorts in grey, (ii) highlighted cohort in blue
#   Facet so each cohort gets its own panel.
plot_births <- ggplot(birth_means, aes(year, br1544, group = treat_date)) +
  
  # grey background trajectories
  geom_line(colour = "grey70", alpha = 0.7) +
  
  # blue focal trajectory
  geom_line(colour = "blue", size = 1) +
  
  # red dashed reference line (draw only when rline is not NA)
  geom_vline(data = birth_means %>% distinct(label, rline) %>% 
               filter(!is.na(rline)),
             aes(xintercept = rline),
             colour = "red", linetype = "dashed") +
  
  facet_wrap(~ label, ncol = 4) +
  
  scale_x_continuous(limits = c(1995, 2007),
                     breaks  = seq(1995, 2007, 2)) +
  labs(title    = "Average Births per 1,000 females by Cohort",
       subtitle = "15‑44 year olds",
       x = NULL, y = NULL) +
  theme_bw() +
  theme(strip.text      = element_text(size = 10),
        plot.title      = element_text(size = 16, face = "bold", hjust = .5),
        plot.subtitle   = element_text(size = 12, hjust = .5),
        panel.grid.minor = element_blank())

# ── 5. Save ────────────────────────────────────────────────────────────────────
ggsave("../figures/msa_pretty_births.png",
       plot_births, width = 10, height = 8, dpi = 300)