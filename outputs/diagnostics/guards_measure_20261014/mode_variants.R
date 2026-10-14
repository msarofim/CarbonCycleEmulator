suppressMessages(for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f))
for (m in c("hilda29l", "hilda29e", "hilda31w")) {
  md <- readRDS(ccx_mode_file(m)); p <- ccx_mode_base(md); p[names(md$par_mode)] <- md$par_mode
  cat(sprintf("%-9s struct %-28s enso %-8s aod %-8s nuc %-9s ndep_ret %s\n", m, ccx_mode_struct(md),
      ccx_enso_index_of(p), ccx_aod_mode_of(p), ccx_nuc_share_of(p),
      format(if (is.null(p$ndep_ret)) 0 else p$ndep_ret, digits = 4)))
}
d <- readRDS(ccx_path("data", "forcing_ndep.rds")); cat("ndep file:", class(d), "\n"); str(d, max.level = 1, give.attr = FALSE)
