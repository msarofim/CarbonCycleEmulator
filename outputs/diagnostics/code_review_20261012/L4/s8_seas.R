suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
for (sc in c("ssp126", "vvL", "vvVL", "ssp119", "ssp245")) for (m in c("spline", "constant")) {
  F <- suppressWarnings(ccx_build_forcing(sc, c(1750, 2300), prod_c14 = 1, emis_method = m, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
  for (h in c("NH","SH")) {
    x <- F[[paste0("e_luc_", h)]]
    a <- tapply(x, F$year, mean); amp <- tapply(x, F$year, function(z) diff(range(z)))
    rat <- amp / pmax(abs(a), 1e-12)
    j <- which.max(amp[as.integer(names(amp)) > 2025]) + sum(as.integer(names(amp)) <= 2025)
    cat(sprintf("%-6s %-8s %s: max within-year range %.3f GtC/yr in %s (annual mean %.4f); median range %.3f\n", sc, m, h, amp[j], names(amp)[j], a[j], median(amp[as.integer(names(amp)) > 2025])))
  }
}
