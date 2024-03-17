## -----------------------------------------------------------------------------
## app.R
## Kyle Butts, CU Boulder Economics
##
## This is a shiny application to view the Goodman-Bacon decomposition
## -----------------------------------------------------------------------------

library(shiny)
library(shiny.tailwind)
library(tidyverse)
library(fixest)
library(did)
library(bacondecomp)
library(kfbmisc)

source("components.R")


ui <- page(
  mid_wrapper(
    shiny.tailwind::use_tailwind(
      css = "style.css",
      tailwindConfig = "tailwind.config.js"
    ),
    shiny::withMathJax(),
    # Header
    gradient_header("Bacon Decomposition", from = "#F2994A", to = "#F2C94C"),
    div(
      class = "mt-6 prose lg:prose-lg xl:prose-xl",
      p("To build some intuition behind the Bacon Decomposition and the 'forbidden comparisons', we built this app to see how different treatment effect heterogeneity can create problems. Note that the data is generated satisfying parallel trends, so differences in outcomes is entirely due to treatment effects."),
      p("Play around the presets below (or try your own DGP!) to see when 'forbidden comparisons' are particularly problematic.")
    ),
    border_container(
      class = "my-4",
      plotOutput("dgp"),
      # Inputs
      div(
        class = "my-4 grid grid-cols-1 md:grid-cols-2 gap-y-4",
        div(
          class = "hide_grid",
          caps_header("Treatment Group 1"),
          sliderInput("te1", "Treatment Effect:", 2, min = -10, max = 10),
          sliderInput("te_m1", "Treatment Effect Slope:", value = 0.4, min = -1, max = 1, step = 0.05),
          sliderInput("g1", "Treatment Date:", value = 2004, min = 2001, max = 2019, step = 1, sep = "")
        ),
        div(
          class = "hide_grid",
          caps_header("Treatment Group 2"),
          sliderInput("te2", "Treatment Effect:", 1, min = -10, max = 10),
          sliderInput("te_m2", "Treatment Effect Slope:", value = 0.2, min = -1, max = 1, step = 0.05),
          sliderInput("g2", "Treatment Date:", value = 2012, min = 2001, max = 2019, step = 1, sep = "")
        ),
        div(
          class = "hide_grid",
          caps_header("Panel"),
          sliderInput("panel", "Panel Years:", c(2000, 2020), min = 1980, max = 2030, step = 5, sep = "")
        ),
        div(
          caps_header("Presets"),
          div(
            class = "flex flex-wrap gap-4",
            tags$button(id = "preset_hom_effects", type = "button", class = "action-button inline-block border-2 border-[#00b7ff] py-1 px-2 rounded-md bg-[#e6f8ff] text-[#006e99]", "Homogeneous Effects"),
            tags$button(id = "preset_het_levels", type = "button", class = "action-button inline-block border-2 border-[#00b7ff] py-1 px-2 rounded-md bg-[#e6f8ff] text-[#006e99]", "Heterogeneity in Levels"),
            tags$button(id = "preset_het_levels_w_slopes", type = "button", class = "action-button inline-block border-2 border-[#00b7ff] py-1 px-2 rounded-md bg-[#e6f8ff] text-[#006e99]", "Heterogeneity in Levels (with Slopes)"),
            tags$button(id = "preset_het_slopes", type = "button", class = "action-button inline-block border-2 border-[#00b7ff] py-1 px-2 rounded-md bg-[#e6f8ff] text-[#006e99]", "Heterogeneity in Slopes"),
            tags$button(id = "preset_het_levels_slopes", type = "button", class = "action-button inline-block border-2 border-[#00b7ff] py-1 px-2 rounded-md bg-[#e6f8ff] text-[#006e99]", "Heterogeneity in Levels and Slopes")
          )
        )
      )
    ),
    div(
      class = "mt-6 prose lg:prose-lg xl:prose-xl",
      p("Below we show the 4 two-by-two difference-in-differences estimates. In particular, the last plot which uses the earlier treated as the 'control group' is the 'forbidden comparison'.")
    ),
    border_container(
      class = "mt-8",
      uiOutput("estimate")
    ),
  ),
  div(
    border_container(
      class = "mt-8 grid grid-cols-1 lg:grid-cols-2 gap-y-4",
      plotOutput("did_one", width = "100%", height = "100%"),
      plotOutput("did_two", width = "100%", height = "100%"),
      plotOutput("did_three", width = "100%", height = "100%"),
      plotOutput("did_four", width = "100%", height = "100%")
    )
  )
)

server <- function(input, output, session) {
  # options
  observeEvent(input$panel, {
    updateSliderInput(inputId = "g1", min = input$panel[1] + 2, max = input$panel[2] - 2)
    updateSliderInput(inputId = "g2", min = input$panel[1] + 2, max = input$panel[2] - 2)
  })
  observeEvent(input$g1 | input$g2, {
    updateSliderInput(inputId = "g1", min = input$panel[1] + 2, max = input$g2 - 2)
    updateSliderInput(inputId = "g2", min = input$g1 + 2, max = input$panel[2] - 2)
  })

  # Presets
  observeEvent(input$preset_hom_effects, {
    updateSliderInput(inputId = "te1", value = input$te1)
    updateSliderInput(inputId = "te2", value = input$te1)
    updateSliderInput(inputId = "te_m1", value = 0)
    updateSliderInput(inputId = "te_m2", value = 0)
  })
  observeEvent(input$preset_het_levels, {
    updateSliderInput(inputId = "te1", value = 2)
    updateSliderInput(inputId = "te2", value = input$te1 * 2)
    updateSliderInput(inputId = "te_m1", value = 0)
    updateSliderInput(inputId = "te_m2", value = 0)
  })
  observeEvent(input$preset_het_levels_w_slopes, {
    updateSliderInput(inputId = "te1", value = 2)
    updateSliderInput(inputId = "te2", value = input$te1 * 2)
    updateSliderInput(inputId = "te_m1", value = 0.1)
    updateSliderInput(inputId = "te_m2", value = 0.1)
  })
  observeEvent(input$preset_het_slopes, {
    updateSliderInput(inputId = "te1", value = input$te1)
    updateSliderInput(inputId = "te2", value = input$te1)
    updateSliderInput(inputId = "te_m1", value = 0.05)
    updateSliderInput(inputId = "te_m2", value = 0.2)
  })
  observeEvent(input$preset_het_levels_slopes, {
    updateSliderInput(inputId = "te1", value = 2)
    updateSliderInput(inputId = "te2", value = input$te1 * 2)
    updateSliderInput(inputId = "te_m1", value = 0.05)
    updateSliderInput(inputId = "te_m2", value = 0.2)
  })

  # Generate data and plot the DGP
  df <- reactive({
    g3 <- 0L
    te3 <- 0
    te_m3 <- 0

    tibble(unit = 1:1000) %>%
      mutate(
        state = sample(1:40, n(), replace = TRUE),
        unit_fe = rnorm(n(), state / 5, 1),
        group = runif(n()),
        group = case_when(
          group < 0.33 ~ "Group 1",
          group < 0.66 ~ "Group 2",
          TRUE ~ "Group 3"
        ),
        g = case_when(
          group == "Group 1" ~ input$g1,
          group == "Group 2" ~ input$g2,
          group == "Group 3" ~ g3,
        )
      ) %>%
      expand_grid(year = input$panel[1]:input$panel[2]) %>%
      # Year FE
      group_by(year) %>%
      mutate(year_fe = rnorm(n(), (year - input$panel[1]) / 4, 1)) %>%
      ungroup() %>%
      mutate(
        treat = (year >= g) & (g %in% input$panel[1]:input$panel[2]),
        rel_year = if_else(g == 0L, Inf, as.numeric(year - g)),
        rel_year_binned = case_when(
          rel_year == Inf ~ Inf,
          rel_year <= -6 ~ -6,
          rel_year >= 6 ~ 6,
          TRUE ~ rel_year
        ),
        error = rnorm(n(), 0, 1),
        # Level Effect
        te =
          (group == "Group 1") * input$te1 * (year >= input$g1) +
            (group == "Group 2") * input$te2 * (year >= input$g2) +
            (group == "Group 3") * te3 * (year >= g3),
        # dynamic Effect
        te_dynamic =
          (group == "Group 1") * (year >= input$g1) * input$te_m1 * (year - input$g1) +
            (group == "Group 2") * (year >= input$g2) * input$te_m2 * (year - input$g2) +
            (group == "Group 3") * (year >= g3) * te_m3 * (year - g3),
        y0 = unit_fe + year_fe + error,
        # With TE level shift
        counterfactual = unit_fe + year_fe + te + error,
        dep_var = unit_fe + year_fe + te + te_dynamic + error
      )
  })
  output$dgp <- renderPlot(
    {
      df <- df()

      df_avg <- df %>%
        group_by(group, year) %>%
        summarize(dep_var = mean(dep_var), .groups = "drop")

      max_y <- max(df_avg$dep_var)

      ggplot() +
        geom_line(data = df_avg, mapping = aes(y = dep_var, x = year, color = group), linewidth = 1.5) +
        geom_vline(xintercept = input$g1 - 0.5, linetype = "dashed") +
        geom_vline(xintercept = input$g2 - 0.5, linetype = "dashed") +
        theme_kyle(base_size = 13) +
        theme(
          legend.location = "plot",
          legend.position = "top",
          legend.margin = margin(0, 0, 4, 0),
          legend.justification = c(0, 1),
        ) +
        labs(y = NULL, x = NULL, title = "Data-Generating Process", color = NULL) +
        scale_y_continuous(expand = expansion(add = 1)) +
        scale_color_manual(values = c("Group 1" = "#d2382c", "Group 2" = "#497eb3", "Group 3" = "#8e549f")) +
        # guides(color = guide_legend(nrow = 2)) +
        geom_label(
          data = data.frame(x = input$g1 - 0.4, y = max_y + 0.75, label = "Group 1 Starts Treatment"), label.size = NA,
          mapping = aes(x = x, y = y, label = label), 
          size = 3.5, hjust = 0L, fontface = 2, inherit.aes = FALSE
        ) +
        geom_label(
          data = data.frame(x = input$g2 - 0.4, y = max_y + 0.75, label = "Group 2 Starts Treatment"), label.size = NA,
          mapping = aes(x = x, y = y, label = label), 
          size = 3.5, hjust = 0L, fontface = 2, inherit.aes = FALSE
        )
    },
    res = 96
  )

  # Bacon Decomposition and display the OLS estimate
  subset_data <- function(df, treat_g, control_g) {
    # Treated vs. Untreated
    if (control_g == 0) {
      min_year <- -Inf
      max_year <- Inf
      # Early vs. Late (before late is treated)
    } else if (treat_g < control_g) {
      min_year <- -Inf
      max_year <- control_g
      # Late vs. Early (after early is treated)
    } else if (control_g < treat_g) {
      min_year <- control_g
      max_year <- Inf
    }

    df_subset <- df %>%
      filter(g %in% c(treat_g, control_g)) %>%
      filter(year >= min_year & year < max_year) %>%
      mutate(
        treated = case_when(
          g == treat_g ~ "Treat Group",
          g == control_g ~ "Control Group"
        )
      )

    return(df_subset)
  }
  two_by_twos <- reactive({
    df <- df()

    # Weights from	`bacondecomp` package
    gs <- unique(df$g)

    two_by_twos <- expand_grid(treat_g = gs, control_g = gs) %>%
      filter(treat_g != control_g) %>%
      filter(treat_g != 0) %>%
      mutate(weight = 0, est = 0)

    for (i in 1:nrow(two_by_twos)) {
      treat_g <- two_by_twos[i, ][["treat_g"]]
      control_g <- two_by_twos[i, ][["control_g"]]

      df_subset <- subset_data(df, treat_g, control_g)

      # Weights from `bacondecomp`

      # Treated vs. Untreated
      if (control_g == 0) {
        n_u <- sum(df_subset$g == control_g)
        n_k <- sum(df_subset$g == treat_g)
        n_ku <- n_k / (n_k + n_u)
        D_k <- mean(df_subset[df_subset$g == treat_g, ][["treat"]])
        V_ku <- n_ku * (1 - n_ku) * D_k * (1 - D_k)
        weight1 <- (n_k + n_u)^2 * V_ku
        # Early vs. Late (before late is treated)
      } else if (treat_g < control_g) {
        n_k <- sum(df_subset$g == treat_g)
        n_l <- sum(df_subset$g == control_g)
        n_kl <- n_k / (n_k + n_l)
        D_k <- mean(df_subset[df_subset$g == treat_g, ][["treat"]])
        D_l <- mean(df_subset[df_subset$g == control_g, ][["treat"]])
        V_kl <- n_kl * (1 - n_kl) * (D_k - D_l) / (1 - D_l) * (1 - D_k) / (1 - D_l)
        weight1 <- ((n_k + n_l) * (1 - D_l))^2 * V_kl
        # Late vs. Early (after early is treated)
      } else if (control_g < treat_g) {
        n_k <- sum(df_subset$g == control_g)
        n_l <- sum(df_subset$g == treat_g)
        n_kl <- n_k / (n_k + n_l)
        D_k <- mean(df_subset[df_subset$g == control_g, ][["treat"]])
        D_l <- mean(df_subset[df_subset$g == treat_g, ][["treat"]])
        V_kl <- n_kl * (1 - n_kl) * (D_l / D_k) * (D_k - D_l) / (D_k)
        weight1 <- ((n_k + n_l) * D_k)^2 * V_kl
      }

      # Estimate TWFE on subsample
      df_subset$treat <- df_subset$treat & (df_subset$g == treat_g)

      est <- fixest::feols(dep_var ~ treat | unit + year, data = df_subset) %>%
        coef() %>%
        .[["treatTRUE"]]

      # Store results
      two_by_twos[i, "weight"] <- weight1
      two_by_twos[i, "est"] <- est
    }

    two_by_twos <- two_by_twos %>%
      mutate(weight = weight / sum(weight))

    two_by_twos
  })
  output$estimate <- renderUI({
    true_te <- df() %>%
      filter(treat == TRUE) %>%
      summarize(te = mean(te + te_dynamic)) %>%
      .[[1, 1]]

    two_by_twos <- two_by_twos()

    # Create decomposition string
    est <- round(two_by_twos$est, 2)
    weight <- round(two_by_twos$weight, 2)
    temp <- c()
    for (i in 1:length(est)) {
      temp[i] <- glue::glue("{est[i]}*{weight[i]}")
    }
    str <- glue::glue("$$\\hat\\tau = {paste0(temp, collapse=' + ')} = {round(sum(est * weight), 2)} $$")

    div(
      class = "flex flex-col items-center gap-y-2",
      withMathJax(glue::glue("$$\\tau = {round(true_te,2)}$$")),
      withMathJax(str)
    )
  })

  # Plot 2x2s
  plot_bacon <- function(df, two_by_twos, treat_g, control_g) {
    df_subset <- subset_data(df, treat_g, control_g)

    est <- two_by_twos[two_by_twos$treat_g == treat_g & two_by_twos$control_g == control_g, ][["est"]]
    weight <- two_by_twos[two_by_twos$treat_g == treat_g & two_by_twos$control_g == control_g, ][["weight"]]

    # Plot -----------------------------------------------------------------

    df_avg <- df %>%
      group_by(group, year) %>%
      summarize(dep_var = mean(dep_var), .groups = "drop")

    df_subset_avg <- df_subset %>%
      group_by(group, treated, year) %>%
      summarize(dep_var = mean(dep_var), counterfactual = mean(counterfactual), .groups = "drop")

    max_y <- max(df_avg$dep_var)

    # Assemble text
    subtitle <- glue::glue("<strong>Estimate:</strong> {round(est,2)} and <strong>Weight:</strong> {round(weight,3)}")

    # Treated vs. Untreated
    if (control_g == 0) {
      title <- glue::glue("<strong style='color: #d2382c'>Treated</strong>: {treat_g} <br/> <strong style='color: #497eb3'>Control</strong>: Never Treated")

    # Early vs. Late (before late is treated)
    } else if (treat_g < control_g) {
      title <- glue::glue("<strong style='color: #d2382c'>Treated</strong>: {treat_g} <br/> <strong style='color: #497eb3'>Control</strong>: {control_g} (before treated)")

    # Late vs. Early (after early is treated)
    } else if (control_g < treat_g) {
      title <- glue::glue("<strong style='color: #d2382c'>Treated</strong>: {treat_g} <br/> <strong style='color: #497eb3'>Control</strong>: {control_g} (after treated)")
    }

    ggplot() +
      # DGP
      geom_line(
        data = df_avg,
        mapping = aes(y = dep_var, x = year, group = group), color = "grey40", alpha = 0.6, linewidth = 1
      ) +
      # 2x2
      geom_line(
        data = df_subset_avg, 
        mapping = aes(y = dep_var, x = year, group = treated, color = treated), linewidth = 1.5
      ) +
      geom_line(
        data = df_subset_avg, 
        mapping = aes(y = counterfactual, x = year, group = treated, color = treated), 
        linetype = "dashed", linewidth = 1.5, alpha = 0.6
      ) +
      geom_vline(xintercept = treat_g - 0.5, linetype = "dashed") +
      geom_label(
        data = data.frame(x = treat_g - 0.4, y = max_y + 0.75, label = "Treatment Starts"), label.size = NA,
        mapping = aes(x = x, y = y, label = label), 
        size = 4.23, hjust = 0L, fontface = 2, inherit.aes = FALSE
      ) +
      labs(
        y = NULL, x = NULL, 
        color = NULL, linetype = NULL, title = title, subtitle = subtitle
      ) +
      scale_y_continuous(expand = expansion(add = 1)) +
      scale_color_manual(
        values = c("Treat Group" = "#d2382c", "Control Group" = "#497eb3"),
        guide = guide_none()
      ) +
      theme_kyle(base_size = 16) +
      theme(
        legend.position = "bottom",
        axis.title.y = element_text(angle = 90, hjust = 0.5),
        plot.title = ggtext::element_markdown(face = "plain", lineheight = 1.2),
        plot.subtitle = ggtext::element_markdown(size = 18)
      )
  }
  output$did_one <- renderPlot(
    {
      df <- df()
      two_by_twos <- two_by_twos()

      plot_bacon(df, two_by_twos, input$g1, 0)
    },
    height = 500
  )
  output$did_two <- renderPlot(
    {
      df <- df()
      two_by_twos <- two_by_twos()

      plot_bacon(df, two_by_twos, input$g2, 0)
    },
    height = 500
  )
  output$did_three <- renderPlot(
    {
      df <- df()
      two_by_twos <- two_by_twos()

      plot_bacon(df, two_by_twos, input$g1, input$g2)
    },
    height = 500
  )
  output$did_four <- renderPlot(
    {
      df <- df()
      two_by_twos <- two_by_twos()

      plot_bacon(df, two_by_twos, input$g2, input$g1)
    },
    height = 500
  )
}

# Run the application
shinyApp(ui = ui, server = server)
