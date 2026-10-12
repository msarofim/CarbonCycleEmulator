setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/app")
w <- character()
withCallingHandlers(suppressPackageStartupMessages(source("global.R")),
  warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
cat("n warnings:", length(w), "\n"); print(head(sort(table(substr(w, 1, 160)), decreasing = TRUE), 15))
