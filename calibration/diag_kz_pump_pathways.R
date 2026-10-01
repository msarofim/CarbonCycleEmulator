# =====================================================================
# diag_kz_pump_pathways.R -- PK-1 of notes/prereg_2026-09-15b_kz_pump_diagnosis.md:
# THE BOMB-14C PATHWAY BUDGET at the canonical (hilda30c), UNREFITTED.
# Paired R-path runs (bomb ON vs OFF) with the 14C edge recorder
# (ccx_deriv(record = TRUE)$edges14 / pump_edges14 / diff_edges14, 09-15b)
# kept at every month's opening state. Excess = ON - OFF. The question the
# 09-14 (g) review answered by READING -- "diffusion carries the bomb 14C" --
# is here MEASURED: cumulative excess 14C entering the interior (oc[1..nl] +
# HD, both hemispheres) by (i) LS ML-base diffusion, (ii) LS entrainment,
# (iii) the LS pump, (iv) the HS route (flush + HS pump); the surface-invasion
# split (atm -> ML vs atm -> HS); where the excess sits; and the per-layer
# budget (diffusion from above / to below, pump, conduit) for layers 1..nl.
# GATE PK-1g: the interior closes (sum of entries - decay = d inventory) to
# within 2x the SAME integration's closure error on the recorded CARBON edges
# -- a MEASURED tolerance, not a typed one; MUTATION-TESTED by dropping the
# pump from the sum. Nothing adopted; nothing refitted.
# Usage: Rscript calibration/diag_kz_pump_pathways.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
PK_COMMIT <- ccx_git_stamp()
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
PK_ARM    <- CCX_MODE_CANONICAL
PK_YEARS  <- DG_YEARS                          # 1750-2025, the gate run's span
PK_T0     <- 1950                              # the budget's opening year (pre-bomb)
PK_MARKS  <- c(1965, 1975, 1995, 2010)         # the prereg's read years
PK_TOL_FR <- 0.1                               # gate: the 14C closure residual <= PK_TOL_FR x the SMALLEST pathway's own contribution
                                               # (amendment A2: the carbon budget is NOT a like-for-like reference -- its net is a ~2 %
                                               # residual of ~45 GtC/yr gross terms and the rectangle rule misses ~50 % of it; reported)
PK_OUT    <- ccx_path("outputs", "diagnostics", sprintf("kz_pump_pathways_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(PK_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== PK-1 the bomb-14C pathway budget at %s (prereg 2026-09-15b) ==\n", PK_ARM))
cat(sprintf("run %d-%d on the R path (ccx_run, edge_fn); budget from %d; marks %s; gate: residual <= %g x the smallest pathway\n\n",
            PK_YEARS[1], PK_YEARS[2], PK_T0, paste(PK_MARKS, collapse = "/"), PK_TOL_FR))

v  <- dg_vector(PK_ARM); cat("vector:", v$src, "\n")
sp <- dg_spinup(v)
F_on <- withCallingHandlers(
  ccx_build_forcing("historical", PK_YEARS, prod_c14 = sp$prod_c14,
                    bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale),
  warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
F_off <- F_on; F_off$c14_bomb <- 0; F_off$c14_nuclear <- 0     # the diag_bomb_partition.R idiom
stopifnot(sum(F_on$c14_bomb) > 0, sum(F_off$c14_bomb) == 0)

keep <- function(fl, y, t) list(e = fl$edges14, d = fl$diff_edges14, pu = fl$pump_edges14,
                                ec = fl$edges, y14 = y[, "C14"], yC = y[, "C"])
t0 <- proc.time()[["elapsed"]]
r_on  <- ccx_run(sp, F_on,  edge_fn = keep)
r_off <- ccx_run(sp, F_off, edge_fn = keep)
cat(sprintf("two R-path runs: %.0f s; substeps auto\n", proc.time()[["elapsed"]] - t0))
# the C++ core and the R path must agree on the trajectory this diagnostic reads
o_fast <- ccx_run_fast(sp, F_on)$out
cat(sprintf("R vs C++ on d14c_NH at 1965: %.4f vs %.4f (diff %.2e)\n",
            r_on$out$d14c_NH[which(floor(r_on$out$t) == 1965)[1]],
            o_fast$d14c_NH[which(floor(o_fast$t) == 1965)[1]],
            r_on$out$d14c_NH[which(floor(r_on$out$t) == 1965)[1]] - o_fast$d14c_NH[which(floor(o_fast$t) == 1965)[1]]))

# ---- geometry -------------------------------------------------------
aux <- sp$aux; grid <- sp$grid; nl <- grid$nl; tt <- F_on$t; n <- length(tt)
ix <- lapply(HEMIS, function(h) aux$idx[[h]]); names(ix) <- HEMIS
nb <- nrow(sp$y)
interior <- unlist(lapply(HEMIS, function(h) c(ix[[h]]$oc, ix[[h]]$hd)))
stopifnot(!any(is.na(interior)), length(interior) == 2 * (nl + 1))
E1 <- function(i) i + 1L                       # edge-matrix offset (row/col 1 = external)
kmol <- function(x) ccx_c14_kmol(x)            # 14C-signal state -> kmol 14C
mon_idx <- function(Y) which(floor(tt + 1e-9) == Y)                  # months of year Y
at_end  <- function(Y) mon_idx(Y + 1)[1]                             # opening state of Jan Y+1 = end of Y
i0 <- at_end(PK_T0 - 1)                                             # opening of Jan PK_T0

# excess (ON - OFF) per month, as lists of matrices / vectors
ex <- lapply(seq_len(n), function(i) list(
  e  = r_on$edge_trace[[i]]$e  - r_off$edge_trace[[i]]$e,
  d  = r_on$edge_trace[[i]]$d  - r_off$edge_trace[[i]]$d,
  pu = r_on$edge_trace[[i]]$pu - r_off$edge_trace[[i]]$pu,
  y14 = r_on$edge_trace[[i]]$y14 - r_off$edge_trace[[i]]$y14))
netE <- function(M, a, b) M[E1(a), E1(b)] - M[E1(b), E1(a)]          # net a -> b on one matrix

# ---- the pathway fluxes per month (excess, state units / yr) --------
path_month <- function(x) {
  out <- c(diff_ml = 0, entrain = 0, pump_ls = 0, hs_route = 0, conduit = 0,
           inv_ml = 0, inv_hs = 0, entry_all = 0)
  for (h in HEMIS) {
    ml <- ix[[h]]$ml; oc <- ix[[h]]$oc; hs <- ix[[h]]$hs; hd <- ix[[h]]$hd; atm <- ix[[h]]$atm
    dml <- netE(x$d, ml, oc[1]); pml1 <- x$pu[E1(ml), E1(oc[1])]
    out["diff_ml"]  <- out["diff_ml"]  + dml
    out["pump_ls"]  <- out["pump_ls"]  + sum(x$pu[E1(ml), E1(oc)])
    out["entrain"]  <- out["entrain"]  + (netE(x$e, ml, oc[1]) - dml - pml1)
    out["hs_route"] <- out["hs_route"] + netE(x$e, hs, hd)
    out["conduit"]  <- out["conduit"]  + sum(vapply(oc, function(k) netE(x$e, hd, k), numeric(1)))
    out["inv_ml"]   <- out["inv_ml"]   + netE(x$e, atm, ml)
    out["inv_hs"]   <- out["inv_hs"]   + netE(x$e, atm, hs)
  }
  # every edge from a NON-interior box into an interior one, net -- the identity the four pathways must sum to
  outside <- setdiff(seq_len(nb), interior)
  out["entry_all"] <- sum(x$e[E1(outside), E1(interior)]) - sum(x$e[E1(interior), E1(outside)])
  out
}
PM <- t(vapply(ex, path_month, numeric(8)))                          # n x 8, per year
inv_int <- vapply(ex, function(x) sum(x$y14[interior]), numeric(1))  # interior excess inventory (state units)
lam <- ccx_const("LAMBDA_C14")
cum <- function(col, i1) sum(PM[i0:(i1 - 1L), col]) / 12             # opening-state Euler, dt = 1/12
cum_decay <- function(i1) sum(lam * inv_int[i0:(i1 - 1L)]) / 12

# ---- GATE PK-1g: closure, tolerance SCALED to the smallest pathway it resolves --
cat("\n-- GATE PK-1g: interior closure of the 14C excess (the carbon budget's closure reported alongside, as a diagnostic) --\n")
outside <- setdiff(seq_len(nb), interior)
entryC <- vapply(seq_len(n), function(i) { M <- r_on$edge_trace[[i]]$ec
  sum(M[E1(outside), E1(interior)]) - sum(M[E1(interior), E1(outside)]) }, numeric(1))
invC <- vapply(seq_len(n), function(i) sum(r_on$edge_trace[[i]]$yC[interior]), numeric(1))
gate_rows <- list(); gate_ok <- TRUE
for (Y in PK_MARKS) {
  i1 <- at_end(Y)
  dI14 <- inv_int[i1] - inv_int[i0]; s14 <- cum("entry_all", i1) - cum_decay(i1)
  dIC  <- invC[i1] - invC[i0];      sC  <- sum(entryC[i0:(i1 - 1L)]) / 12
  relC <- abs(sC - dIC) / abs(dIC); resid <- abs(s14 - dI14)
  c4 <- vapply(c("diff_ml", "entrain", "pump_ls", "hs_route"), function(k) abs(cum(k, i1)), numeric(1))
  bound <- PK_TOL_FR * min(c4)
  ok <- resid <= bound
  # mutation: the pump dropped from the sum -- must exceed the bound
  resid_mut <- abs((s14 - cum("pump_ls", i1)) - dI14); mut_fails <- resid_mut > bound
  cat(sprintf("  %d: 14C excess dI %+.2f kmol, integral %+.2f, residual %.3f vs bound %.3f (= %g x smallest pathway %s %.2f) -> %s | mutation (no pump) residual %.2f -> %s | carbon: dI %+.2f GtC, integral %+.2f (rel %.2f, diagnostic)\n",
              Y, kmol(dI14), kmol(s14), kmol(resid), kmol(bound), PK_TOL_FR, names(c4)[which.min(c4)], kmol(min(c4)),
              if (ok) "PASS" else "FAIL", kmol(resid_mut), if (mut_fails) "FAILS as it must" else "DOES NOT FAIL -- no power",
              dIC, sC, relC))
  gate_rows[[as.character(Y)]] <- c(dI14 = kmol(dI14), s14 = kmol(s14), resid = kmol(resid), bound = kmol(bound),
                                    resid_mut = kmol(resid_mut), ok = ok, mut_fails = mut_fails, dIC = dIC, sC = sC, relC = relC)
  gate_ok <- gate_ok && ok && mut_fails
}
cat(sprintf("GATE PK-1g: %s\n", if (gate_ok) "PASS (closes within a tenth of the smallest pathway; the mutation fails)" else "FAIL"))
# one year of the monthly carbon entry, so the rectangle-rule miss is visible rather than asserted
yy <- mon_idx(1955)
cat(sprintf("carbon entry into the interior, monthly 1955 (GtC/yr): %s; mean %.2f vs dI over 1955 %.2f\n",
            paste(sprintf("%+.1f", entryC[yy]), collapse = " "), mean(entryC[yy]), invC[at_end(1955)] - invC[yy[1]]))
# the four-pathway identity: their sum IS entry_all (no other edge enters the interior under hilda)
iden <- max(abs(rowSums(PM[, c("diff_ml", "entrain", "pump_ls", "hs_route")]) - PM[, "entry_all"]))
cat(sprintf("identity check: |diff+entrain+pump+hs - entry_all| max %.2e (state units/yr) -> %s\n",
            iden, if (iden < 1e-12 * max(abs(PM[, "entry_all"]))) "the four pathways are the whole entry" else "ANOTHER EDGE ENTERS THE INTERIOR -- find it"))

# ---- P1: cumulative entry by pathway ---------------------------------
cat("\n-- P1: cumulative bomb-excess 14C ENTRY into the interior by pathway (kmol; share of the total entry) --\n")
cat(sprintf("%6s %10s %10s %10s %10s %10s | %8s %8s %8s %8s | %10s %10s %7s\n", "year", "diff_ml", "entrain", "pump_ls", "hs_route", "total",
            "diff%", "entr%", "pump%", "hs%", "inv_atm>ml", "inv_atm>hs", "hs_inv%"))
P1 <- list()
for (Y in PK_MARKS) {
  i1 <- at_end(Y); c4 <- vapply(c("diff_ml", "entrain", "pump_ls", "hs_route"), function(k) cum(k, i1), numeric(1))
  tot <- sum(c4); inv <- c(cum("inv_ml", i1), cum("inv_hs", i1))
  cat(do.call(sprintf, c(list("%6d %10.1f %10.1f %10.1f %10.1f %10.1f | %7.1f%% %7.1f%% %7.1f%% %7.1f%% | %10.1f %10.1f %6.1f%%\n", Y),
              as.list(c(kmol(c4), kmol(tot), 100 * c4 / tot, kmol(inv), 100 * inv[2] / sum(inv))))))
  P1[[as.character(Y)]] <- c(kmol = kmol(c4), share = c4 / tot, inv_ml = kmol(inv[1]), inv_hs = kmol(inv[2]))
}
s75 <- P1[["1975"]]
cat(sprintf("\nP1 at 1975: diffusion+entrainment %.1f%% (predicted >= 60), pump %.1f%% (predicted 5-20), HS route %.1f%% (predicted 15-35) -> %s\n",
            100 * (s75["share.diff_ml"] + s75["share.entrain"]), 100 * s75["share.pump_ls"], 100 * s75["share.hs_route"],
            paste(c(if (s75["share.diff_ml"] + s75["share.entrain"] >= 0.6) "diff PASS" else "diff FAIL",
                    if (s75["share.pump_ls"] >= 0.05 && s75["share.pump_ls"] <= 0.20) "pump PASS" else "pump FAIL",
                    if (s75["share.hs_route"] >= 0.15 && s75["share.hs_route"] <= 0.35) "hs PASS" else "hs FAIL"), collapse = ", ")))
cat(sprintf("the conduit (HD -> LS layers, internal to the interior), cumulative: %s\n",
            paste(sprintf("%d %.1f kmol", PK_MARKS, vapply(PK_MARKS, function(Y) kmol(cum("conduit", at_end(Y))), numeric(1))), collapse = "; ")))

# ---- P1b: where it sits, and the per-layer budget --------------------
cat("\n-- P1b: where the ocean's bomb-excess 14C SITS (kmol; share of the ocean excess) --\n")
cls_inv <- function(i1) {
  x <- ex[[i1]]$y14
  g <- c(ML = 0, HS = 0, HD = 0, stats::setNames(rep(0, nl), paste0("L", seq_len(nl))))
  for (h in HEMIS) { g["ML"] <- g["ML"] + x[ix[[h]]$ml]; g["HS"] <- g["HS"] + x[ix[[h]]$hs]; g["HD"] <- g["HD"] + x[ix[[h]]$hd]
    for (k in seq_len(nl)) g[paste0("L", k)] <- g[paste0("L", k)] + x[ix[[h]]$oc[k]] }
  g
}
zb <- cumsum(grid$dz)
cat(sprintf("layer bases (m): %s; HS %.0f m thick\n", paste(round(zb), collapse = " "), aux$h_hs))
P1b <- list()
for (Y in PK_MARKS) {
  g <- cls_inv(at_end(Y)); tot <- sum(g)
  top <- (g["ML"] + sum(g[paste0("L", 1:4)]) + g["HS"] + g["HD"]) / tot
  cat(sprintf("%d: total %.1f kmol | %s | ML+L1-4+HS+HD %.1f%%\n", Y, kmol(tot),
              paste(sprintf("%s %.1f%%", names(g), 100 * g / tot), collapse = " "), 100 * top))
  P1b[[as.character(Y)]] <- c(kmol(g), top = unname(top))
}
cat("\n-- per-LAYER cumulative excess budget (kmol): diffusion from above (+), diffusion to below (-), pump (+), conduit HD->k (+), entrainment (L1) --\n")
layer_budget <- function(i1) {
  M <- matrix(0, nl, 6, dimnames = list(paste0("L", seq_len(nl)), c("diff_above", "diff_below", "pump", "conduit", "entrain", "inventory")))
  for (i in i0:(i1 - 1L)) { x <- ex[[i]]
    for (h in HEMIS) { ml <- ix[[h]]$ml; oc <- ix[[h]]$oc; hd <- ix[[h]]$hd
      for (k in seq_len(nl)) {
        above <- if (k == 1L) ml else oc[k - 1L]
        M[k, "diff_above"] <- M[k, "diff_above"] + netE(x$d, above, oc[k]) / 12
        if (k < nl) M[k, "diff_below"] <- M[k, "diff_below"] - netE(x$d, oc[k], oc[k + 1L]) / 12
        M[k, "pump"]    <- M[k, "pump"]    + x$pu[E1(ml), E1(oc[k])] / 12
        M[k, "conduit"] <- M[k, "conduit"] + netE(x$e, hd, oc[k]) / 12
        if (k == 1L) M[k, "entrain"] <- M[k, "entrain"] + (netE(x$e, ml, oc[1]) - netE(x$d, ml, oc[1]) - x$pu[E1(ml), E1(oc[1])]) / 12
      } } }
  for (h in HEMIS) for (k in seq_len(nl)) M[k, "inventory"] <- M[k, "inventory"] + ex[[i1]]$y14[ix[[h]]$oc[k]] - ex[[i0]]$y14[ix[[h]]$oc[k]]
  kmol(M)
}
LB <- list()
for (Y in c(1975, 1995)) {
  M <- layer_budget(at_end(Y)); LB[[as.character(Y)]] <- M
  cat(sprintf("\n%d (cumulative from %d):\n", Y, PK_T0)); print(round(M, 2))
  gross_in <- M[1:4, "diff_above"] + M[1:4, "pump"] + M[1:4, "conduit"] + M[1:4, "entrain"]
  gross_in[gross_in < 0] <- NA
  sh_diff <- sum(M[1:4, "diff_above"] + M[1:4, "entrain"], na.rm = TRUE) / sum(gross_in, na.rm = TRUE)
  sh_cond <- sum(M[1:4, "conduit"]) / sum(gross_in, na.rm = TRUE)
  cat(sprintf("layers 1-4 gross inflow: diffusion-from-above+entrainment %.1f%%, pump %.1f%%, conduit %.1f%%\n",
              100 * sh_diff, 100 * sum(M[1:4, "pump"]) / sum(gross_in, na.rm = TRUE), 100 * sh_cond))
  if (Y == 1995) cat(sprintf("P1b at 1995: top-of-column share %.1f%% (predicted >= 80) %s; layers 1-4 by diffusion %.1f%% (predicted >= 70) %s; conduit %.1f%% (predicted <= 30) %s\n",
                              100 * P1b[["1995"]]["top"], if (P1b[["1995"]]["top"] >= 0.8) "PASS" else "FAIL",
                              100 * sh_diff, if (sh_diff >= 0.7) "PASS" else "FAIL", 100 * sh_cond, if (sh_cond <= 0.3) "PASS" else "FAIL"))
}

# ---- the bomb rows' own quantities, for the record ---------------------
cat("\n-- the record: atmospheric peaks and the whole-ocean excess --\n")
for (h in c("NH", "SH")) { col <- paste0("d14c_", h); i <- which.max(r_on$out[[col]])
  cat(sprintf("  %s peak %+.1f permil at %.2f\n", h, r_on$out[[col]][i], r_on$out$t[i])) }
oc_ex <- r_on$out$ocean_C14 - r_off$out$ocean_C14
for (Y in PK_MARKS) cat(sprintf("  ocean excess 14C at end-%d: %.1f kmol\n", Y, kmol(oc_ex[at_end(Y)])))

saveRDS(list(arm = PK_ARM, years = PK_YEARS, t0 = PK_T0, marks = PK_MARKS, gate = gate_rows, gate_ok = gate_ok,
             P1 = P1, P1b = P1b, layer_budget = LB, path_month = PM, t = tt, inv_int = inv_int, entryC = entryC, invC = invC,
             src = v$src, commit = PK_COMMIT),
        paste0(PK_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", PK_OUT))
