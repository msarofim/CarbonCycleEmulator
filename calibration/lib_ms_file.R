# =====================================================================
# lib_ms_file.R -- the dispersed multistart's FILE STARTS (ids 6-9), and the evaluation-identity bound they share with
# PORT GATE (a) (2026-10-23; refit item 2 of notes/handoff_2026-10-23_flask_refit_item2.md §3).
# Sourced by run_dispersed_multistart.R and by tests/testthat/test-ms-file.R.
#
# WHY. The flask refit is ruled as a LOCAL refit from three points (Marcus 2026-10-22: "Local refit from T8c's point
# (Recommended)", "Add it as a third (Recommended)"): the canonical, which is already id 1, and two points a diagnostic
# computed, T8c's block point and T8f's Newton point. Neither is a registered mode, so neither can be a reference or a
# seed. A FILE START takes a named u vector from the rds that CCX_MS_FILE_STARTS names.
#
# THE CONTRACT of that rds (ms_read_file_starts() refuses anything else):
#   starts      a named list, one entry per start, in SLOT ORDER: list(u = a numeric vector named by the run's fitted
#               names, logpost = what the objective scored there where the point was computed, source = what the point
#               is and which file it came from)
#   struct, seas_ml, pump_field, pins   the label the logposts were scored under (pins NULL = a free arm)
#   provenance  a list; recorded, not checked
# ⭐ TWO GATES, both before any optimisation:
#   (1) THE LABEL: the file's struct / seas_ml / pump_field / pins are the run's (pins compared by ccx_pin_label(), as
#       the port gate and ccx_ms_reference_set() compare them), and each u carries exactly the run's fitted names.
#   (2) THE VALUE: the run's objective at the file's u reproduces the file's logpost within PORT GATE (a)'s bound
#       (ms_identity_bound()). A u means nothing without the table it was encoded under, and a point the driver
#       scores differently from where it was computed is another point. The target is read from a file the driver did
#       not write ([[gate_reads_its_own_output]]).
# ⚠ AN EMPTY SLOT IS A DISPERSED DRAW, labelled so (the unseedable-slot precedent, lib_ms_seed.R rule 1). With no file,
# or a file with fewer starts than slots, the slot runs its id's dispersed draw (set.seed(MS_SEED + id)): the vector
# that id drew before the slots existed, so a wave that names no file draws what it drew before.
# =====================================================================

MS_FILE_LABEL_FIELDS <- c("struct", "seas_ml", "pump_field", "pins")

#' Read and check the file starts.
#' @param path the rds (CCX_MS_FILE_STARTS, resolved); "" or NA = no file starts
#' @param n_slots how many file slots the driver reserves
#' @param label the run's label: list(struct, seas_ml, pump_field, pins), pins as MS_PINS (NULL = free)
#' @param param_names the run's fitted names (CCX_PARAM_NAMES once the gate and the pins are applied)
#' @return a list in slot order, each list(name, u = named by param_names in that order, logpost, source); list() when
#'   there is no file
ms_read_file_starts <- function(path, n_slots, label, param_names) {
  if (is.null(path) || is.na(path) || !nzchar(path)) return(list())
  if (!file.exists(path)) stop("CCX_MS_FILE_STARTS names '", path, "', which does not exist.", call. = FALSE)
  x <- readRDS(path)
  if (!is.list(x) || !is.list(x$starts) || !length(x$starts))
    stop("the file starts at '", path, "' carry no `starts` list.", call. = FALSE)
  nm <- names(x$starts)
  if (is.null(nm) || any(!nzchar(nm)) || anyDuplicated(nm))
    stop("the file starts at '", path, "': `starts` must be NAMED, each name once.", call. = FALSE)
  if (length(nm) > n_slots)
    stop("the file starts at '", path, "' hold ", length(nm), " starts, but the driver reserves ", n_slots,
         " file slots. Add slots (MS_FILE_IDS, and CO_FILE_IDS in the collector) or split the file.", call. = FALSE)
  # ---- GATE (1), THE LABEL. Absence asserts: a field the file does not record is refused, not assumed
  # ([[recorded_but_never_restored]]); `pins` must be PRESENT even when NULL (a free arm).
  miss <- setdiff(MS_FILE_LABEL_FIELDS, names(x))
  if (length(miss))
    stop("the file starts at '", path, "' record no ", paste(miss, collapse = ", "), ", so they cannot be shown to ",
         "have been scored under this run's objective.", call. = FALSE)
  for (f in MS_FILE_LABEL_FIELDS) {
    a <- if (identical(f, "pins")) ccx_pin_label(x$pins) else as.character(x[[f]])
    b <- if (identical(f, "pins")) ccx_pin_label(label$pins) else as.character(label[[f]])
    if (!identical(a, b))
      stop("the file starts at '", path, "' were scored with ", f, " '", paste(a, collapse = " "), "'; this run has '",
           paste(b, collapse = " "), "'. Their logposts belong to another objective.", call. = FALSE)
  }
  lapply(nm, function(n) {
    e <- x$starts[[n]]
    u <- e$u
    if (!is.numeric(u) || is.null(names(u)) || anyDuplicated(names(u)))
      stop("file start '", n, "': `u` must be a numeric vector with unique names.", call. = FALSE)
    extra <- setdiff(names(u), param_names); absent <- setdiff(param_names, names(u))
    if (length(extra) || length(absent))
      stop("file start '", n, "': `u` is not named by this run's ", length(param_names), " fitted names (",
           paste(c(if (length(absent)) paste("missing", paste(absent, collapse = ", ")),
                   if (length(extra)) paste("not fitted here", paste(extra, collapse = ", "))), collapse = "; "),
           ").", call. = FALSE)
    if (any(!is.finite(u))) stop("file start '", n, "': `u` has a non-finite entry.", call. = FALSE)
    if (!is.numeric(e$logpost) || length(e$logpost) != 1L || !is.finite(e$logpost))
      stop("file start '", n, "': `logpost` must be one finite number (the target of the value gate).", call. = FALSE)
    if (!is.character(e$source) || length(e$source) != 1L || !nzchar(e$source))
      stop("file start '", n, "': `source` must say what the point is and where it came from.", call. = FALSE)
    list(name = n, u = u[param_names], logpost = e$logpost, source = e$source)
  })
}

#' The label of a file start.
ms_file_kind <- function(slot, e)
  sprintf("file start '%s' (slot %s): %s; it scored %.6f there", e$name, slot, e$source, e$logpost)

#' The label of an EMPTY file slot's dispersed draw: the slot, why it is empty, and the draw's own label.
ms_empty_file_kind <- function(slot, why, draw_kind)
  sprintf("EMPTY file slot %s (%s) -- so this id runs a DISPERSED DRAW instead: %s", slot, why, draw_kind)

#' The objective's ROUNDOFF FLOOR at a point (2026-09-15; PORT GATE (a)'s measurement, moved here 2026-10-23 so the file
#' starts' value gate measures it the same way): lp(u') - here over `n` SEEDED perturbations u' = u * (1 +- eps) of one
#' coordinate. Its RNG stream is private: the caller's .Random.seed is restored (or removed, if there was none).
#' @return the n deltas (the floor is max(abs()) of them)
ms_roundoff_floor <- function(lp_fun, u, here, n, eps, seed) {
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  saved <- if (had) get(".Random.seed", envir = globalenv()) else NULL
  on.exit(if (had) assign(".Random.seed", saved, envir = globalenv()) else rm(".Random.seed", envir = globalenv()))
  set.seed(seed)
  vapply(seq_len(n), function(k) {
    du <- u; j <- sample(length(du), 1L)
    du[j] <- du[j] * (1 + sample(c(-1, 1), 1L) * eps)
    lp_fun(du) - here
  }, numeric(1))
}

#' PORT GATE (a)'s bound on an evaluation identity: max(eval_tol x |target|, k x floor), and its ceiling ceil x |target|.
ms_identity_bound <- function(target, floor, eval_tol, k, ceil) {
  a <- max(abs(target), 1e-12)
  list(tol = max(eval_tol * a, k * floor), ceil = ceil * a)
}
