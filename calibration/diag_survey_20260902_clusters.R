# Is the -1482.708 cluster a SECOND OPTIMUM or the same point polished differently?
# The 09-01 survey settled its own "one basin" claim on pairwise u-distance, so
# this uses the same instrument on the same scale.
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
D <- "calibration/output/multistart_20260902_demean25"
fs <- sort(list.files(D, pattern = "^start_[0-9]+\\.rds$", full.names = TRUE))
R  <- lapply(fs, readRDS)
lp <- vapply(R, function(x) x$logpost, numeric(1))
id <- vapply(R, function(x) x$id, integer(1))
cv <- vapply(R, function(x) isTRUE(x$converged), logical(1))
U  <- do.call(rbind, lapply(R, function(x) x$u))
cat(sprintf("%d results | %d converged | best %.4f | worst %.4f\n\n",
            length(R), sum(cv), max(lp), min(lp)))

grp <- ifelse(lp > -1482.65, "A", ifelse(lp > -1500, "B", "outlier"))
for (g in c("A","B","outlier"))
  cat(sprintf("  cluster %-7s n=%2d  logpost %.4f .. %.4f  converged %d/%d\n", g,
              sum(grp==g), max(lp[grp==g]), min(lp[grp==g]), sum(cv[grp==g]), sum(grp==g)))

iA <- which(grp=="A"); iB <- which(grp=="B")
du <- function(i,j) sqrt(sum((U[i,]-U[j,])^2))
wa <- iA[which.max(lp[iA])]; wb <- iB[which.max(lp[iB])]
cat(sprintf("\n  WITHIN A : max pairwise u-distance %.6f (n=%d)\n",
            max(outer(iA, iA, Vectorize(du))), length(iA)))
cat(sprintf("  WITHIN B : max pairwise u-distance %.6f (n=%d)\n",
            max(outer(iB, iB, Vectorize(du))), length(iB)))
cat(sprintf("  A  <->  B: u-distance %.6f  (Delta logpost %.4f)\n", du(wa,wb), lp[wa]-lp[wb]))

d <- U[wa,] - U[wb,]; names(d) <- CCX_PARAM_NAMES
o <- order(abs(d), decreasing = TRUE)[1:6]
cat("\n  the coordinates that separate them (u units):\n")
for (k in o) cat(sprintf("    %-22s %+8.4f    A %+9.4f   B %+9.4f\n",
                         names(d)[k], d[k], U[wa,k], U[wb,k]))
cat(sprintf("\n  BEST OVERALL: id %d, logpost %.4f, converged %s\n",
            id[wa], lp[wa], cv[wa]))
saveRDS(list(files=fs, id=id, logpost=lp, converged=cv, U=U, group=grp),
        file.path(D, "survey_summary.rds"))
