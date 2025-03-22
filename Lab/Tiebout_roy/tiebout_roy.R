# Set random seed for reproducibility
set.seed(123)

# Define population parameters
num_people <- 30000000
num_large_counties <- 5
num_small_counties <- 249
total_counties <- num_large_counties + num_small_counties

# Define county populations
large_county_pop <- 3000000  # 3M each for large counties
small_county_pop <- 15000000 / num_small_counties  # Remaining split equally

# Create data frame to store individual-level data
df <- data.frame(id = 1:num_people)

# Generate individual-level potential outcomes
df$y0 <- rnorm(num_people, mean = 10, sd = 2)
df$treatment_effect <- rnorm(num_people, mean = 2, sd = 1)
df$y1 <- df$y0 + df$treatment_effect
df$individual_ate <- df$y1 - df$y0

# Initialize county column
df$county <- NA

# Assign the five largest counties first (3M people each)
for (i in 1:num_large_counties) {
  start_idx <- (i-1) * large_county_pop + 1
  end_idx <- i * large_county_pop
  df$county[start_idx:end_idx] <- i
}

# For the remaining people, randomly assign to small counties
# Generate a random sorting variable for unassigned people
remaining_indices <- which(is.na(df$county))
df$random_sort <- NA
df$random_sort[remaining_indices] <- runif(length(remaining_indices))

# Sort the remaining observations by this random variable
df_sorted <- df[order(is.na(df$county), df$random_sort), ]

# Assign the remaining people to small counties in random order
remaining_people <- num_people - (num_large_counties * large_county_pop)
people_per_small_county <- ceiling(small_county_pop)  # Round up to ensure all people are assigned

current_person <- (num_large_counties * large_county_pop) + 1
for (i in 1:num_small_counties) {
  county_num <- i + num_large_counties
  end_person <- min(current_person + people_per_small_county - 1, num_people)
  df_sorted$county[current_person:end_person] <- county_num
  current_person <- end_person + 1
  
  # Break if we've assigned everyone
  if (current_person > num_people) break
}

# Re-sort by ID to restore original order if needed
df <- df_sorted[order(df_sorted$id), ]

# Calculate ATEs
overall_ate <- mean(df$individual_ate)

# Create county-level dataset
county_summary <- aggregate(
  individual_ate ~ county, 
  data = df, 
  FUN = function(x) c(mean = mean(x), count = length(x))
)

# Extract the county-level ATEs
county_ates <- county_summary$individual_ate[, "mean"]
county_level_ate <- mean(county_ates)

# Sort counties by ATE for visualization
sorted_indices <- order(county_ates)
sorted_ates <- county_ates[sorted_indices]
sorted_counties <- county_summary$county[sorted_indices]

# Create plot
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
  annotate("text", x = total_counties * 0.8, y = overall_ate + 0.1,
           label = sprintf("Overall ATE = %.2f", overall_ate)) +
  annotate("text", x = total_counties * 0.8, y = county_level_ate - 0.1,
           label = sprintf("County Average ATE = %.2f", county_level_ate)) +
  labs(
    title = "County-Level Average Treatment Effects (Random Assignment)",
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

# Print the means to verify they're close
cat("Overall ATE:", sprintf("%.4f", overall_ate), "\n")
cat("County-level Average ATE:", sprintf("%.4f", county_level_ate), "\n")

# Verify the county sizes
large_county_counts <- table(df$county[df$county <= num_large_counties])
small_county_counts <- table(df$county[df$county > num_large_counties])

cat("\nLarge county population sizes:\n")
print(large_county_counts)

cat("\nSmall county population statistics:\n")
print(summary(as.numeric(small_county_counts)))

# Save the plot if needed
# ggsave("county_ate_plot.png", p, width = 12, height = 6, dpi = 300)