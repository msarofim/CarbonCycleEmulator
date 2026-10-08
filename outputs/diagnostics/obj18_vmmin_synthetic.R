# obj18_vmmin_synthetic.R -- does R's optim(method = "BFGS") return, at NORMAL convergence, a `par` it never evaluated
# and whose f differs from the returned `value`? (CHANGELOG 2026-10-08 a; the id 13 DEAD gate.) A smooth quadratic plus
# a DETERMINISTIC, ulp-sensitive noise term of amplitude SY_NOISE (CCX's own floor is ~1e-6, ~1e-5 at id 13), every
# evaluation recorded. Seeded: SY_SEED, set immediately before the start draws (the only RNG use).
SY_NOISE <- 1e-6; SY_N <- 29L; SY_REPS <- 20L; SY_SEED <- 20261008L
SY_CONTROL <- list(maxit = 100L, reltol = 1e-14)           # the driver's polish control (MS_POLISH_MAXIT 100)
f0 <- function(u) sum((u - seq_len(SY_N) / SY_N)^2) + SY_NOISE * sin(1e17 * sum(u * sqrt(seq_len(SY_N))))
set.seed(SY_SEED)
starts <- lapply(seq_len(SY_REPS), function(i) seq_len(SY_N) / SY_N + stats::rnorm(SY_N, 0, 1e-3))
res <- t(vapply(seq_len(SY_REPS), function(i) {
  E <- new.env(); E$u <- list(); E$v <- numeric(0)
  fn <- function(u) { v <- f0(u); E$u[[length(E$u) + 1L]] <- u; E$v <- c(E$v, v); v }
  o <- stats::optim(starts[[i]], fn, method = "BFGS", control = SY_CONTROL)
  hit <- any(vapply(E$u, function(x) identical(x, o$par), TRUE))
  dmin <- min(vapply(E$u, function(x) max(abs(x - o$par)), 0))
  c(conv = o$convergence, iters = o$counts[["gradient"]], par_evaluated = hit, gap = f0(o$par) - o$value, nearest_du = dmin)
}, numeric(5)))
cat(sprintf("R %s, optim BFGS, control maxit %d reltol %g; noise %g; %d starts (seed %d)\n", getRversion(),
            SY_CONTROL$maxit, SY_CONTROL$reltol, SY_NOISE, SY_REPS, SY_SEED))
print(data.frame(rep = seq_len(SY_REPS), convergence = res[, "conv"], gradients = res[, "iters"],
                 par_evaluated = as.logical(res[, "par_evaluated"]), gap = signif(res[, "gap"], 3),
                 nearest_du = signif(res[, "nearest_du"], 2)), row.names = FALSE)
cat(sprintf("par NOT evaluated in %d of %d; of those, f(par) > value (re-evaluation WORSE, the CCX sign) in %d\n",
            sum(!res[, "par_evaluated"]), SY_REPS, sum(!res[, "par_evaluated"] & res[, "gap"] > 0)))
