page <- function(...) {
  div(
    class = "w-full min-h-screen py-12 px-4 mb-[12rem]",
    ...
  )
}


mid_wrapper <- function(...) {
  div(
    class = "w-full xl:max-w-[58rem] mx-auto",
    ...
  )
}

border_container <- function(class = "", ...) {
  if(is.character(class)) {
    div(
      class = paste("w-full p-4 bg-white rounded-lg border-2", class),
      ...
    )
  } else {
    div(
      class = paste("w-full p-4 bg-white rounded-lg border-2"),
      class, ...
    )
  }
}


gradient_header <- function(text = "", from = "#67b26f", to = "#4ca2cd") {
  h1(
    class = "border-b-2 border-slate-200",
    span(class = glue::glue("inline-block text-4xl font-black bg-gradient-to-r text-transparent bg-clip-text from-[{from}] to-[{to}]"), text)
  )
}
caps_header <- function(text = "", class="", ...) {
  h3(class = paste("text-[#00b7ff] uppercase text-sm font-semibold mb-4", class), text)
}


twCheckboxInput <- function(inputId, label = NULL, value = FALSE, width = NULL,
                            disabled = FALSE,
                            container_class = NULL, label_class = NULL,
                            input_class = NULL, center = TURE) {
  container_class <- paste("form-check", container_class)
  input_class <- paste("form-check-input", input_class)
  label_class <- paste("form-check-label", label_class)
  
  res <- shiny::div(
    class = container_class,
    style = if (!is.null(width)) paste0("width:", width) else NULL,
    shiny::tags$input(
      type = "checkbox",
      id = inputId,
      style = if (center) "margin: 0px !important;" else NULL,
      checked = if (value) "" else NULL,
      disabled = if (disabled) "" else NULL,
      class = input_class
    ),
    shiny::tags$label(
      class = label_class, "for" = inputId,
      label
    )
  )
  
  return(res)
}


