# =====================================================================
# lib_ms_seed.R -- the dispersed multistart's SEEDED STARTS (ids 3-5) and the refusal of a DUPLICATE start vector
# (2026-10-07 m; the driver half of Marcus's "Records now, driver later (Recommended)", owed once #18 landed).
# Sourced by run_dispersed_multistart.R and by tests/testthat/test-ms-seed.R.
#
# ⛔ THE DEFECT, TWICE ([[pinned_name_seed_vanishes]]). A seed SETS a name in the parameter list; the encoder
# (ccx_par_to_unc) walks only CCX_PARAM_NAMES -- the FITTED set after the gate and the pins -- so a seed on a name
# the arm does not fit vanishes and the "seeded" start IS the reference it is named for. 09-17 fixed ONE case (the
# ocean pair pinned -> seed the limb's w_enso_l2). The interannual cut (#17, #18) pins w_enso_l2 AND the land pair,
# so ids 3 / 4 / 5 re-ran ids 1 / 2 / 2 bit for bit, while their labels said "w_enso_l2 SET to 25 Sv" and "land
# x1.734"; #17's "basin B x8" was 5 distinct starts. A fix keyed on a LIST of pinned cases re-opens the moment a later
# pin set pins the fallback.
#
# ⭐ SO THE FIX IS TWO RULES, AND NEITHER IS A LIST OF PINNED CASES:
#   (1) A SEED TARGETS ONLY NAMES IN THE FITTED SET (`free`), and whether it SEEDED is read off the ENCODED vector:
#       a slot whose encoded start is identical() to its reference's is UNSEEDABLE under this arm. The driver then
#       runs that id as a DISPERSED DRAW, labelled UNSEEDABLE with the reason (RULED: "an unseedable seeded slot
#       becomes a dispersed draw, labelled as such"). The label names what LANDED and what was DROPPED, and it is
#       built in the same branch that moves the value, never typed beside it.
#   (2) NO TWO STARTS OF AN ARRAY ARE ONE VECTOR. Every task -- the preflight included -- compares its own start
#       with every FIXED start that needs no draw and STOPS on an identical() one, naming both ids. Two dispersed
#       draws differ by their seeds (MS_SEED + id); a draw that collapses onto a fixed start (a zero spread lands
#       on the cold init) is caught against the fixed set like anything else.
# =====================================================================

MS_ENSO_OCN_PAIR  <- c("gamma_enso_ocn_NH", "gamma_enso_ocn_SH")
MS_ENSO_LAND_PAIR <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
MS_ENSO_L2_NAME   <- "w_enso_l2"
MS_SEED_SLOTS     <- c("inc_enso", "new_enso", "new_obs")

#' Build one seeded slot's start, under an arm's FITTED set.
#' @param slot one of MS_SEED_SLOTS: inc_enso (the incumbent + the ENSO seed at the HIGH edge), new_enso (the new
#'   basin + the same at the LOW edge), new_obs (the new basin + the observation-implied partition: the ENSO seed at
#'   the HIGH edge and the land pair scaled)
#' @param p the reference point's parameter list: P_INC for inc_enso, P_NEW for the other two
#' @param free the arm's fitted names (CCX_PARAM_NAMES once the gate and the pins are applied)
#' @param pinned the names the arm PINS (names(MS_PINS)); only the WORDING of the limb label reads it
#' @param limb_on ccx_l2_on() of the run's base: w_enso_l2 is inert without the limb, so it is no seed target then
#' @param l2_edges Meinen's per-index bracket in Sv, c(14, 25)
#' @param ocn_opt,ocn_obs the ocean-pair seed values (MS_ENSO_OCN_OPT, MS_ENSO_OCN_OBS)
#' @param land_mult the land-pair multiplier (MS_ENSO_LAND_OBS)
#' @param encode the encoder; ccx_par_to_unc in the driver
#' @return list(seeded, u = the encoded seeded vector (NULL when unseedable), kind = its label (NA when unseedable),
#'   why = why it is unseedable (NA when seeded), landed = the names whose ENCODED value moved, dropped = the names
#'   the seed meant to move and could not, slot_label = what the slot is for)
ms_seed_slot <- function(slot, p, free, pinned, limb_on, l2_edges, ocn_opt, ocn_obs, land_mult,
                         encode = ccx_par_to_unc) {
  slot <- match.arg(slot, MS_SEED_SLOTS)
  edge <- if (identical(slot, "new_enso")) "lo" else "hi"
  slot_label <- switch(slot, inc_enso = "the INCUMBENT + the ENSO seed",
                       new_enso = "the NEW BASIN + the ENSO seed",
                       new_obs  = "the NEW BASIN + the OBSERVATION-implied partition")
  q <- p
  # ---- the ENSO coordinate: the ocean pair when the arm fits it; else the limb's w_enso_l2 when the limb is on and
  # the arm fits it; else nothing. ⚠ "fits" is `free`, never "is not in the pins": the gate removes names too.
  x <- if (identical(slot, "new_obs")) ocn_obs else ocn_opt
  if (all(MS_ENSO_OCN_PAIR %in% free)) {
    q$gamma_enso_ocn_NH <- x; q$gamma_enso_ocn_SH <- x
    enso <- list(targets = MS_ENSO_OCN_PAIR, gone = character(0), off = NULL,
                 lab = if (identical(slot, "new_obs")) sprintf("the ocean ENSO pair SET to %+0.3f each", x)
                       else sprintf("the ocean ENSO pair SET to %+0.3f each (the 09-01 conditional optimum of the 08-31e basin; a perturbation here)", x))
  } else if (isTRUE(limb_on) && MS_ENSO_L2_NAME %in% free) {
    v <- if (edge == "hi") max(l2_edges) else min(l2_edges)
    q[[MS_ENSO_L2_NAME]] <- v
    enso <- list(targets = MS_ENSO_L2_NAME, gone = character(0), off = NULL,
                 lab = sprintf("the ocean ENSO pair %s; the limb's w_enso_l2 SET to %g Sv per index (the %s edge of Meinen's bracket)",
                               if (all(MS_ENSO_OCN_PAIR %in% pinned)) "PINNED" else "NOT FITTED by this arm",
                               v, if (edge == "hi") "HIGH" else "LOW"))
  } else {
    enso <- list(targets = character(0),
                 gone = c(setdiff(MS_ENSO_OCN_PAIR, free), if (isTRUE(limb_on)) setdiff(MS_ENSO_L2_NAME, free)),
                 off = if (!isTRUE(limb_on)) "the limb is off", lab = NA_character_)
  }
  # ---- the land pair (new_obs only): scale each member the arm fits
  land <- NULL
  if (identical(slot, "new_obs")) {
    lf <- intersect(MS_ENSO_LAND_PAIR, free)
    for (n in lf) q[[n]] <- q[[n]] * land_mult
    land <- list(targets = lf, gone = setdiff(MS_ENSO_LAND_PAIR, free), off = NULL, lab = sprintf("land x%.3f", land_mult))
  }
  # ---- RULE (1): what MOVED is the ENCODER's answer, and every label below is read off it
  u_ref <- encode(p); u <- encode(q)
  moved <- names(u)[unname(u) != unname(u_ref)]
  read <- function(c, what) {
    m <- intersect(c$targets, moved); still <- setdiff(c$targets, moved)
    notes <- c(if (length(c$gone)) sprintf("%s not fitted by this arm", paste(c$gone, collapse = ", ")),
               c$off,
               if (length(still)) sprintf("%s already at the seed's value at the reference", paste(still, collapse = ", ")))
    c$moved <- m; c$dropped <- c(c$gone, still); c$notes <- notes
    c$lab <- if (length(m) && !length(notes)) c$lab
             else if (length(m)) sprintf("%s, on %s only (%s)", c$lab, paste(m, collapse = ", "), paste(notes, collapse = "; "))
             else sprintf("%s NOT applied (%s)", what, paste(notes, collapse = "; "))
    c
  }
  enso <- read(enso, "the ENSO seed")
  if (!is.null(land)) land <- read(land, "the land seed")
  dropped <- c(enso$dropped, land$dropped)
  if (identical(u, u_ref))
    return(list(seeded = FALSE, u = NULL, kind = NA_character_,
                why = paste(c(sprintf("the ENSO seed: %s", paste(enso$notes, collapse = "; ")),
                              if (!is.null(land)) sprintf("the land seed: %s", paste(land$notes, collapse = "; "))),
                            collapse = "; "),
                landed = character(0), dropped = dropped, slot_label = slot_label))
  kind <- switch(slot,
    inc_enso = paste("seeded: INCUMBENT with", enso$lab),
    new_enso = paste("seeded: NEW BASIN with", enso$lab),
    new_obs  = sprintf("seeded: NEW BASIN + the OBSERVATION-implied partition (%s; %s)", enso$lab, land$lab))
  list(seeded = TRUE, u = u, kind = kind, why = NA_character_, landed = c(enso$moved, land$moved), dropped = dropped,
       slot_label = slot_label)
}

#' The label of an UNSEEDABLE slot's dispersed draw: the slot, the reason, and the draw's own label.
ms_unseedable_kind <- function(slot, s, draw_kind)
  sprintf("UNSEEDABLE seeded slot '%s' (%s): %s -- so this id runs a DISPERSED DRAW instead: %s",
          slot, s$slot_label, s$why, draw_kind)

#' RULE (2): refuse a start vector identical() to another start of the array.
#' @param id this task's id
#' @param u its start vector
#' @param others the array's FIXED starts, a list named by id; NULL where the slot is a draw
#' @return invisibly TRUE; stops on a duplicate, naming both ids
ms_assert_distinct_start <- function(id, u, others) {
  if (is.null(names(others)) || any(!nzchar(names(others))))
    stop("ms_assert_distinct_start(): `others` must be a list NAMED by start id")
  for (j in names(others)) {
    v <- others[[j]]
    if (is.null(v) || identical(as.integer(j), as.integer(id))) next
    if (identical(unname(v), unname(u)))
      stop(sprintf(paste0("DUPLICATE START: id %d's start vector is identical() to id %s's, so the two tasks would run ",
                          "the same optimisation and the record would count it twice ([[pinned_name_seed_vanishes]]). ",
                          "A seeded slot whose seed this arm cannot encode must run as a dispersed draw ",
                          "(lib_ms_seed.R rule 1); fix the start, do not launch."), as.integer(id), j))
  }
  invisible(TRUE)
}
