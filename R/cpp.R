# =====================================================================
# cpp.R — compile and drive the C++ core (src/ccx_core.cpp).
#
# The C++ core is a PORT of R/model.R, not a replacement for it. R stays the
# reference implementation; test-parity.R gates the two against each other on
# both a single derivative and a multi-decade integration. If they disagree,
# the C++ is wrong until proven otherwise.
# =====================================================================

# NB: parent must NOT be emptyenv() -- sourceCpp() evaluates assignments in this
# environment and needs `<-` resolvable from it.
.ccx_cpp_env <- new.env(parent = globalenv())

#' Compile the C++ core (once per session) and expose its functions
ccx_load_cpp <- function(quiet = TRUE) {
  if (isTRUE(.ccx_cpp_env$loaded)) return(invisible(TRUE))
  if (!requireNamespace("Rcpp", quietly = TRUE)) stop("Rcpp is required for the C++ core.")
  Rcpp::sourceCpp(ccx_path("src", "ccx_core.cpp"), env = .ccx_cpp_env,
                  verbose = FALSE, rebuild = FALSE, showOutput = !quiet)
  .ccx_cpp_env$loaded <- TRUE
  invisible(TRUE)
}

#' Flatten the R-side aux/grid/constants into the plain list the C++ unpacks
#'
#' Everything the core needs is resolved HERE, once, rather than looked up per
#' flux per RK stage as the R reference does -- that string-keyed lookup is a
#' large part of why the R version is slow, and it must not be reproduced in
#' the hot loop.
ccx_cpp_aux <- function(aux, grid, carb_iter = 6L) {
  cc <- ccx_aux_carb(aux)                  # the run's carbonate table (2026-10-12)
  list(
    gtc_per_ppm_hemi = aux$gtc_per_ppm_hemi,
    chi0 = aux$chi0, mol_per_GtC = aux$mol_per_GtC,
    npp0 = c(aux$npp0$NH, aux$npp0$SH),
    veg0 = c(aux$veg0$NH, aux$veg0$SH),
    land0 = c(aux$land0$NH, aux$land0$SH),
    ml_mass_kg = c(aux$ml_mass_kg$NH, aux$ml_mass_kg$SH),
    asx = c(aux$asx$NH, aux$asx$SH),
    sst = c(aux$sst$NH, aux$sst$SH),
    dz = grid$dz, dz_mid = aux$dz_mid,
    # Per-interface diffusivity (2026-09-06b). Sent UNCONDITIONALLY like every
    # vector field below, and LOUD if absent: an aux built without it would
    # otherwise hand the core whatever was in that buffer before.
    kz_int = if (is.null(aux$kz_int))
      stop("aux lacks kz_int -- build it with ccx_prepare() (2026-09-06b)") else aux$kz_int,
    # SEASONAL MIXED LAYER (round 6). Sent zero-filled when off -- the pump_org
    # precedent -- so a stale draw cannot leave a live field behind, and the two
    # cores agree bit for bit at seas_ml = 0.
    seas_ml = as.integer(!is.null(aux$mld_coef)),
    mld_a = if (is.null(aux$mld_coef)) numeric(12) else
              unlist(lapply(HEMIS, function(h) aux$mld_coef[[h]]$a), use.names = FALSE),
    mld_b = if (is.null(aux$mld_coef)) numeric(12) else
              unlist(lapply(HEMIS, function(h) aux$mld_coef[[h]]$b), use.names = FALSE),
    a_oc = c(aux$a_oc$NH, aux$a_oc$SH),
    dic0 = c(aux$dic0$NH, aux$dic0$SH),
    revelle0 = c(aux$revelle0$NH, aux$revelle0$SH),
    pco2_0 = c(aux$pco2_0$NH, aux$pco2_0$SH),
    alpha_photo = aux$alpha_photo,
    alpha_as_down = aux$alpha_as_down, alpha_as_up = aux$alpha_as_up,
    # the T-dependent pair (2026-09-02). Sent UNCONDITIONALLY, like the pump
    # arrays: the C++ reads every field into a fixed struct, so a field the R
    # side sometimes omits is whatever was in that memory before.
    alpha_as_tdep = as.integer(aux$alpha_as_tdep),
    alpha_as_zA = aux$alpha_as_zA, alpha_as_zB = aux$alpha_as_zB,
    alpha_as_zC = aux$alpha_as_zC, alpha_as_fco3 = aux$alpha_as_fco3,
    alpha_as_kin_a = aux$alpha_as_kin_a, alpha_as_kin_b = aux$alpha_as_kin_b,
    bomb_share_NH = aux$bomb_share_NH, nuc_share_NH = aux$nuc_share_NH,
    R13 = ccx_const("R13_VPDB"), R14STD = ccx_const("R14_STD"),
    lambda = ccx_const("LAMBDA_C14"), alk = ccx_aux_alk(aux),    # the run's LS alkalinity (2026-10-12)
    # the cold box's own alkalinity (2026-09-08g); absent = the LS value
    alk_hs = if (is.null(aux$alk_hs)) ccx_aux_alk(aux) else aux$alk_hs,
    cK0 = cc$coefs$K0, cK1 = cc$coefs$K1, cK2 = cc$coefs$K2,
    cKb = cc$coefs$Kb, cKw = cc$coefs$Kw,
    t_centre = cc$t_centre, t_scale = cc$t_scale, boron = cc$boron_total,
    carb_iter = as.integer(carb_iter),
    # THE PUMP (task 9). Sent FLAT, 2 x NL hemisphere-major, and ZERO-FILLED when
    # the pump is off -- the C++ reads the array unconditionally into a fixed
    # buffer, so leaving it unset would hand the core whatever was there before.
    # `pump_on` is what actually gates the flux, on both sides.
    pump_on = as.integer(!is.null(aux$pump)),
    pump_org = if (is.null(aux$pump)) numeric(2 * grid$nl) else
      c(aux$pump$NH$org, aux$pump$SH$org),
    pump_carb = if (is.null(aux$pump)) numeric(2 * grid$nl) else
      c(aux$pump$NH$carb, aux$pump$SH$carb),
    ml_C0 = c(aux$ml_C0$NH, aux$ml_C0$SH),
    # THE STRATIFICATION FEEDBACK (DESIGN §3.4a S, 2026-10-04): the upper part of K and the export
    # solved against it. Sent UNCONDITIONALLY and ZERO-FILLED when off (the pump_org precedent);
    # `mix_on` is what gates both substitutions, on both sides.
    mix_on = as.integer(isTRUE(aux$mix_on == 1L)),
    kz_up = if (is.null(aux$kz_up)) numeric(grid$nl) else aux$kz_up,
    pump_up_org = if (is.null(aux$pump_up)) numeric(2 * grid$nl) else
      c(aux$pump_up$NH$org, aux$pump_up$SH$org),
    pump_up_carb = if (is.null(aux$pump_up)) numeric(2 * grid$nl) else
      c(aux$pump_up$NH$carb, aux$pump_up$SH$carb),
    alpha_pump_org  = 1 + ccx_aux_pump_eps13_org(aux) / 1000,   # the run's value (2026-10-12)
    alpha_pump_carb = 1 + ccx_const("PUMP_EPS13_CARB") / 1000,
    # THE HIGH-LATITUDE BOXES (HILDA HS/HD, 2026-09-05). Sent UNCONDITIONALLY,
    # for the reason the pump arrays and the T-dependent alphas are: the core
    # reads every field into a fixed struct, so a field the R side sometimes
    # omits is whatever was in that memory before. `hs_on` is read FIRST on the
    # C++ side because it also sets the box stride.
    hs_on = as.integer(aux$hs_on), hs_frac = aux$hs_frac,
    a_ls = c(aux$a_ls$NH, aux$a_ls$SH),
    a_hs = c(aux$a_hs$NH, aux$a_hs$SH),
    hs_mass_kg = c(aux$hs_mass_kg$NH, aux$hs_mass_kg$SH),
    asx_hs = c(aux$asx_hs$NH, aux$asx_hs$SH),
    h_hs = aux$h_hs, dz_hd = aux$dz_hd, sst_hs = aux$sst_hs,
    # PER-HEMISPHERE HS / HD thickness (2026-09-21 e; plumbing kept after the
    # 09-21 prune): the core reads these; = the scalars above. LOUD if the aux
    # predates it.
    thick_hs = if (is.null(aux$thick_hs))
      stop("aux lacks thick_hs -- build it with ccx_prepare() (2026-09-21 e)") else c(aux$thick_hs$NH, aux$thick_hs$SH),
    thick_hd = c(aux$thick_hd$NH, aux$thick_hd$SH),
    dic0_hs = aux$dic0_hs, revelle0_hs = aux$revelle0_hs,
    # THE HS PUMP (2026-09-07d): two scalars per hemisphere, ZERO-FILLED when
    # off; `pump_hs_on` gates the flux on both sides, like `pump_on`.
    pump_hs_on = as.integer(!is.null(aux$pump_hs)),
    pump_hs_org  = if (is.null(aux$pump_hs)) numeric(2) else c(aux$pump_hs$NH$org,  aux$pump_hs$SH$org),
    pump_hs_carb = if (is.null(aux$pump_hs)) numeric(2) else c(aux$pump_hs$NH$carb, aux$pump_hs$SH$carb),
    hs_C0 = if (is.null(aux$hs_C0)) numeric(2) else c(aux$hs_C0$NH, aux$hs_C0$SH),
    # O5b (2026-09-16 b): the HS pump's seasonal shape, 6 Fourier harmonics per
    # hemisphere (the mld_a/mld_b precedent), ZERO-FILLED when the HS pump is
    # off. `pump_hs_seas_on` says the coefficients are DATA-PRESENT; the switch
    # that emits anything is P.pump_hs_seas_amp > 0, on p, in both cores.
    pump_hs_seas_on = as.integer(!is.null(aux$hs_export_seas_coef)),
    phs_a = if (is.null(aux$hs_export_seas_coef)) numeric(12) else
              unlist(lapply(HEMIS, function(h) aux$hs_export_seas_coef[[h]]$a), use.names = FALSE),
    phs_b = if (is.null(aux$hs_export_seas_coef)) numeric(12) else
              unlist(lapply(HEMIS, function(h) aux$hs_export_seas_coef[[h]]$b), use.names = FALSE),
    # THE EQUATORIAL CELL (2026-09-13g). Sent UNCONDITIONALLY, zero-filled when
    # off, for the same reason as every structural field above; `eq_on` is
    # read SECOND on the C++ side (after hs_on) because it also sets the box
    # stride. `a_ml` is the mixed layer's OWN area (choice D1) -- equal to a_ls
    # with the cell off. An aux built before the cell existed carries none of
    # these; ccx_prepare() is the one builder, so LOUD rather than defaulted.
    eq_on = if (is.null(aux$eq_on))
      stop("aux lacks eq_on -- build it with ccx_prepare() (2026-09-13g)") else as.integer(aux$eq_on),
    a_ml = c(aux$a_ml$NH, aux$a_ml$SH),
    a_eq = c(aux$a_eq$NH, aux$a_eq$SH),
    eq_mass_kg = c(aux$eq_mass_kg$NH, aux$eq_mass_kg$SH),
    asx_eq = c(aux$asx_eq$NH, aux$asx_eq$SH),
    eq_w_share = c(aux$eq_w_share$NH, aux$eq_w_share$SH),
    h_eq = aux$h_eq, sst_eq = aux$sst_eq, sst_eq_enso = aux$sst_eq_enso,
    alk_eq = aux$alk_eq, k_eq = as.integer(aux$k_eq),
    dic0_eq = aux$dic0_eq, revelle0_eq = aux$revelle0_eq,
    # THE VENTILATION LOOP (option E, 2026-09-14 h). Same contract: unconditional,
    # zero-filled when off, LOUD if the aux predates it.
    e_on = if (is.null(aux$e_on))
      stop("aux lacks e_on -- build it with ccx_prepare() (2026-09-14 h)") else as.integer(aux$e_on),
    k_e1 = as.integer(aux$k_e1), k_e2 = as.integer(aux$k_e2),
    e_w = as.numeric(aux$e_w),
    e_share = c(aux$e_share$NH, aux$e_share$SH),
    # THE HS-ROUTE DEEP RETURN (option O1 arm THC, 2026-09-15 d). Same contract.
    thc_on = if (is.null(aux$thc_on))
      stop("aux lacks thc_on -- build it with ccx_prepare() (2026-09-15 d)") else as.integer(aux$thc_on),
    k_thc = as.integer(aux$k_thc),
    thc_share = c(aux$thc_share$NH, aux$thc_share$SH),
    # THE LAYER-2 NINO3.4 LIMB (2026-09-17 k). Same contract.
    l2_on = if (is.null(aux$l2_on))
      stop("aux lacks l2_on -- build it with ccx_prepare() (2026-09-17 k)") else as.integer(aux$l2_on),
    k_l2 = as.integer(aux$k_l2), w0_l2 = as.numeric(aux$w0_l2),
    l2_share = c(aux$l2_share$NH, aux$l2_share$SH),
    # THE TROPICAL SURFACE BOX (2026-09-14f). Same contract as the cell's
    # fields: unconditional, zero-filled when off, LOUD if the aux predates it;
    # `tr_on` is read THIRD on the C++ side because it also sets the stride.
    tr_on = if (is.null(aux$tr_on))
      stop("aux lacks tr_on -- build it with ccx_prepare() (2026-09-14f)") else as.integer(aux$tr_on),
    # THE INERT SOIL BOX (2026-09-30), read FOURTH on the C++ side: it sets the
    # stride (one box per hemisphere, appended last) and moves that box from the
    # ocean sum to the land sum in the out matrix. An aux that predates it is
    # the pool-off model, which is what 0 means.
    inert_on = if (is.null(aux$inert_on)) 0L else as.integer(aux$inert_on),
    a_tr = c(aux$a_tr$NH, aux$a_tr$SH),
    tr_mass_kg = c(aux$tr_mass_kg$NH, aux$tr_mass_kg$SH),
    asx_tr = c(aux$asx_tr$NH, aux$asx_tr$SH),
    tr_q_share = c(aux$tr_q_share$NH, aux$tr_q_share$SH),
    h_tr = aux$h_tr, sst_tr = aux$sst_tr, sst_tr_enso = aux$sst_tr_enso,
    alk_tr = aux$alk_tr, dic0_tr = aux$dic0_tr, revelle0_tr = aux$revelle0_tr,
    ml_pump_share = c(aux$ml_pump_share$NH, aux$ml_pump_share$SH),
    tr_C0 = c(aux$tr_C0$NH, aux$tr_C0$SH),
    kz_tr = aux$kz_tr
  )
}

#' Refuse a `p`/`aux` pair that disagrees about the seasonal mixed layer.
#'
#' ⛔ The 2026-09-09t defect had a mirror image: `p` says the mechanism is ON
#' while `aux` was prepared from a list that said OFF, so `mld_a`/`mld_b` ship
#' zero-filled and the core would run f = 0 -- a mixed layer of zero thickness --
#' rather than error. `ccx_prepare()` builds `mld_coef` under the SAME predicate
#' the gate now uses, so the two can only disagree when an `aux` is reused across
#' a parameter change. That is worth a loud stop, not a silent zero.
#'
#' ⛔ `seas_ml` = 2 (OPTION B, the cycle on the HS box) HAS NO C++ TWIN: commit
#' 5ed31cf paused option B before the core was ported, so `ccx_core.cpp` carries
#' no `mld_hs_coef` and would silently run the aseasonal cold box. That is a
#' DIFFERENT condition from the 09-09t leak and used to be reported with the
#' leak's message (an aux prepared for seas_ml = 2 legitimately has no
#' `mld_coef`; it has `mld_hs_coef`). Named for what it is since 2026-09-12.
ccx_seas_ml_marshal_check <- function(p, aux) {
  if (ccx_seas_ml_on(p) && isTRUE(p$seas_ml == 2))
    stop("ccx: seas_ml = 2 (option B, the seasonal cycle on the HS box) has NO C++ ",
         "twin -- src/ccx_core.cpp carries no `mld_hs_coef` (option B was paused at ",
         "commit 5ed31cf). Run the R core (ccx_run / ccx_deriv), or use seas_ml = 0/1.")
  if (ccx_seas_ml_on(p) && is.null(aux$mld_coef))
    stop("ccx: `p` says the seasonal mixed layer is ON (ccx_seas_ml_on) but `aux` ",
         "carries no `mld_coef` -- this aux was prepared from a DIFFERENT parameter ",
         "list. Rebuild it with ccx_prepare(p). (2026-09-09t: one mechanism, one gate.)")
  invisible(TRUE)
}

#' Parameters in the flat form the C++ unpacks
ccx_cpp_par <- function(p) {
  # ⚠ RESOLVED THROUGH ccx_gamma_enso(), NOT with four literals here -- the same
  # rule seas_lag_p follows twenty lines down, and for the same reason: the R
  # core resolves an absent coefficient through that one function, so the two
  # cores cannot drift apart about what absence means. A pre-2026-09-01 list
  # carrying only `gamma_enso` takes its legacy branch (land = scalar x 0.5,
  # ocean = 0) and reaches the core as the model it was fitted under.
  .ge <- ccx_gamma_enso(p)
  p$gamma_enso_land_NH <- unname(.ge[["land_NH"]])
  p$gamma_enso_land_SH <- unname(.ge[["land_SH"]])
  p$gamma_enso_ocn_NH  <- unname(.ge[["ocn_NH"]])
  p$gamma_enso_ocn_SH  <- unname(.ge[["ocn_SH"]])
  # Pump export law, added 2026-08-16. Defaulted here as well as in
  # ccx_default_params() so a parameter list built before the port reaches the
  # core as the nutrient-limited model rather than as garbage.
  p$pump_mode <- if (identical(p$pump_mode, "D")) 1L else 0L
  if (is.null(p$revelle_frozen)) p$revelle_frozen <- 0
  # ⛔⛔ THE SEASONAL MIXED LAYER'S GATE, RESOLVED HERE AND NOWHERE ELSE
  # (2026-09-09t). Until today the C++ gated it on `aux$mld_coef`'s PRESENCE
  # while R gated on ccx_seas_ml_on(p) -- two gates for one mechanism. Because
  # ccx_spinup() builds `aux` from the un-zeroed `p` and only THEN sets
  # seas_drivers = 0, the zeroing was honoured by R and IGNORED by C++: every
  # equilibrium solve runs through the C++ path, so the "aseasonal"
  # preindustrial equilibrium was the one that balances a spurious entrainment
  # limb frozen at the spinup epoch (-1940.2 GtC of ocean carbon at hilda31).
  # SAME RULE AS gamma_enso ABOVE AND seas_lag_p BELOW: the predicate is
  # computed by the function the R core itself calls, so the two cores cannot
  # hold a second opinion about whether the mechanism is on.
  p$seas_ml_on <- as.integer(ccx_seas_ml_on(p))
  # Volcanic diffuse-light fertilisation, added 2026-08-29 and ADOPTED at 0.25
  # the same day. Defaults to the SAME named constant ccx_default_params() uses,
  # so a hand-built parameter list cannot reach the core with a different
  # mechanism strength than the R path would have given it.
  # ⚠ This is no longer the behaviour-preserving fallback it was when the value
  # was 0: a pre-2026-08-29 parameter list now reaches the core with the
  # mechanism ON. That is the adoption, and it is why every vector fitted before
  # the adoption is non-comparable.
  if (is.null(p$gamma_diff)) p$gamma_diff <- CCX_GAMMA_DIFF_DEFAULT
  # N-deposition retention flux (D2 (a), 2026-09-30): the SAME named constant the
  # R deriv falls back to, so absence cannot mean two things.
  if (is.null(p$ndep_ret)) p$ndep_ret <- CCX_NDEP_RET_DEFAULT
  # NPP temperature sensitivity (D2 (b), 2026-09-30): same rule, same constant.
  if (is.null(p$npp_tsens)) p$npp_tsens <- CCX_NPP_TSENS_DEFAULT
  # Land-structure parameters added 2026-08-12. Defaulted here as well as in
  # ccx_default_params() so that a hand-built or older parameter list cannot
  # reach the C++ with a missing name.
  # ⚠ CORRECTED 2026-10-02: a missing name does NOT "unpack as garbage", as this
  # file said in five places -- Rcpp's List lookup THROWS ("Index out of bounds:
  # [index='q10']", measured). The defaults below exist so an OLDER list runs as
  # the model it was written for instead of stopping; the silent-garbage hazard is
  # the forcing's POSITIONAL columns (CCX_FORCING_COLS), not the named parameters.
  # HILDA high-latitude boxes, added 2026-09-05. Defaulted here as well as in
  # ccx_default_params() so a parameter list built before that date cannot reach
  # the core with a missing name (which would THROW -- see the correction above).
  # The behaviour-preserving values are the OFF ones: hs_frac = 0 (in the aux,
  # via ccx_hs_on()) means the boxes are absent, and these two are then inert.
  if (is.null(p$u_hs))  p$u_hs  <- 0
  if (is.null(p$tau_q)) p$tau_q <- 0
  # The equatorial cell's two fitted names (2026-09-13g): absence = 0 = the
  # loop OFF / no modulation, inert while eq_frac = 0 (in the aux, via
  # ccx_eq_on()) says the box is absent. Same contract as u_hs / tau_q.
  if (is.null(p$w_eq))     p$w_eq     <- 0
  if (is.null(p$gamma_eq)) p$gamma_eq <- 0
  # The tropical box's lateral exchange (2026-09-14f): absence = 0 = OFF, and
  # inert while tr_frac = 0 says the box is absent. Same contract.
  if (is.null(p$q_tr))     p$q_tr     <- 0
  # The ventilation loop's two fitted names (option E, 2026-09-14 h): absence
  # = 0 = OFF (aux$e_on, via ccx_prepare(), already says so). Same contract.
  if (is.null(p$w_vent))      p$w_vent      <- 0
  if (is.null(p[["w_thc"]]))  p[["w_thc"]]  <- 0   # the HS-route deep return (2026-09-15 d)
  if (is.null(p[["w_enso_l2"]])) p[["w_enso_l2"]] <- 0   # the layer-2 Nino3.4 limb (2026-09-17 k): absence = 0 = OFF
  if (is.null(p$pump_seas_amp)) p$pump_seas_amp <- 0   # the seasonal export (2026-09-15 f): absence = 0 = OFF
  if (is.null(p$pump_seas_lag)) p$pump_seas_lag <- 0
  if (is.null(p$pump_hs_seas_amp)) p$pump_hs_seas_amp <- 0   # O5b (2026-09-16 b): absence = 0 = OFF
  if (is.null(p$pump_hs_seas_lag)) p$pump_hs_seas_lag <- 0
  if (is.null(p$gamma_vent))  p$gamma_vent  <- 0
  # q_attach_from (2026-09-05f): 1 = every interior layer = HILDA's
  # depth-independent q, so a parameter list written before that date reaches
  # BOTH cores as the 09-05 structure. Same absence contract as h_hs.
  if (is.null(p$q_attach_from)) p$q_attach_from <- 1
  if (is.null(p$npp_veg_frac)) p$npp_veg_frac <- 0
  if (is.null(p$ra_ratio)) p$ra_ratio <- 0
  # Fertilisation form, added 2026-08-14. Defaults to the SAME named constant
  # ccx_default_params() uses -- and that constant is the LOG form, so a
  # parameter list built before today reaches the core as the model it was
  # written for. beta_max / fert_k are inert under FERT_LOG but must still be
  # present and finite: unpack_par reads them unconditionally, and a missing
  # name would throw (see the 2026-10-02 correction above).
  if (is.null(p$fert_form)) p$fert_form <- CCX_FERT_FORM_DEFAULT
  p$fert_form <- as.integer(p$fert_form)
  if (is.null(p$beta_max)) p$beta_max <- 0
  if (is.null(p$fert_k)) p$fert_k <- 1
  # Ocean overturning added 2026-08-13, default OFF. Same reasoning as above: a
  # parameter list built before that date must reach the core as the
  # pure-diffusion model it was written for, not as garbage.
  # Land-use permanence, added 2026-08-13. UNLIKE the switches above this does
  # NOT default to the old behaviour: a parameter list built before the fix is a
  # list built against a bug (land-use carbon with an airborne fraction of 0.002
  # at 100 years), so it defaults to the SAME named constant ccx_default_params()
  # uses. If the two ever disagree, the C++ core silently runs a different model
  # from the R one -- which is exactly what gamma_enso did.
  if (is.null(p$f_luc_perm)) p$f_luc_perm <- CCX_F_LUC_PERM_DEFAULT
  # WHERE the debit comes from. Like f_luc_perm, this does NOT default to the
  # old behaviour: wood-only (= 1) was the incumbent when the switch was added
  # (b3108d7), but ea7c70b ADOPTED pro rata and flipped the constant to 0, so a
  # pre-ea7c70b parameter list must reach the core as the pro-rata model that
  # ships today. Read the default off CCX_F_LUC_WOOD_DEFAULT, never off this
  # comment.
  if (is.null(p$f_luc_wood)) p$f_luc_wood <- CCX_F_LUC_WOOD_DEFAULT
  if (is.null(p$w_up)) p$w_up <- 0
  if (is.null(p$w_out_NH)) p$w_out_NH <- 0
  if (is.null(p$w_out_SH)) p$w_out_SH <- 0
  # The conveyor, added 2026-08-13, same reasoning again. NOTE the structural
  # switches must reach the C++ as INTEGERS -- unpack_par reads them into int.
  # Seasonal drivers, added 2026-08-18. ABSENCE = the SINE, deliberately, and
  # this is the f_luc_perm principle applied the other way round: a parameter
  # list built before this date was fitted UNDER the sine (its seas_amp/phase
  # carry that fit), so it must reach the core as the sine model -- running it
  # under drivers would ignore its own seasonal fit and substitute defaults,
  # silently. New lists get drivers because ccx_default_params() sets
  # seas_drivers = 1 explicitly. The T-amp/lag defaults below are inert at
  # seas_drivers = 0; they exist so unpack_par never reads a missing field.
  if (is.null(p$seas_drivers)) p$seas_drivers <- 0
  if (is.null(p$seas_T_amp_NH)) p$seas_T_amp_NH <- 12
  if (is.null(p$seas_T_amp_SH)) p$seas_T_amp_SH <- 6
  # ⚠ RESOLVED THROUGH ccx_seas_lag_p(), NOT with a second literal here. The
  # R core resolves an absent lag through that same function, so the two cores
  # cannot drift apart about what absence means -- the gamma_diff failure of
  # 2026-08-30. Legacy `seas_lag_p` lists are carried by its own fallback.
  # diagnostic seasonal exchange; absence = 0 = OFF in BOTH cores
  # SEASONAL MIXED LAYER (seas_ml = 1): the C++ twin EXISTS as of 2026-09-09o and
  # test-parity.R covers the mechanism at an explicit seas_ml = 1. Absence still
  # means 0 = OFF = bit-identical. (seas_ml = 2 has no twin and is refused by
  # ccx_seas_ml_marshal_check() above.)
  if (is.null(p$seas_ml)) p$seas_ml <- 0
  if (is.null(p$tau_ex_seas_amp)) p$tau_ex_seas_amp <- 0
  if (is.null(p$tau_ex_seas_phase)) p$tau_ex_seas_phase <- 0
  .lagp <- ccx_seas_lag_p(p)
  p$seas_lag_p_NH <- .lagp[["NH"]]; p$seas_lag_p_SH <- .lagp[["SH"]]
  # the respiration and seasonal-SST lags (2026-10-12): compile-time twins until today, now
  # resolved by the SAME functions the R core calls, so absence means 2.0 / 1.32 in both cores
  p$seas_T_lag <- ccx_seas_t_lag(p)
  .sstl <- ccx_sst_seas_lag(p)
  p$sst_seas_lag_NH <- .sstl[["NH"]]; p$sst_seas_lag_SH <- .sstl[["SH"]]
  if (is.null(p$sst_seas_amp_NH)) p$sst_seas_amp_NH <- 2.0
  if (is.null(p$sst_seas_amp_SH)) p$sst_seas_amp_SH <- 1.2
  # ABSENCE = 0 = the channel OFF = the pre-2026-08-27g model, bit for bit. A
  # parameter list written before the Southern-Ocean entrainment channel
  # existed reaches the core as the model it was built for -- the same
  # principle as seas_drivers and sst_obs below.
  if (is.null(p$ent_seas_amp_SH)) p$ent_seas_amp_SH <- 0
  # ABSENCE = 1 = the shipped model: a parameter list written before 2026-08-20f
  # reaches the core as the model it was built for.
  if (is.null(p$seas_npp_amp_NH)) p$seas_npp_amp_NH <- 1
  if (is.null(p$seas_npp_amp_SH)) p$seas_npp_amp_SH <- 1
  # Observed-SST switch: ABSENCE = the legacy sst_scale * gmst path, so a
  # pre-2026-08-18 parameter list runs the model it was fitted to (the same
  # principle as seas_drivers above). ccx_default_params() sets 1 explicitly.
  if (is.null(p$sst_obs)) p$sst_obs <- 0
  # The HS box's share of the SST anomaly (DESIGN §3.4a T, 2026-10-05): resolved by the SAME function the R core
  # calls, so absence means 1 in both cores and the C++ source never sees an absent value.
  p$hs_sst_anom_frac <- ccx_hs_sst_frac(p)
  if (is.null(p$q_conv)) p$q_conv <- 0
  if (is.null(p$conv_sink)) p$conv_sink <- N_INTERIOR
  if (is.null(p$conv_descent)) p$conv_descent <- 0L
  if (is.null(p$conv_reverse)) p$conv_reverse <- 0L
  p$conv_sink <- as.integer(p$conv_sink)
  p$conv_descent <- as.integer(p$conv_descent)
  p$conv_reverse <- as.integer(p$conv_reverse)
  # The four-pool land REPLACED tau_veg/tau_soil, so an older parameter list
  # reaches here with the wrong names entirely. That is a structural mismatch,
  # not a missing default -- fail loudly rather than silently substituting a
  # land the caller did not ask for.
  need <- c("npp_leaf_frac", "tau_leaf", "tau_wood",
            "litter_slow_frac", "tau_soil_fast", "tau_soil_slow")
  miss <- need[!need %in% names(p)]
  if (length(miss)) {
    extra <- if (any(c("tau_veg", "tau_soil") %in% names(p)))
      " (it carries tau_veg/tau_soil: a PRE-4-POOL parameter list)" else ""
    stop("parameter list is missing the land structure: ",
         paste(miss, collapse = ", "), extra)
  }
  # INERT SOIL CARVE-OUT (2026-09-30), RESOLVED HERE AND NOWHERE ELSE on the C++
  # side, by the SAME function the R core calls: the core receives the
  # EXCHANGING passive share under the name `litter_slow_frac` and never sees
  # `soil_inert_frac`. Same rule as gamma_enso / seas_ml_on above -- one
  # resolution, so the two cores cannot disagree -- and the C++ source is
  # untouched. Its only other use, aux$land0, is marshalled from the R aux.
  # After the land-structure check, so a list missing litter_slow_frac fails
  # there by name. Absent or 0 passes litter_slow_frac through unchanged (bit-exact).
  p$litter_slow_frac <- ccx_litter_slow_eff(p)
  p[c("beta", "fert_form", "beta_max", "fert_k",
      "q10", "k_w", "kz", "w_up", "w_out_NH", "w_out_SH", "tau_ex",
      "u_hs", "tau_q", "q_attach_from",   # HILDA HS/HD (2026-09-05, -05f)
      "w_eq", "gamma_eq",                 # the equatorial cell (2026-09-13g)
      "q_tr",                             # the tropical box (2026-09-14f)
      "w_vent", "gamma_vent",                   # the ventilation loop (2026-09-14 h)
      "w_thc",                                  # the HS-route deep return (2026-09-15 d)
      "w_enso_l2",                              # the layer-2 Nino3.4 limb (2026-09-17 k)
      "pump_seas_amp", "pump_seas_lag",         # the seasonal export (2026-09-15 f; structural)
      "pump_hs_seas_amp", "pump_hs_seas_lag",   # O5b, the HS pump's own shape (2026-09-16 b; structural)
      "q_conv", "conv_sink", "conv_descent", "conv_reverse", "pump_mode",
      "npp_leaf_frac", "tau_leaf", "tau_wood",
      "litter_slow_frac", "tau_soil_fast", "tau_soil_slow",
      "npp_veg_frac", "ra_ratio", "f_luc_perm", "f_luc_wood",
      "sst_scale", "gamma_enso_land_NH", "gamma_enso_land_SH",
      "gamma_enso_ocn_NH", "gamma_enso_ocn_SH",
      "seas_amp_NH", "seas_amp_SH",
      "seas_phase_NH", "seas_phase_SH",
      "seas_drivers", "seas_ml_on", "seas_T_amp_NH", "seas_T_amp_SH",
      "seas_lag_p_NH", "seas_lag_p_SH",
      "seas_T_lag", "sst_seas_lag_NH", "sst_seas_lag_SH",   # run inputs since 2026-10-12 (label ...wtc)
      "sst_seas_amp_NH", "sst_seas_amp_SH", "ent_seas_amp_SH",
      "sst_obs", "seas_npp_amp_NH", "seas_npp_amp_SH",
      "hs_sst_anom_frac",                       # the HS box's share of the SST anomaly (2026-10-05; §3.4a T)
      "revelle_frozen", "gamma_diff",
      "tau_ex_seas_amp", "tau_ex_seas_phase",
      "ndep_ret", "npp_tsens")]
}

#' Forcing table -> the matrix the C++ expects, in its column order
# Column ORDER is the contract with src/ccx_core.cpp, which indexes f[] by
# position. Adding, removing or reordering a name here requires the same edit
# there; a mismatch is silent garbage, not an error, so both sides state the
# layout and test-parity.R runs them against each other.
CCX_FORCING_COLS <- c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH",
                      "gmst", "enso", "c14_bomb", "c14_nuclear", "c14_cosmo",
                      "d13c_foss", "cum_luc_NH", "cum_luc_SH",
                      # observed SST anomalies (2026-08-18), appended LAST so
                      # every earlier index survives. A forcing without them
                      # reaches C++ as NaN, and the core falls back to
                      # sst_scale * gmst -- the absence contract, in the matrix.
                      "sst_anom_NH", "sst_anom_SH",
                      # artificial mid-century OCEAN sink (2026-08-23c),
                      # GtC/yr atmosphere -> mixed layer, GLOBAL: the deriv
                      # splits it on the ocean-area shares. Appended LAST for
                      # the same reason the sst columns were -- every earlier
                      # index survives. Zero, not NaN, is its "off" value, and
                      # ccx_build_forcing() always emits it.
                      "sink_ocean",
                      # VOLCANIC stratospheric AOD, hemispheric (2026-08-29).
                      # Appended LAST for the third time and for the same reason
                      # -- every earlier index survives. Its "off" value is ZERO
                      # (a quiet stratosphere), and ccx_build_forcing() always
                      # emits it; a hand-built forcing without it reaches C++ as
                      # NaN and the core reads that as zero, same absence
                      # contract as the sst columns.
                      "aod_NH", "aod_SH",
                      # N DEPOSITION onto LAND, Tg N/yr above 1750, hemispheric
                      # (D2 (a), 2026-09-30). Appended LAST for the fourth time,
                      # same reason. "Off" is ZERO (no anthropogenic deposition);
                      # ccx_build_forcing() always emits it, and an absent column
                      # reaches C++ as NaN, which the core reads as zero.
                      "ndep_NH", "ndep_SH",
                      # the nuclear 14C NH share (2026-10-12; label ...wtc). Appended
                      # LAST for the fifth time. ccx_build_forcing() always emits it (the
                      # constant 0.95 under nuc_share = "constant"); an absent column
                      # reaches C++ as NaN, which the core reads as the aux scalar.
                      "nuc_share_NH")

ccx_cpp_forcing <- function(F) {
  miss <- setdiff(CCX_FORCING_COLS, names(F))
  if (length(miss))
    stop("forcing table is missing column(s): ", paste(miss, collapse = ", "),
         ". Build it with ccx_build_forcing().")
  as.matrix(F[, CCX_FORCING_COLS])
}

#' Run the model using the C++ core. Same signature and return shape as ccx_run().
#'
#' @param substeps RK4 substeps per month, or "auto" (default) for the smallest
#'   count that keeps the explicit diffusion term stable -- see the stability
#'   section of R/model.R. "auto" resolves to 4 at every ordinary parameter
#'   value, so this default does not change any existing result.
#'   ⚠ (code review 2026-10-12) Not under the seasonal mixed layer: there it
#'   is 4 at the canonical's h_ml (64.63) but 5 / 6 / 9 / 13 at h_ml 68 / 70 /
#'   72 / 73 and more toward the P8 bound -- see the stability section of
#'   R/model.R. A retried run is -Inf in the objective since 2026-09-16 (d).
#' @param retry_na if the run still produces NAs (the air-sea corner, which the
#'   diffusion criterion deliberately does not cover), double the substep count
#'   and try again, up to CCX_SUBSTEPS_MAX. A NA that survives that is a real
#'   model failure, not an integrator artefact -- which is the whole point: a
#'   caller's `anyNA` -> -Inf guard must not double as a prior bound.
ccx_run_fast <- function(spin, F, substeps = "auto", retry_na = TRUE) {
  if (!inherits(F, "ccx_cpp_forcing")) F <- ccx_fill_prod_c14(F, spin)   # finding 6 (09-16 d); see R/forcing.R
  # `spin$enso_hist` (W1, 2026-10-02): the ENSO months before F's first row, when this
  # state continues an earlier run; NULL for a spinup (see ccx_land_enso()).
  ccx_run_prepared(spin$y, ccx_run_prepare(spin, substeps), F, retry_na = retry_na,
                   enso_hist = spin$enso_hist, tdeep0 = spin$tdeep0)
}

#' The MARSHALLED arguments of `ccx_run_fast()`, built ONCE for many runs
#'
#' `ccx_periodic_spinup()` calls the one-year map ~260-300 times per objective
#' evaluation with the SAME `params`/`aux`/`grid` and a different `y`, and each
#' call re-ran `ccx_cpp_par()`, `ccx_cpp_aux()` and the substep resolution
#' (an eigenvalue bound) -- 23 % of every evaluation (review 2026-09-12, B1).
#' This marshals once; `ccx_run_prepared()` runs from it. `ccx_run_fast()` is
#' now the one-shot composition of the two, so there is ONE marshalling path
#' and the numbers that reach the core are the same bytes either way.
#'
#' ⚠ A prepared object is bound to the `params`/`aux`/`grid` it was built from.
#' It carries the marshal gate's verdict for THAT pair; reusing it after a
#' parameter change is the 09-09t leak's mechanism, so build it where you
#' build `aux` and let it go out of scope with it.
ccx_run_prepare <- function(spin, substeps = "auto") {
  ccx_load_cpp()
  ccx_seas_ml_marshal_check(spin$params, spin$aux)
  list(par = ccx_cpp_par(spin$params),
       aux = ccx_cpp_aux(spin$aux, spin$grid),
       ss  = ccx_resolve_substeps(substeps, spin$params, spin$grid),
       box_names = ccx_box_names(spin$grid$nl, ccx_hs_on(spin$params), ccx_eq_on(spin$params),
                                 ccx_tr_on(spin$params), ccx_inert_on(spin$params)),
       hs_on = ccx_hs_on(spin$params), eq_on = ccx_eq_on(spin$params),
       tr_on = ccx_tr_on(spin$params),
       enso_index = ccx_enso_index_of(spin$params),
       aod_mode = ccx_aod_mode_of(spin$params),
       nuc_share = ccx_nuc_share_of(spin$params),       # 2026-10-12, label ...wtc
       # D2 (a): a nonzero retention must meet a forcing that CARRIES deposition
       ndep_ret = if (is.null(spin$params$ndep_ret)) CCX_NDEP_RET_DEFAULT else spin$params$ndep_ret,
       # W1 (2026-10-02): the land ENSO lag, months. The core never sees it -- the
       # runner turns it into the lagged series ccx_run_cpp() takes (ccx_land_enso()).
       enso_lag = ccx_enso_lag_of(spin$params),
       # THE STRATIFICATION FEEDBACK (DESIGN §3.4a S, 2026-10-04): its three constants, which
       # the runner turns into the g series ccx_run_cpp() takes (ccx_mix_g_series()). NULL = OFF.
       mix_p = if (ccx_mix_on(spin$params)) spin$params[c("mix_strat_s", "mix_strat_q", "mix_strat_tau")] else NULL)
}

#' A forcing table marshalled ONCE for many `ccx_run_prepared()` calls
ccx_cpp_forcing_prep <- function(F) {
  structure(list(mat = ccx_cpp_forcing(F), t = F$t), class = "ccx_cpp_forcing",
            enso_index = attr(F, "enso_index"), aod_mode = attr(F, "aod_mode"),
            ndep_source = attr(F, "ndep_source"), nuc_share = attr(F, "nuc_share"))
}

#' Run the core from prepared arguments. Same return shape as `ccx_run_fast()`,
#' the SAME NA-retry semantics (doubling substeps up to CCX_SUBSTEPS_MAX), and
#' the same guard columns. `F` is a forcing table or a `ccx_cpp_forcing_prep()`.
ccx_run_prepared <- function(y, prep, F, retry_na = TRUE, enso_hist = NULL, tdeep0 = NULL) {
  Fm <- if (inherits(F, "ccx_cpp_forcing")) F else ccx_cpp_forcing_prep(F)
  # the forcing's ENSO index must be the one the parameters name (2026-09-29)
  ccx_enso_index_check(if (is.null(prep$enso_index)) "demean" else prep$enso_index, Fm)
  ccx_aod_mode_check(if (is.null(prep$aod_mode)) "legacy" else prep$aod_mode, Fm)
  ccx_nuc_share_check(if (is.null(prep$nuc_share)) "constant" else prep$nuc_share, Fm)   # 2026-10-12
  ccx_ndep_check(prep$ndep_ret, Fm)                 # D2 (a), 2026-09-30
  # THE LAND ENSO INPUT (W1, 2026-10-02): the SAME builder ccx_run() uses, so the two
  # cores integrate one series. Unlagged, it IS the matrix's enso column.
  land_enso <- unname(ccx_land_enso(Fm$mat[, "enso"],
                                    if (is.null(prep$enso_lag)) 0 else prep$enso_lag, enso_hist))
  # THE STRATIFICATION FEEDBACK's g (DESIGN §3.4a S): the SAME builder ccx_run() uses, so the
  # two cores integrate one series. All ones when off (the core then never reads it).
  mix_g <- if (is.null(prep$mix_p)) rep(1, nrow(Fm$mat)) else
    as.numeric(ccx_mix_g_series(unname(Fm$mat[, "gmst"]), Fm$t, prep$mix_p, tdeep0))
  ss <- prep$ss
  one <- function(nsub) {
    res <- .ccx_cpp_env$ccx_run_cpp(y, prep$par, Fm$mat, Fm$t, prep$aux, as.integer(nsub),
                                    land_enso, mix_g)
    out <- as.data.frame(res$out)
    # The C++ matrix width is a literal there; tie it to the R-side column
    # vector LOUDLY (a mismatch used to be a positional mis-naming, not an error).
    if (ncol(out) != 11L + length(CCX_OCEAN_BOX_COLS))
      stop("ccx_run_fast(): the C++ out matrix has ", ncol(out), " columns; R expects ",
           11L + length(CCX_OCEAN_BOX_COLS), " (11 + CCX_OCEAN_BOX_COLS). Rebuild the core.")
    names(out) <- c("co2_NH", "co2_SH", "d13c_NH", "d13c_SH",
                    "d14c_NH", "d14c_SH", "ocean_C", "land_C",
                    "ocean_C14", "land_C14", "atm_C14",
                    CCX_OCEAN_BOX_COLS)
    state <- res$state
    dimnames(state) <- list(prep$box_names, CCX_TRACERS)
    npp <- data.frame(t = Fm$t, npp_NH = res$npp[, 1], npp_SH = res$npp[, 2])
    list(state = state, out = cbind(t = Fm$t, out), npp = npp, substeps = as.integer(nsub),
         # ⚠ THE COUNT THE CALLER ASKED FOR (2026-09-16 d). A retry below runs
         # the transient at a HIGHER count than the spinup that produced `y`,
         # and the fixed point of the 4-step map is NOT on the 64-step orbit:
         # measured at the canonical, a transient-only refinement manufactures
         # -3.0 log-units at h_ml 65.2 and -13.5 at 71.0 while the like-for-like
         # integrator error is <= 0.15 (review 09-16 c, finding 3). So a
         # retried result is a DIFFERENT NUMBER, not a more accurate one; the
         # objective refuses it (ccx_make_logpost) and the periodic spinup's
         # one-year map never retries. `retried` says which happened.
         substeps_requested = as.integer(ss0), retried = nsub != ss0)
  }
  ss0 <- ss
  r <- one(ss)
  # The NaN guard reads the PHYSICS columns only: with the HILDA structure off
  # the hs_* columns are NA BY CONTRACT (the box does not exist, 2026-09-07f),
  # and reading them here doubled the substeps to CCX_SUBSTEPS_MAX on every
  # structure-off run -- a 1e-4 R-vs-C++ parity break that looked like physics.
  # ... and the eq_* columns likewise with the equatorial cell off (2026-09-13g).
  guard_cols <- names(r$out)
  if (!prep$hs_on) guard_cols <- grep("^hs_", guard_cols, invert = TRUE, value = TRUE)
  if (!isTRUE(prep$eq_on)) guard_cols <- grep("^eq_", guard_cols, invert = TRUE, value = TRUE)
  if (!isTRUE(prep$tr_on)) guard_cols <- grep("^tr_", guard_cols, invert = TRUE, value = TRUE)
  # ... AND THE FINAL STATE (2026-10-12, code review sec.5): `out` holds month-OPENING states, so
  # a NaN made during the LAST month reached only `state` and escaped the guard. The state holds
  # only the boxes the structure has, so it is never NA by contract.
  while (retry_na && (anyNA(r$out[, guard_cols]) || anyNA(r$state)) && ss < CCX_SUBSTEPS_MAX) {
    ss <- min(2L * ss, CCX_SUBSTEPS_MAX)
    r  <- one(ss)
  }
  r
}

#' The `out` columns a NaN guard may read: every column when the HILDA boxes
#' are on, every column but the hs_* ones when they are off (those are NA by
#' contract, not by blow-up). Use this wherever `anyNA(out)` stands guard.
ccx_out_na_guard_cols <- function(out, p) {
  cols <- names(out)
  if (!ccx_hs_on(p)) cols <- grep("^hs_", cols, invert = TRUE, value = TRUE)
  if (!ccx_eq_on(p)) cols <- grep("^eq_", cols, invert = TRUE, value = TRUE)   # the cell (2026-09-13g)
  if (!ccx_tr_on(p)) cols <- grep("^tr_", cols, invert = TRUE, value = TRUE)   # the tropical box (2026-09-14f)
  cols
}

#' The MARSHALLED `p`/`aux` of `ccx_deriv_fast()`, built ONCE for many calls
#'
#' `ccx_spinup()` makes ~190 single-derivative calls per solve on ONE
#' `(p0, aux, grid)` and each re-marshalled both lists -- about half of the
#' spinup's wall time (review 2026-09-12, B2). Same binding caveat as
#' `ccx_run_prepare()`: it is tied to the pair it was built from.
ccx_deriv_prepare <- function(p, aux, grid) {
  ccx_load_cpp()
  ccx_seas_ml_marshal_check(p, aux)
  list(par = ccx_cpp_par(p), aux = ccx_cpp_aux(aux, grid))
}

#' Single derivative via the C++ core (used by the parity gate and the spinup)
#'
#' @param forc a point-forcing list, or the flat numeric vector
#'   `ccx_cpp_forcing_vec()` builds from one (the spinup flattens its three
#'   constant forcings once).
#' @param prep an optional `ccx_deriv_prepare(p, aux, grid)`; when given, `p`,
#'   `grid` and `aux` are not re-marshalled (they must be the same objects).
ccx_deriv_fast <- function(y, t, p, forc, grid, aux, prep = NULL) {
  ccx_load_cpp()
  f <- if (is.numeric(forc)) forc else ccx_cpp_forcing_vec(forc)
  # THE LAND ENSO INPUT (W1, 2026-10-02). A list point forcing resolves it exactly as
  # ccx_deriv() does (ccx_point_land_enso(): the runner's `land_enso`, else the index,
  # refused under a lag). A FLATTENED vector is the spinup's CONSTANT forcing, whose
  # lagged index is the index itself -- but only a zero index makes that safe to
  # assume without a history, so a nonzero one under a lag is refused here.
  if (is.numeric(forc)) {
    land_enso <- f[[match("enso", CCX_FORCING_COLS)]]
    if (ccx_enso_lag_of(p) != 0 && isTRUE(land_enso != 0))
      stop("ccx_deriv_fast(): a FLATTENED forcing with a nonzero ENSO index (", land_enso,
           ") under a lagged land term. Pass the point forcing as a list carrying `land_enso`.")
  } else land_enso <- ccx_point_land_enso(forc, p)
  # THE STRATIFICATION FEEDBACK's g (DESIGN §3.4a S). A FLATTENED vector is the spinup's
  # constant forcing: exact as g = 1 only at GMST <= 0 (T_deep = 0), refused otherwise.
  mix_g <- if (!ccx_mix_on(p)) 1 else if (is.numeric(forc)) {
    T0 <- f[[match("gmst", CCX_FORCING_COLS)]]
    if (isTRUE(T0 > 0))
      stop("ccx_deriv_fast(): a FLATTENED forcing with GMST ", T0, " under the stratification ",
           "feedback. Pass the point forcing as a list carrying `mix_g`.")
    1
  } else ccx_point_mix_g(forc, p)
  if (is.null(prep)) {
    ccx_seas_ml_marshal_check(p, aux)
    prep <- list(par = ccx_cpp_par(p), aux = ccx_cpp_aux(aux, grid))
  }
  d <- .ccx_cpp_env$ccx_deriv_cpp(y, t, prep$par, f, prep$aux, as.numeric(land_enso), as.numeric(mix_g))
  dimnames(d) <- dimnames(y)
  d
}

#' A point forcing flattened into the vector the C++ derivative indexes by
#' POSITION against CCX_FORCING_COLS
ccx_cpp_forcing_vec <- function(forc) {
  cl <- ccx_forcing_cum_luc(forc)
  f <- c(forc$e_foss$NH, forc$e_foss$SH, forc$e_luc$NH, forc$e_luc$SH,
         forc$gmst, forc$enso, forc$c14_bomb, forc$c14_nuclear, forc$c14_cosmo,
         ccx_forcing_d13c_foss(forc), cl$NH, cl$SH,
         # absent in most hand-built test forcings -> NaN -> C++ falls back
         if (is.null(forc$sst_anom_NH)) NA_real_ else forc$sst_anom_NH,
         if (is.null(forc$sst_anom_SH)) NA_real_ else forc$sst_anom_SH,
         # absent -> 0, NOT NaN: this one has a well-defined "off" value and a
         # NaN would poison the mixed-layer tendency rather than fall back.
         if (is.null(forc$sink_ocean)) 0 else forc$sink_ocean,
         # VOLCANIC stratospheric AOD, hemispheric.
         # ⚠ THESE WERE MISSING FROM 2026-08-29g TO 2026-08-29k. The columns were
         # appended to CCX_FORCING_COLS and to the C++ (which reads f[15]/f[16]),
         # and ccx_cpp_forcing() -- the MATRIX path ccx_run_fast() uses -- was
         # correct throughout. This SINGLE-STEP builder was not: it stopped at
         # sink_ocean, so the core indexed two slots PAST THE END of a 15-element
         # vector. Nothing errored and nothing was caught, because `gamma_diff`
         # defaulted to 0 and the out-of-bounds read was multiplied by zero.
         # ADOPTING gamma_diff = 0.25 is what exposed it, as an R-vs-C++ parity
         # break of ~0.07 GtC/yr in the NPP-fed pools.
         # The lesson is structural, and test-parity.R now pins it: a flat
         # forcing vector must be length(CCX_FORCING_COLS) BY CONSTRUCTION, not
         # by whoever last appended a column remembering this second site.
         if (is.null(forc$aod_NH)) NA_real_ else forc$aod_NH,
         if (is.null(forc$aod_SH)) NA_real_ else forc$aod_SH,
         # N deposition (D2 (a), 2026-09-30): absent -> NaN -> the core reads zero.
         if (is.null(forc$ndep_NH)) NA_real_ else forc$ndep_NH,
         if (is.null(forc$ndep_SH)) NA_real_ else forc$ndep_SH,
         # the nuclear NH share (2026-10-12): absent -> NaN -> the core reads the aux scalar
         if (is.null(forc$nuc_share_NH)) NA_real_ else forc$nuc_share_NH)
  # STRUCTURAL GUARD, not a comment: the C++ indexes this vector by POSITION
  # against CCX_FORCING_COLS, so a short vector is an out-of-bounds read that
  # neither language reports.
  if (length(f) != length(CCX_FORCING_COLS))
    stop("ccx_deriv_fast(): flat forcing vector has ", length(f), " element(s) but ",
         "CCX_FORCING_COLS declares ", length(CCX_FORCING_COLS),
         ". The C++ indexes by position -- a mismatch reads past the buffer. ",
         "A column was appended to CCX_FORCING_COLS without extending this builder.")
  f
}
