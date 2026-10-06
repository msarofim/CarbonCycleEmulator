# =====================================================================
# make_port_targets.R -- record, ON THE REFERENCE MACHINE, what the objective
# evaluates to at three fixed points, so a PORT can be gated against it.
#
# WHY A FILE AND NOT A LITERAL. `run_dispersed_multistart.R`'s reference ids
# must be able to say "this machine reproduces the objective". The value they
# compare against has to come from somewhere the running script did not produce
# ([[gate_reads_its_own_output]]) -- a gate whose target is its own output
# passes exactly once and thereafter compares a convention against itself.
#
# WHY NOT THE MODE FILES' OWN STORED logpost. Because that is NOT the same
# quantity. The 08-30 incumbent stores -1547.1579 and evaluates to -1548.0112
# in today's build: a -0.85 objective-drift offset that has nothing to do with
# any port. Gating a port against it would spend 85 % of a 1.0-log-unit budget
# on a known, unrelated effect. What a port must reproduce is what THIS BUILD
# computes at THAT point, which is what this file records.
#
# THE THREE POINTS are the reference starts, and they are read out of the mode
# files rather than restated: the cold hand-set init, the 08-30 incumbent, and
# the 08-31e polished new-basin mode.
#
# Re-run this whenever the OBJECTIVE changes. The output carries the commit, the
# host and the timestamp so a stale target is visible rather than silent.
#
# Usage:  Rscript calibration/make_port_targets.R      # ~5 s
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
# the GATE first (2026-09-30), exactly as the driver: an open structure fits four more names
PT_GATE <- ccx_apply_gate(Sys.getenv("CCX_MS_STRUCT", ""))
PT_PINS <- ccx_parse_pins(Sys.getenv("CCX_MS_PIN", ""))   # same contract as the driver (2026-09-13)
invisible(ccx_apply_pins(PT_PINS))
source(ccx_path("calibration", "lib_run_inputs.R"))
ccx_require_run_inputs()   # BEFORE the wall budget, and before any target is written

PT_ARM  <- "N"
PT_OUT  <- ccx_path("calibration", "torch", "port_targets.csv")
PT_COMMIT <- ccx_git_stamp(exclude = PT_OUT)   # the targets file is its product, not an input
# ⛔ RE-RULED 2026-09-10 (round 6): the 08-31e new basin is -Inf at seas_ml = 1
# (h_ml 143.9 m vs the ~75 m P8 wall). MUST MATCH run_dispersed_multistart.R's
# MS_REF_INC / MS_REF_NEW -- the names are the driver's port-target KEYS.
# 2026-09-13 (d): the incumbent FOLLOWS THE PINS, exactly as the driver's MS_REF_INC does
# (the two must agree, or the port gate compares two different points): the canonical
# `hilda30c` under its own pins, the free parent `hilda31s2` for a free run.
# 2026-09-14 (h): pins that EXTEND the canonical's by names the pump field does not
# read (ccx_pins_extend_canonical) also take the canonical -- the E array's case.
# 2026-09-17 (j): ONE rule, ccx_ms_reference_set() (R/calibrate.R), shared with the driver.
.pt_ref <- ccx_ms_reference_set(PT_PINS, Sys.getenv("CCX_MS_SEAS_ML", NA_character_))
PT_INC_NAME <- .pt_ref$incumbent; PT_NEW_NAME <- .pt_ref$new_basin
PT_REFS <- c(
  cold      = NA,   # the hand-set init; no file
  incumbent = CCX_MODE_FILES[[PT_INC_NAME]],  # through the registry; see ccx_ms_reference_set
  new_basin = CCX_MODE_FILES[[PT_NEW_NAME]]   # the other reference; feasible at either seas_ml
)
cat(sprintf("reference set: incumbent %s, new basin %s (%s)\n", PT_INC_NAME, PT_NEW_NAME, .pt_ref$why))

bp <- ccx_default_params(); bp$pump_mode <- PT_ARM
# 2026-09-06d: the SAME definition the driver uses, selected by CCX_MS_STRUCT --
# ⛔ and since 2026-09-10 BOTH label variables must be SET, or this stops. Unset,
# CCX_MS_STRUCT silently yielded the COLUMN model while the sbatch defaulted to
# hilda, and the cold target read -5,436,208 against hilda's -16,211.88 -- a
# ~330x gap that reads exactly like a catastrophic objective regression
# ⇒ [[port_targets_need_the_struct_var]]. CCX_MS_SEAS_ML has the same shape
# with a quieter symptom: unset = 0 = the shipped model, and a round-6 run at
# seas_ml = 1 would then be gated against the wrong objective -- or, if the run
# were ALSO unset, both would agree at 0 and the round-6 refit would silently
# repeat the 09-10 one ⇒ [[ccx_refit_ran_at_seas_ml_0]].
#     CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=1 Rscript calibration/make_port_targets.R
.pt_env_required <- function(k) {
  v <- Sys.getenv(k, NA_character_)
  if (is.na(v)) stop("make_port_targets.R: ", k, " is NOT SET. State the objective's label ",
                     "explicitly, e.g. CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=1 Rscript ",
                     "calibration/make_port_targets.R -- an unset value records the WRONG ",
                     "objective and the consumer cannot tell.")
  v
}
# CCX_MS_PUMP_FIELD (2026-09-14 h) is NOT required: unset = "solved" is a FACT about
# every registered file (ccx_mode_pump_field()), not a default; the E array sets "martin".
bp <- ccx_apply_structure(bp, .pt_env_required("CCX_MS_STRUCT"), .pt_env_required("CCX_MS_SEAS_ML"),
                          pump_field = Sys.getenv("CCX_MS_PUMP_FIELD", "solved"))
for (n in names(PT_PINS)) bp[[n]] <- PT_PINS[[n]]
cat(sprintf("objective label: struct '%s', seas_ml %d, pump_field '%s', pins '%s' (%d free parameters)\n", attr(bp, "struct"), attr(bp, "seas_ml"), attr(bp, "pump_field"), ccx_pin_label(PT_PINS), length(CCX_PARAM_NAMES)))
lp <- ccx_make_logpost(base_params = bp)
.ship <- lapply(CCX_PARAM_TABLE, function(s) c(s$lo, s$hi))

rows <- lapply(names(PT_REFS), function(nm) {
  if (is.na(PT_REFS[[nm]])) {
    u <- ccx_init_unc(); stored <- NA_real_; src <- "ccx_init_unc()"
  } else {
    md <- readRDS(ccx_path(PT_REFS[[nm]]))
    # ⚠ FEASIBILITY IS THE REQUIREMENT; BAND EQUALITY IS NOT (fixed 2026-09-01).
    # This used to REFUSE any file whose recorded bands differed from the shipped
    # table -- and the 09-01 `kz` re-bisection made that every file on disk, so
    # the gate would have blocked its own re-measurement. The claim this file
    # makes is "here is what the objective evaluates to AT THIS POINT UNDER THE
    # TABLE SHIPPED RIGHT NOW". For that, all the point has to be is FEASIBLE;
    # what the file was FITTED under changes the meaning of its own stored
    # logpost, which is reported below and gated on by nothing.
    # [[gate_bound_matches_its_claim]] -- the bound must match the claim, and the
    # claim that actually needs guarding is that the CONSUMER of this file runs
    # the same table, which is why the bracket is now RECORDED in the CSV.
    pmv <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))   # a held name is not absent (09-13 (d))
    # SEED BEFORE the feasibility check (2026-09-06d): kz_deep_frac migrates to
    # 1 = its box's upper bound, so the unseeded ancestor is infeasible by
    # construction; the seed (table init, printed by name) is the start point.
    pmv <- ccx_seed_unencodable(pmv, paste(nm, "port target"))
    bad <- Filter(function(n) {
      b <- .ship[[n]]
      !is.null(b) && all(is.finite(b)) && (pmv[[n]] <= b[1] || pmv[[n]] >= b[2])
    }, CCX_PARAM_NAMES)
    if (length(bad))
      stop(nm, " is NOT FEASIBLE under the shipped table (", paste(bad, collapse = ", "),
           "), so the objective has no finite value there and it cannot be a port target.")
    if (!isTRUE(all.equal(md$kz_bracket, .ship$kz)) ||
        !isTRUE(all.equal(md$hml_bound, .ship$h_ml)))
      cat(sprintf("  NOTE %s was FITTED under kz [%s] / h_ml [%s], not the shipped
       kz [%s] / h_ml [%s]. Its own stored logpost therefore carries a
       reparameterisation constant; the TARGET below does not, because it is
       measured here, now, under the shipped table.
",
                  nm, paste(md$kz_bracket, collapse = ", "), paste(md$hml_bound, collapse = ", "),
                  paste(.ship$kz, collapse = ", "), paste(.ship$h_ml, collapse = ", ")))
    # ⚠ A MIGRATED ANCESTOR MAY CARRY AN UNENCODABLE STATE (2026-09-03): with
    # `ent_seas_amp_SH` in the table under `tr = "log"`, a pre-09-03 vector
    # migrates to 0, which is not a point of the fitted space. Seed it, LOUDLY.
    # The target does not need to be a GOOD point -- it is an identity check
    # that two machines agree at the SAME point -- but it does need to be one
    # both machines can reach, and the seed must be reproducible, which it is:
    # it comes from CCX_PARAM_TABLE, which the bracket columns already gate.
    u <- ccx_par_to_unc(pmv)
    stored <- md$logpost; src <- PT_REFS[[nm]]
  }
  v <- lp(u)
  if (!identical(lp(u), v))
    stop("the objective is not a pure function of u on this machine; a port ",
         "gate against it would be meaningless.")
  # ⛔ A NON-FINITE TARGET IS NOT A TARGET (2026-09-10). At seas_ml = 1 the P8
  # geometry guard (ccx_seas_ml_guard) makes the objective -Inf wherever h_ml
  # exceeds ~76 m, and the 08-31e new-basin reference sits at 143.9 m: it is
  # INFEASIBLE under that objective, and a gate against -Inf can neither pass
  # nor fail (rel = NaN). Refuse to write it; the reference SET has to change,
  # and that is a ruling, not something this script papers over.
  if (!is.finite(v))
    stop("the objective is ", v, " at the '", nm, "' reference point (h_ml = ",
         signif(ccx_unc_to_par(u)$h_ml, 4), " m) under struct '", attr(bp, "struct"),
         "' / seas_ml ", attr(bp, "seas_ml"), ". That point is infeasible under this ",
         "objective and cannot be a port target; PT_REFS must name a feasible one.")
  data.frame(name = nm, logpost = sprintf("%.10f", v),
             stored = if (is.na(stored)) NA_character_ else sprintf("%.10f", stored),
             offset = if (is.na(stored)) NA_character_ else sprintf("%+.10f", v - stored),
             source = src, stringsAsFactors = FALSE)
})
tg <- do.call(rbind, rows)
tg$arm       <- PT_ARM
tg$n_par     <- length(CCX_PARAM_NAMES)
tg$struct    <- attr(bp, "struct")            # "" = column, "hilda" = the declared structure
tg$seas_ml   <- attr(bp, "seas_ml")           # 0 = the shipped model, 1 = round 6 (2026-09-10); READ by the driver's port gate
tg$pump_field <- attr(bp, "pump_field")       # "solved" / "martin" (2026-09-14 h); READ by the driver's port gate
tg$pins      <- ccx_pin_label(PT_PINS)        # "" = free arm; READ by the driver's port gate (2026-09-13)
# ⭐ THE TABLE THESE TARGETS WERE MEASURED UNDER, recorded so a consumer can
# REFUSE a stale target instead of silently comparing across two tables. A
# widened bracket shifts every logpost by a reparameterisation constant, so a
# target measured under one table and checked under another fails for a reason
# that has nothing to do with the port. [[recorded_but_never_restored]] --
# recorded AND read, this time, by run_dispersed_multistart.R.
tg$kz_lo     <- sprintf("%.6f", .ship$kz[1]);   tg$kz_hi   <- sprintf("%.6f", .ship$kz[2])
tg$hml_lo    <- sprintf("%.6f", .ship$h_ml[1]); tg$hml_hi  <- sprintf("%.6f", .ship$h_ml[2])
tg$commit    <- PT_COMMIT
tg$host      <- Sys.info()[["nodename"]]
tg$r_version <- paste(R.version$major, R.version$minor, sep = ".")
tg$measured  <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")

dir.create(dirname(PT_OUT), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(tg, PT_OUT, row.names = FALSE)
cat(sprintf("\nPORT TARGETS written to %s\n\n", PT_OUT))
print(tg[, c("name", "logpost", "stored", "offset")], row.names = FALSE)
cat(sprintf("\n  arm %s, %d parameters, struct '%s', seas_ml %d, commit %s, host %s, R %s\n",
            PT_ARM, length(CCX_PARAM_NAMES), tg$struct[1], tg$seas_ml[1], tg$commit[1], tg$host[1], tg$r_version[1]))
cat("  ⚠ `stored` is each mode FILE's own logpost and is NOT the target: each\n")
off <- tg$offset[!is.na(tg$offset)]; nm <- tg$name[!is.na(tg$offset)]
cat(sprintf("    offset (%s) is objective drift since that file was fitted, not a port defect.\n",
            paste(sprintf("%s %+.2f", nm, as.numeric(off)), collapse = ", ")))   # offset is FORMATTED text in tg
cat("    (This line was a typed '-0.85' until 2026-09-07f; it is now GENERATED.)\n")
