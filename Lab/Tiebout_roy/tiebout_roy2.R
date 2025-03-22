# Set random seed for reproducibility
set.seed(123)

# Define population parameters
num_people <- 30000000
num_large_counties <- 5
num_small_counties <- 249
total_counties <- num_large_counties + num_small_counties

# Define county populations
large_county_pop <- 3000000  # 3M each for large counties
total_large_pop <- large_county_pop * num_large_counties
small_county_pop <- 60241    # Adjusted to make total population exact

# Create data frame for individuals
df <- data.frame(id = 1:num_people)

# Generate treatment effects with two different distributions
# For positive effects: Normal distribution with mean 5 and SD 1
half_people <- num_people %/% 2
positive_effects <- rnorm(half_people, mean = 5, sd = 1)

# For negative effects: Normal distribution with mean -1 and SD 0.5
negative_effects <- rnorm(num_people - half_people, mean = -1, sd = 0.5)

# Combine the effects
df$treatment_effect <- c(positive_effects, negative_effects)

# Sort individuals by treatment effect in descending order
df <- df[order(df$treatment_effect, decreasing = TRUE), ]
df$sorted_index <- 1:nrow(df)

# Initialize county assignments
df$county <- NA

# Assign first 15M people (highest treatment effects) to large counties
current_idx <- 1
for (i in 1:num_large_counties) {
  end_idx <- current_idx + large_county_pop - 1
  df$county[current_idx:end_idx] <- i
  current_idx <- end_idx + 1
}

# Assign remaining to small counties
for (i in 1:num_small_counties) {
  county_num <- i + num_large_counties
  end_idx <- min(current_idx + small_county_pop - 1, num_people)
  df$county[current_idx:end_idx] <- county_num
  current_idx <- end_idx + 1
  
  # Break if all people are assigned
  if (current_idx > num_people) break
}

# Calculate ATEs
overall_ate <- mean(df$treatment_effect)  # Population average

# Create county-level dataset
county_summary <- aggregate(
  treatment_effect ~ county, 
  data = df, 
  FUN = function(x) c(mean = mean(x), count = length(x))
)

# Extract county-level ATEs
county_ates <- county_summary$treatment_effect[, "mean"]
names(county_ates) <- county_summary$county
county_level_ate <- mean(county_ates)  # Average of county averages

# Sort counties by ATE for visualization
sorted_indices <- order(county_ates)
sorted_ates <- county_ates[sorted_indices]
sorted_counties <- as.numeric(names(sorted_ates))

# Create plot using ggplot2
library(ggplot2)

# Prepare data for plotting
plot_data <- data.frame(
  county_index = 1:length(sorted_ates),
  county = sorted_counties,
  ate = sorted_ates
)

# Create the plot
p <- ggplot(plot_data, aes(x = county_index, y = ate)) +
  geom_bar(stat = "identity", fill = "blue", alpha = 0.7, color = "black") +
  geom_hline(yintercept = overall_ate, linetype = "dashed", color = "black", size = 1) +
  geom_hline(yintercept = county_level_ate, linetype = "dashed", color = "red", size = 1) +
  annotate("text", x = total_counties * 0.8, y = overall_ate + 0.5,
           label = sprintf("Overall ATE = %.2f", overall_ate)) +
  annotate("text", x = total_counties * 0.8, y = county_level_ate - 0.5,
           label = sprintf("County Average ATE = %.2f", county_level_ate)) +
  labs(
    title = "County-Level Average Treatment Effects",
    subtitle = "Counties sorted by treatment effect",
    x = "County Index",
    y = "Average Treatment Effect (ATE)"
  ) +
  theme_minimal() +
  theme(
    panel.grid.minor = element_line(color = "gray90"),
    panel.grid.major = element_line(color = "gray80")
  )

# Display the plot
print(p)

# Print values to verify
cat("Overall ATE:", sprintf("%.4f", overall_ate), "\n")
cat("County-level Average ATE:", sprintf("%.4f", county_level_ate), "\n\n")

# Print first 5 and last 5 county ATEs
cat("First 5 county ATEs:\n")
head_ates <- head(county_ates[order(as.numeric(names(county_ates)))], 5)
print(head_ates)

cat("\nLast 5 county ATEs:\n")
tail_ates <- tail(county_ates[order(as.numeric(names(county_ates)))], 5)
print(tail_ates)

# Verify county sizes
large_counties <- df$county <= num_large_counties
small_counties <- df$county > num_large_counties

cat("\nLarge county sizes:\n")
print(table(df$county[large_counties]))

cat("\nSmall county statistics:\n")
small_county_sizes <- table(df$county[small_counties])
print(summary(as.numeric(small_county_sizes)))

# Optional: Return to original sort order if needed
df <- df[order(df$id), ]

# Save the plot if needed
# ggsave("county_ate_plot.png", p, width = 12, height = 6, dpi = 300)