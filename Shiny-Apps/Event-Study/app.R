## -----------------------------------------------------------------------------
## app.R
## Kyle Butts, CU Boulder Economics
##
## This is a shiny application to highlight the pitfalls with TWFE estimation of 
## Event-Studies
## -----------------------------------------------------------------------------

library(shiny)
library(shiny.tailwind)
library(tidyverse)
library(fixest)
library(did)
library(did2s)
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
    gradient_header("Event-Study and Staggered Treatment", from = "#F2994A", to = "#F2C94C"),
    div(
      class = "mt-6 prose lg:prose-lg xl:prose-xl",
      p("To build some intuition behind the problems of event-study OLS estimates in staggered treatment settings, we built this app to see how different treatment effect heterogeneity can create problems. Note that the data is generated satisfying parallel trends, so differences in outcomes is entirely due to treatment effects."),
      p("Play around the presets below (or try your own DGP!) to see when OLS estimates are particularly problematic")
    ),
    border_container(
      class = "my-4",
      plotOutput("dgp"),
      # Inputs
      div(class = "hide_grid",
        class = "my-4 grid grid-cols-1 md:grid-cols-2 gap-y-4",
        div(
          caps_header("Treatment Group 1"),
          sliderInput("te1", "Treatment Effect:", 2, min = -10, max = 10),
          sliderInput("te_m1", "Treatment Effect Slope:", value = 0.4, min = -1, max = 1, step = 0.05),
          sliderInput("g1", "Treatment Date:", value = 2004, min = 2001, max = 2019, step = 1, sep = "")
        ),
        div(class = "hide_grid",
          caps_header("Treatment Group 2"),
          sliderInput("te2", "Treatment Effect:", 1, min = -10, max = 10),
          sliderInput("te_m2", "Treatment Effect Slope:", value = 0.2, min = -1, max = 1, step = 0.05),
          sliderInput("g2", "Treatment Date:", value = 2012, min = 2001, max = 2019, step = 1, sep = "")
        ),
        div(class = "hide_grid",
          caps_header("Group 3"),
          twCheckboxInput(
            "is_treated3",
            label = "Last Group Treated?", value = FALSE,
            container_class = "flex items-center mt-4 mb-2",
            label_class = "ml-2 text-sm font-medium text-gray-900",
            input_class = "w-4 h-4 bg-gray-100 rounded border-gray-300 focus:ring-[#00b7ff] text-[#00b7ff] focus:ring-2",
            center = TRUE
          ),
          uiOutput("input_treated3")
        ),
        div(class = "hide_grid",
          caps_header("Panel"),
          sliderInput("panel", "Panel Years:", c(1995, 2020), min = 1980, max = 2030, step = 5, sep = "")
        ),
        div(class="md:col-span-2",
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
      ),
    )
  ),
  # ES Plots are added in code below when Estimate Event Study is clicked
  border_container(
    div(class="flex flex-col items-center",
        tags$button(id = "estimate", type = "button", class = "action-button inline-block border-2 border-[#00b7ff] py-1 px-2 rounded-md bg-[#e6f8ff] text-[#006e99]", "Estimate Event Study")
    ),
    uiOutput(outputId = "es_plots")
  )
)

server <- function(input, output, session) {

  # Gen Data
  df <- reactive({
    # Check if third group is treated
    if (input$is_treated3) {
      g3 <- input$g3
      te3 <- input$te3
      te_m3 <- input$te_m3
    } else {
      g3 <- 0L
      te3 <- 0
      te_m3 <- 0
    }

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
      mutate(year_fe = rnorm(length(year), 0, 1)) %>%
      ungroup() %>%
      mutate(
        treat = (year >= g) & (g %in% input$panel[1]:input$panel[2]),
        rel_year = if_else(g == 0L, Inf, as.numeric(year - g)),
        rel_year_binned = case_when(
          rel_year == Inf ~ Inf,
          rel_year <= -9 ~ -9,
          rel_year >= 9 ~ 9,
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
        dep_var = unit_fe + year_fe + te + te_dynamic + error
      )
  })

  # requires rel_year, estimate, se, ci_lower, ci_upper named as that
  make_es_plot <- function(es, te_true, estimator) {
    max_y <- max(es$ci_upper)

    es <- es %>% mutate(group = "Estimated Effect")
    te_true <- te_true %>% mutate(estimate = te_true, group = "True Effect")
    es <- bind_rows(es, te_true)

    # Stagger true and estimate
    # es <- es %>%
    #     mutate(rel_year_stagg = if_else(group == "True Effect", rel_year - 0.1, rel_year + 0.1))


    max_y <- max(es$estimate)

    ggplot() +
      # 0 effect
      geom_hline(yintercept = 0, linetype = "dashed") +
      geom_vline(xintercept = -0.5, linetype = "dashed") +
      # Confidence Intervals
      geom_linerange(data = es, mapping = aes(x = rel_year, ymin = ci_lower, ymax = ci_upper), color = "grey30") +
      # Estimates
      geom_point(data = es, mapping = aes(x = rel_year, y = estimate, color = group), size = 2) +
      # Label
      geom_label(
        data = data.frame(x = -0.5 - 0.1, y = max_y + 0.25, label = "Treatment Starts ▶"), label.size = NA,
        mapping = aes(x = x, y = y, label = label), size = 5.5, hjust = 1, fontface = 2, inherit.aes = FALSE
      ) +
      scale_x_continuous(breaks = -8:8, minor_breaks = NULL) +
      scale_y_continuous(minor_breaks = NULL) +
      scale_color_manual(values = c("Estimated Effect" = "#013ef5", "True Effect" = "#eb3f25")) +
      labs(x = "Relative Time", y = "Estimate", color = NULL, title = NULL) +
      theme_kyle(base_size = 24) +
      theme(legend.position = "bottom")
  }

  get_true_effects <- function(df) {
    df %>%
      # Keep only treated units
      filter(g > 0) %>%
      group_by(rel_year) %>%
      summarize(te_true = mean(te + te_dynamic)) %>%
      filter(rel_year >= -8 & rel_year <= 8)
  }

  # Presets
  observeEvent(input$preset_hom_effects, {
    updateSliderInput(inputId = "te1", value = input$te1)
    updateSliderInput(inputId = "te2", value = input$te1)
    updateSliderInput(inputId = "te3", value = input$te1)
    updateSliderInput(inputId = "te_m1", value = 0)
    updateSliderInput(inputId = "te_m2", value = 0)
    updateSliderInput(inputId = "te_m3", value = 0)
  })
  observeEvent(input$preset_het_levels, {
    updateSliderInput(inputId = "te1", value = 2)
    updateSliderInput(inputId = "te2", value = input$te1 * 2)
    updateSliderInput(inputId = "te3", value = input$te1 * 1.5)
    updateSliderInput(inputId = "te_m1", value = 0)
    updateSliderInput(inputId = "te_m2", value = 0)
    updateSliderInput(inputId = "te_m3", value = 0)
  })
  observeEvent(input$preset_het_levels_w_slopes, {
    updateSliderInput(inputId = "te1", value = 2)
    updateSliderInput(inputId = "te2", value = input$te1 * 2)
    updateSliderInput(inputId = "te3", value = input$te1 * 1.5)
    updateSliderInput(inputId = "te_m1", value = 0.1)
    updateSliderInput(inputId = "te_m2", value = 0.1)
    updateSliderInput(inputId = "te_m3", value = 0.1)
  })
  observeEvent(input$preset_het_slopes, {
    updateSliderInput(inputId = "te1", value = input$te1)
    updateSliderInput(inputId = "te2", value = input$te1)
    updateSliderInput(inputId = "te3", value = input$te1)
    updateSliderInput(inputId = "te_m1", value = 0.05)
    updateSliderInput(inputId = "te_m2", value = 0.2)
    updateSliderInput(inputId = "te_m3", value = 0.1)
  })
  observeEvent(input$preset_het_levels_slopes, {
    updateSliderInput(inputId = "te1", value = 2)
    updateSliderInput(inputId = "te2", value = input$te1 * 2)
    updateSliderInput(inputId = "te3", value = input$te1* 1.5)
    updateSliderInput(inputId = "te_m1", value = 0.05)
    updateSliderInput(inputId = "te_m2", value = 0.2)
    updateSliderInput(inputId = "te_m3", value = 0.1)
  })
  # Control Group or Treated
  output$input_treated3 <- renderUI({
    if (input$is_treated3) {
      list(
        sliderInput("te3", "Treatment Effect:", 0, min = -10, max = 10),
        sliderInput("te_m3", "Treatment Effect Slope:", value = 0, min = -1, max = 1, step = 0.05),
        sliderInput("g3", "Treatment Date:", value = 2016, min = input$g2, max = 2019, step = 1, sep = "")
      )
    }
  })

  # Panel length changed
  observeEvent(input$panel, {
    if (input$is_treated3) {
      updateSliderInput(inputId = "g1", min = input$panel[1] + 2, max = input$panel[2] - 2)
      updateSliderInput(inputId = "g2", min = input$panel[1] + 2, max = input$panel[2] - 2)
      updateSliderInput(inputId = "g3", min = input$panel[1] + 2, max = input$panel[2] - 2)
    } else {
      updateSliderInput(inputId = "g1", min = input$panel[1] + 2, max = input$panel[2] - 2)
      updateSliderInput(inputId = "g2", min = input$panel[1] + 2, max = input$panel[2] - 2)
    }
  })

  # Change treatment year
  observeEvent(input$g1 | input$g2 | input$g3, {
    if (input$is_treated3) {
      updateSliderInput(inputId = "g1", min = input$panel[1] + 2, max = input$g2 - 2)
      updateSliderInput(inputId = "g2", min = input$g1 + 2, max = input$panel[2] - 4)
      updateSliderInput(inputId = "g3", min = input$g2 + 2, max = input$panel[2] - 2)
    } else {
      updateSliderInput(inputId = "g1", min = input$panel[1] + 2, max = input$g2 - 2)
      updateSliderInput(inputId = "g2", min = input$g1 + 2, max = input$panel[2] - 2)
    }
  })


  output$dgp <- renderPlot(
    {
      df <- df()

      df_avg <- df %>%
        group_by(group, year) %>%
        summarize(dep_var = mean(dep_var), .groups = "drop")

      max_y <- max(df_avg$dep_var)


      ggplot() +
        geom_line(data = df_avg, mapping = aes(y = dep_var, x = year, color = group), size = 1.5) +
        geom_vline(xintercept = input$g1 - 0.5, linetype = "dashed") +
        geom_vline(xintercept = input$g2 - 0.5, linetype = "dashed") +
        {
          if (input$is_treated3) geom_vline(xintercept = input$g3 - 0.5, linetype = "dashed")
        } +
        theme_kyle(base_size = 24) +
        theme(legend.position = "bottom") +
        labs(y = "Outcome", x = "Year", color = "Treatment Cohort") +
        scale_y_continuous(expand = expansion(add = .5)) +
        scale_color_manual(values = c("Group 1" = "#d2382c", "Group 2" = "#497eb3", "Group 3" = "#8e549f")) +
        geom_label(
          data = data.frame(x = input$g1 - 0.4, y = max_y + 0.5, label = "◀ Treatment Starts"), label.size = NA,
          mapping = aes(x = x, y = y, label = label), size = 4.23, hjust = 0L, fontface = 2, inherit.aes = FALSE
        ) +
        geom_label(
          data = data.frame(x = input$g2 - 0.4, y = max_y + 0.75, label = "◀ Treatment Starts"), label.size = NA,
          mapping = aes(x = x, y = y, label = label), size = 4.23, hjust = 0L, fontface = 2, inherit.aes = FALSE
        ) +
        {
          if (input$is_treated3) {
            geom_label(
              data = data.frame(x = input$g3 - 0.4, y = max_y + 0.75, label = "◀ Treatment Starts"), label.size = NA,
              mapping = aes(x = x, y = y, label = label), size = 4.23, hjust = 0L, fontface = 2, inherit.aes = FALSE
            )
          }
        }
    },
    res = 96
  )



  # When Estimate Event Study is clicked
  observeEvent(input$estimate, {
    output$es_plots <- renderUI({
      div(class = "mt-8 grid grid-cols-1 lg:grid-cols-2 gap-8 px-8",
        div(
          caps_header("TWFE Event Study Binned"),
          p("This runs a TWFE Event-Study regression with all lead and legs and binned end periods:"),
          withMathJax("$$Y_{it} = \\alpha_i + \\alpha_t + \\gamma_{\\text{Pre}} \\text{Pre} + \\sum_{k = -8}^{-2} \\gamma_{k}^{lead} D_{it}^k + \\sum_{k = 0}^8 \\gamma_{k}^{lag} D_{it}^k + \\gamma_{\\text{Post}} \\text{Post} + \\varepsilon_{it}$$"),
          plotOutput("es_twfe_binned", height = "600px")
        ),
        div(
          caps_header("TWFE Event Study"),
          p("This runs a TWFE Event-Study regression with all lead and legs besides -1 and the earliest relative time period:"),
          withMathJax("$$Y_{it} = \\alpha_i + \\alpha_t + \\sum_{k = -K+1}^{-2} \\gamma_{k}^{lead} D_{it}^k + \\sum_{k = 0}^L \\gamma_{k}^{lag} D_{it}^k + \\varepsilon_{it}$$"),
          plotOutput("es_twfe", height = "600px")
        ),
        div(
            caps_header("C&S Event Study"),
            p("This runs the R `did` program to estimate event-study parameters following Callaway and Sant'Anna"),
            plotOutput("es_cs", height = "600px")
          ),
        div(
            caps_header("Gardner Event Study"),
            p("This runs the R `did2s` program to estimate event-study parameters following Gardner"),
            plotOutput("es_gardner", height = "600px")
        ),
        div(
            caps_header("S&A Event Study"),
            p("This runs the sunab program from `fixest` to estimate event-study parameters following Sun and Abraham"),
            plotOutput("es_sa", height = "600px")
        )
      )
    })
  })


  es_twfe_binned <- eventReactive(input$estimate, {
    df <- df()

    te_true <- get_true_effects(df)

    formula <- as.formula(glue::glue("dep_var ~ i(rel_year_binned, ref=c(-1, Inf)) | unit + year"))

    mod <- fixest::feols(formula, data = df)

    es <- broom::tidy(mod) %>%
      filter(str_detect(term, "rel_year_binned::")) %>%
      rename(rel_year = term, se = std.error) %>%
      mutate(
        rel_year = as.numeric(str_remove(rel_year, "rel_year_binned::")),
        ci_lower = estimate - 1.96 * se,
        ci_upper = estimate + 1.96 * se
      ) %>%
      filter(rel_year <= 8 & rel_year >= -8) %>%
      bind_rows(tibble(rel_year = -1, estimate = 0, se = 0, ci_lower = 0, ci_upper = 0))

    make_es_plot(es, te_true, "TWFE Event-Study with Binned Endpoints")
  })

  output$es_twfe_binned <- renderPlot({
    es_twfe_binned()
  })

  es_twfe <- eventReactive(input$estimate, {
    df <- df()

    te_true <- get_true_effects(df)

    min_rel_year <- min(df$rel_year, na.rm = TRUE)

    formula <- as.formula(glue::glue("dep_var ~ i(rel_year, ref=c(-1)) | unit + year"))

    mod <- fixest::feols(formula, data = df)

    es <- broom::tidy(mod) %>%
      filter(str_detect(term, "rel_year::")) %>%
      rename(rel_year = term, se = std.error) %>%
      mutate(
        rel_year = as.numeric(str_remove(rel_year, "rel_year::")),
        ci_lower = estimate - 1.96 * se,
        ci_upper = estimate + 1.96 * se
      ) %>%
      filter(rel_year <= 8 & rel_year >= -8) %>%
      bind_rows(tibble(rel_year = -1, estimate = 0, se = 0, ci_lower = 0, ci_upper = 0))

    make_es_plot(es, te_true, "TWFE Event-Study")
  })

  output$es_twfe <- renderPlot({
    es_twfe()
  })

  es_cs <- eventReactive(input$estimate, {
    df <- df()

    te_true <- get_true_effects(df)


    if (input$is_treated3) {
      ctrl <- "notyettreated"
    } else {
      ctrl <- "nevertreated"
    }

    mod <- did::att_gt(
      yname = "dep_var",
      tname = "year",
      idname = "unit",
      gname = "g",
      control_group = ctrl,
      data = df
    ) %>%
      did::aggte(type = "dynamic")

    es <- broom::tidy(mod) %>%
      select(
        rel_year = event.time, estimate, se = std.error, ci_lower = point.conf.low, ci_upper = point.conf.high
      ) %>%
      filter(rel_year <= 8 & rel_year >= -8)

    make_es_plot(es, te_true, "Callaway and Sant'Anna")
  })

  output$es_cs <- renderPlot({
    es_cs()
  })

  es_gardner <- eventReactive(input$estimate, {
    df <- df()

    te_true <- get_true_effects(df)


    mod <- did2s::did2s(
      data = df,
      yname = "dep_var",
      first_stage = ~ 0 | unit + year,
      second_stage = ~ i(rel_year),
      treatment = "treat",
      cluster_var = "state",
      n_bootstraps = 10,
      verbose = F
    )

    es <- broom::tidy(mod) %>%
      filter(str_detect(term, "rel_year::")) %>%
      rename(rel_year = term, se = std.error) %>%
      mutate(
        rel_year = as.numeric(str_remove(rel_year, "rel_year::")),
        ci_lower = estimate - 1.96 * se,
        ci_upper = estimate + 1.96 * se
      ) %>%
      filter(rel_year <= 8 & rel_year >= -8)

    make_es_plot(es, te_true, "Gardner")
  })

  output$es_gardner <- renderPlot({
    es_gardner()
  })

  es_sa <- eventReactive(input$estimate, {
    df <- df()

    te_true <- get_true_effects(df)

    min_rel_year <- min(df$rel_year, na.rm = TRUE)

    formula <- as.formula(glue::glue("dep_var ~ sunab(g, year) | unit + year"))

    mod <- fixest::feols(formula, data = df)

    es <- broom::tidy(mod) %>%
      filter(str_detect(term, "year::")) %>%
      select(rel_year = term, estimate, se = std.error) %>%
      mutate(
        rel_year = as.numeric(str_remove(rel_year, "year::")),
        ci_lower = estimate - 1.96 * se,
        ci_upper = estimate + 1.96 * se
      ) %>%
      filter(rel_year <= 8 & rel_year >= -8) %>%
      bind_rows(tibble(rel_year = -1, estimate = 0, se = 0, ci_lower = 0, ci_upper = 0))

    make_es_plot(es, te_true, "TWFE Event-Study")
  })

  output$es_sa <- renderPlot({
    es_sa()
  })
}

# Run the application
# For Testing
# input <- list(g1 = 2004L, g2 = 2012L, te1 = 2.0, te2 = 2.0, te_m1=1, te_m2=0.5, panel = c(2000, 2020))

shinyApp(ui = ui, server = server)
