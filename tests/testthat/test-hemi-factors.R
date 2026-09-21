# =====================================================================
# THE SCOPING FACTORS (2026-09-21 c, notes/scoping_2026-09-21c_gate_d_larger_structures.md):
# STRUCTURAL, hemisphere- or box-specific multipliers on existing exchanges, each
# 1 = bit-exact. u_hs_fac_SH (HS <-> HD, SH), tau_q_fac_SH (HD <-> interior, SH),
# pump_hs_fac_SH (the SH cold box's export), k_w_fac_SH (the SH's gas exchange),
# k_w_fac_hs (the cold boxes' gas exchange, both hemispheres). Contracts: absent
# vs 1 bit-exact on spinup / deriv / run_fast + the canonical's streams; guards by
# name; R / C++ parity with every factor off 1; each factor MOVES the state.
# =====================================================================
HF_NAMES <- c("u_hs_fac_SH", "tau_q_fac_SH", "pump_hs_fac_SH", "k_w_fac_SH", "k_w_fac_hs")
hf_par <- function() { p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1); p$pump_hs_gcm2 <- 50; p }   # the HS pump ON, so its SH factor is live

test_that("the factors ship at 1, absent = 1 is BIT-EXACT, the canonical's streams reproduce", {
  p <- hf_par(); for (n in HF_NAMES) expect_identical(p[[n]], 1)
  q <- p; for (n in HF_NAMES) q[[n]] <- NULL
  a <- ccx_spinup(p); b <- ccx_spinup(q)
  expect_identical(a$y, b$y)
  F0 <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0), gmst = 0.3, enso = 0.2, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = a$prod_c14)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  skip_if_no_cpp()
  F <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1902), prod_c14 = a$prod_c14))
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F)
  expect_identical(ra$state, rb$state); expect_identical(ra$out, rb$out)
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "hf"))
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(ccx_par_to_unc(pm))
  ccx_unpin_params(rm); rm <- list()
  expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
})

test_that("guards by name; every factor moves the state; R / C++ parity with all five off 1", {
  p <- hf_par()
  for (n in HF_NAMES) { q <- p; q[[n]] <- -1; expect_error(ccx_prepare(q), n); q[[n]] <- NA_real_; expect_error(ccx_prepare(q), n) }
  for (n in c("u_hs_fac_SH", "tau_q_fac_SH", "k_w_fac_SH", "k_w_fac_hs")) { q <- p; q[[n]] <- 0; expect_error(ccx_prepare(q), n) }
  a <- ccx_spinup(p)
  for (n in HF_NAMES) { q <- p; q[[n]] <- if (n == "pump_hs_fac_SH") 0.25 else 3
    expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - a$y[, "C"])), 1e-4, label = n) }
  # the SH-only factors leave the NH cold box's PI state untouched only through the atmosphere (a second-order coupling):
  # the NH HS moves by far less than the SH HS under u_hs_fac_SH
  q <- p; q$u_hs_fac_SH <- 4; sq <- ccx_spinup(q); ix <- a$aux$idx
  expect_gt(abs(sq$y[ix$SH$hs, "C13"] / sq$y[ix$SH$hs, "C"] - a$y[ix$SH$hs, "C13"] / a$y[ix$SH$hs, "C"]),
            5 * abs(sq$y[ix$NH$hs, "C13"] / sq$y[ix$NH$hs, "C"] - a$y[ix$NH$hs, "C13"] / a$y[ix$NH$hs, "C"]))
  skip_if_no_cpp()
  q <- p; q$u_hs_fac_SH <- 3; q$tau_q_fac_SH <- 2; q$pump_hs_fac_SH <- 0.4; q$k_w_fac_SH <- 1.3; q$k_w_fac_hs <- 2.5
  sp <- ccx_spinup(q)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1903), prod_c14 = sp$prod_c14))
  for (i in c(1L, 7L)) { fr <- ccx_forcing_at(F, i)
    dR <- suppressWarnings(ccx_deriv(sp$y, F$t[i], q, fr, sp$grid, sp$aux)); dC <- ccx_deriv_fast(sp$y, F$t[i], q, fr, sp$grid, sp$aux)
    expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10) }
  r <- ccx_run_fast(sp, F); rR <- suppressWarnings(ccx_run(sp, F))
  expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
})
