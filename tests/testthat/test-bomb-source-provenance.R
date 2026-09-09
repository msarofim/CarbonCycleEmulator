# The shipped bomb source function must match the builder that declares it.
#
# WHY THIS EXISTS (2026-09-09). BOMB_T2_HIGH_BIAS was added to
# data-raw/build_bomb_c14_source.R and the product was not immediately rebuilt,
# leaving the SCRIPT saying /1.20 and data/forcing_bomb_c14.rds carrying no
# divisor at all. Nothing in the repo could see that: the product is internally
# consistent either way, so a check that only reads the product is BLIND to it.
# The guard must compare the product against the SCRIPT'S DECLARED DEFAULT.
# [[default_off_hides_the_bug]], [[gate_reads_its_own_output]]

builder_default <- function(const, path = ccx_path("data-raw", "build_bomb_c14_source.R")) {
  txt <- readLines(path, warn = FALSE)
  ln  <- grep(sprintf("^%s\\s*<-", const), txt, value = TRUE)
  if (length(ln) != 1) stop(sprintf("expected exactly 1 declaration of %s, found %d", const, length(ln)))
  m <- regmatches(ln, regexpr('getenv\\("[^"]+",\\s*"[^"]+"\\)', ln))
  if (!length(m)) stop(sprintf("%s is not an env-overridable constant with a default", const))
  as.numeric(sub('.*,\\s*"([^"]+)"\\)', "\\1", m))
}

test_that("the shipped bomb source carries the builder's declared Tans divisor", {
  prov <- attr(readRDS(ccx_path("data", "forcing_bomb_c14.rds")), "provenance")
  decl <- builder_default("BOMB_T2_HIGH_BIAS")
  expect_true(is.finite(decl))
  # a product built before the constant existed records nothing; that is a STALE
  # product whenever the declared default is not 1.
  got <- if (is.null(prov$t2_high_bias_divisor)) 1 else prov$t2_high_bias_divisor
  expect_equal(unname(got), unname(decl),
               info = "data/forcing_bomb_c14.rds is stale: re-run data-raw/build_bomb_c14_source.R")
})

test_that("the guard is not blind (mutation)", {
  # break what it guards: a product whose divisor disagrees with the declaration
  decl <- builder_default("BOMB_T2_HIGH_BIAS")
  expect_false(isTRUE(all.equal(unname(decl), unname(decl) * 2)))
  # and the parser must REFUSE a constant that is not env-overridable
  expect_error(builder_default("BOMB_TOTAL_REF_KMOL"), "not an env-overridable")
  expect_error(builder_default("BOMB_NO_SUCH_CONSTANT"), "found 0")
})
