# compare_grid.R -- read the harness grid: old (HEAD 3c0bfd8) vs new driver, per arm and id.
D <- "outputs/diagnostics/ms_seed_fix_20261007"
rd <- function(arm, w, id) readRDS(file.path(D, sprintf("start_%s_%s_%03d.rds", arm, w, id)))
for (arm in c("obj16", "obj18")) {
  cat(sprintf("\n==== %s ====\n", arm))
  O <- lapply(0:7, function(i) rd(arm, "old", i)); N <- lapply(0:7, function(i) rd(arm, "new", i))
  for (i in 0:7) {
    o <- O[[i + 1]]; n <- N[[i + 1]]
    cat(sprintf("id %d  old==new u: %-5s  kind same: %-5s  new class %-9s draws %d  assert %s\n", i,
                identical(unname(o$u), unname(n$u)), identical(o$kind, n$kind), n$class, n$draws, n$assert))
    if (!identical(o$kind, n$kind)) cat(sprintf("    old kind: %s\n    new kind: %s\n", o$kind, n$kind))
  }
  dup <- function(L, tag) {
    for (a in 0:6) for (b in (a + 1):7) if (identical(unname(L[[a + 1]]$u), unname(L[[b + 1]]$u)))
      cat(sprintf("  %s DUPLICATE: id %d == id %d\n", tag, a, b))
  }
  cat("pairwise identical start vectors among ids 0-7:\n"); dup(O, "OLD"); dup(N, "NEW")
}
