# Evaluates the CPU-clock build's end-to-end smokes against their PRE-REGISTERED criteria
# (~/ccx_frozen/20261005h_cpuclock_smoke.sh header; CHANGELOG 2026-10-05). Prints PASS/FAIL per criterion.
L <- "~/ccx_frozen/20261005h_cpuclock_smoke_logs"
OLD <- "~/ccx_frozen/20261005h_cpuclock_old/calibration/output"
NEW <- "~/ccx_frozen/20261005h_cpuclock_smoke/calibration/output"
rd  <- function(f) readLines(path.expand(file.path(L, f)), warn = FALSE)
sf  <- function(dir, name) readRDS(path.expand(file.path(dir, name, "start_001.rds")))
res <- character(0)
chk <- function(label, ok, detail) {
  res <<- c(res, sprintf("%-4s %s -- %s", if (isTRUE(ok)) "PASS" else "FAIL", label, detail)); invisible(ok)
}
# ---- T1: the NM restart's line, without its trailing minutes, in all three arms
nm_line <- function(f) {
  x <- grep("^\\[001\\] cycle 1 restart  1: log-post", rd(f), value = TRUE)
  if (length(x) != 1L) return(NA_character_)
  sub("\\s+[0-9.]+ (min|CPU-min)$", "", x)
}
t1 <- vapply(c(old = "T1_old.log", new = "T1_new.log", alias = "T1_alias.log"), nm_line, character(1))
cat("T1 NM restart lines:\n"); print(t1)
chk("T1  old == new (wall clock, NEW name)", !anyNA(t1) && identical(t1[["old"]], t1[["new"]]), t1[["new"]])
chk("T1  old == alias (wall clock, LEGACY name)", !anyNA(t1) && identical(t1[["old"]], t1[["alias"]]), t1[["alias"]])
so <- sf(OLD, "SMOKE_T1_old"); sn <- sf(NEW, "SMOKE_T1_new"); sa <- sf(NEW, "SMOKE_T1_alias")
tr <- function(s) s$trace[1:2, ]   # the start row and cycle 1 restart 1
chk("T1  trace rows 1-2 identical (start + restart 1)", identical(tr(so), tr(sn)) && identical(tr(so), tr(sa)),
    paste(capture.output(print(tr(sn))), collapse = " | "))
chk("T1  start point identical", identical(so$logpost_start, sn$logpost_start) && identical(so$logpost_start, sa$logpost_start),
    sprintf("%.10f", sn$logpost_start))
chk("T1  the old file has no clock; the new ones record wall, budget 12",
    is.null(so$clock) && identical(sn$clock, "wall") && identical(sa$clock, "wall") &&
      identical(sn$budget_min, 12) && identical(sa$budget_min, 12),
    sprintf("old clock %s; new %s/%g; alias %s/%g", format(so$clock), sn$clock, sn$budget_min, sa$clock, sa$budget_min))
chk("T1  wall arm: minutes_wall == minutes to < 0.01", abs(sn$minutes_wall - sn$minutes) < 0.01,
    sprintf("minutes %.3f, minutes_wall %.3f", sn$minutes, sn$minutes_wall))
chk("T1  the alias arm says it read CCX_MS_WALL_MIN", any(grepl("^OVERRIDE CCX_MS_WALL_MIN = 12", rd("T1_alias.log"))), "OVERRIDE line")
chk("T1c both names, different: stopped at start-up", any(grepl("are both set and DIFFER", rd("T1c_conflict.log"))), "the stop message")
# ---- T3: a real suspend
sc <- sf(NEW, "SMOKE_T3_cpu"); sw <- sf(NEW, "SMOKE_T3_wall")
rl <- function(f) grep("^\\[001\\] cycle 1 restart  1", rd(f), value = TRUE)
ev <- function(f) { x <- grep("restart  1: log-post", rl(f), value = TRUE); as.integer(sub(".* evals ([0-9]+) .*", "\\1", x)) }
mx <- function(f) { x <- grep("SHORTENED to maxit", rl(f), value = TRUE); as.integer(sub(".*maxit ([0-9]+) .*", "\\1", x)) }
cat("\nT3 restart lines:\n"); cat(rl("T3_cpu.log"), sep = "\n"); cat(rl("T3_wall.log"), sep = "\n")
cat(sprintf("T3 cpu : clock %s minutes %.3f minutes_wall %.3f n_eval %d deadline_stops %d out_of_time %s wall_warned %s\n",
            sc$clock, sc$minutes, sc$minutes_wall, sc$n_eval, sc$deadline_stops, sc$out_of_time, sc$wall_warned))
cat(sprintf("T3 wall: clock %s minutes %.3f minutes_wall %.3f n_eval %d deadline_stops %d out_of_time %s wall_warned %s\n",
            sw$clock, sw$minutes, sw$minutes_wall, sw$n_eval, sw$deadline_stops, sw$out_of_time, sw$wall_warned))
chk("T3  CPU arm's restart NOT stopped by the suspension", !any(grepl("restart  1: STOPPED AT THE DEADLINE", rl("T3_cpu.log"))),
    sprintf("its restart made %d evals of a sized maxit %d", ev("T3_cpu.log"), mx("T3_cpu.log")))
chk("T3  CPU arm's minutes within its 3-min budget", sc$minutes <= 3 + 0.05, sprintf("%.3f CPU-min", sc$minutes))
chk("T3  CPU arm's wall exceeds its CPU by >= 2.9 (the 3-min stop)", sc$minutes_wall - sc$minutes >= 2.9,
    sprintf("wall - CPU = %.3f min", sc$minutes_wall - sc$minutes))
chk("T3  WALL arm's restart STOPPED AT THE DEADLINE", any(grepl("restart  1: STOPPED AT THE DEADLINE", rl("T3_wall.log"))),
    sprintf("its restart made %d evals of a sized maxit %d", ev("T3_wall.log"), mx("T3_wall.log")))
chk("T3  WALL arm made fewer restart evals than the CPU arm", ev("T3_wall.log") < ev("T3_cpu.log"),
    sprintf("%d < %d", ev("T3_wall.log"), ev("T3_cpu.log")))
chk("T3  WALL arm's minutes include the stop (>= 3)", sw$minutes >= 3, sprintf("%.3f wall-min", sw$minutes))
chk("T3  the record: clocks cpu / wall", identical(sc$clock, "cpu") && identical(sw$clock, "wall"), "start files")
cat("\n"); cat(res, sep = "\n"); cat(sprintf("\n%d PASS, %d FAIL\n", sum(startsWith(res, "PASS")), sum(startsWith(res, "FAIL"))))
