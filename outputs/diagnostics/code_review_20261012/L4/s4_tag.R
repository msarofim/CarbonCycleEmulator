suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
sp <- dg_spinup(v)
sc <- "vvM"; Y <- c(1750, 2150); yy <- seq(Y[1], Y[2]); PY <- 2050
s <- ccx_scenario_emissions(sc)
base <- data.frame(year = yy, fossil_GtC = approx(s$year, s$fossil_GtC, yy, rule=2)$y, luc_GtC = approx(s$year, s$luc_GtC, yy, rule=2)$y)
run <- function(em, tb = NULL, m = "constant") ccx_run_coupled(sp, sc, Y, emissions = em, bomb_total_kmol = v$bomb_total,
                     luc_scale = v$luc_scale, interp_method = m, c14_tag_base = tb)
chk <- function(lab, em_p, m = "constant") {
  pu <- run(em_p, NULL, m); tg <- run(em_p, base, m)
  tp <- ccx_tag_partition(tg$out, pu$out, tg$tag)
  after <- tp$t >= PY + 1
  i0 <- which(tp$t > PY)[1]
  rel <- which(tp$t >= PY & tp$t < PY + 1)
  cat(sprintf("%-28s gtc %.6f s_mid %.4f  max|total-1| after %.2e  air@first-post-yr %.4f  min share %.3e  total range in yr: %.4f..%.4f\n",
              lab, tg$tag$gtc, tg$tag$s_mid, max(abs(tp$total[after]-1)), tp$air[which(tp$t >= PY+1)[1]],
              min(unlist(tp[after, c("air","land","ocean")])), min(tp$total[rel]), max(tp$total[rel])))
  # carbon identical?
  cc <- setdiff(names(pu$out), c("atm_C14","land_C14","ocean_C14","d14c_NH","d14c_SH"))
  cat("     carbon identical:", identical(tg$out[cc], pu$out[cc]), " air(t) at +1,+5,+20,+100:",
      round(sapply(c(1,5,20,100), function(h) tp$air[which.min(abs(tp$t-(PY+h)))]),4), "\n")
  invisible(tp)
}
foss <- base; foss$fossil_GtC[foss$year==PY] <- foss$fossil_GtC[foss$year==PY] + 100
luc  <- base; luc$luc_GtC[luc$year==PY]   <- luc$luc_GtC[luc$year==PY] + 100
neg  <- base; neg$fossil_GtC[neg$year==PY] <- neg$fossil_GtC[neg$year==PY] - 5
chk("fossil +100, constant", foss)
chk("LUC +100, constant", luc)
chk("fossil -5 (removal), constant", neg)
tps <- chk("fossil +100, SPLINE", foss, "spline")
# pre-release tag under spline
cat("spline: max|total| before release year:", max(abs(tps$total[tps$t < PY])), "\n")
