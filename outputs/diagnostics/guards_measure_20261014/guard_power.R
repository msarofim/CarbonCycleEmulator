# Power check: does ccx_run() refuse each mismatch? Fake spin; the guards sit before any use of y/aux/grid.
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
F <- data.frame(t = 2000 + (0:11) / 12)                      # UNSTAMPED table
cases <- list(enso = list(enso_index = 1L), aod = list(aod_mode = 1L),
              nuc = list(nuc_share_ts = 1L), ndep = list(ndep_ret = 0.5), none = list())
for (nm in names(cases)) {
  msg <- tryCatch({ ccx_run(list(params = cases[[nm]], y = NULL, aux = NULL, grid = NULL), F); "ran" },
                  error = function(e) conditionMessage(e))
  cat(sprintf("%-5s %s\n", nm, substr(gsub("\n", " ", msg), 1, 90)))
}
