# =====================================================================
# build_npp_modern_target.R -- the MODERN global NPP target for the option-4
# likelihood row (NPP_GLOBAL_PI, Marcus 2026-09-29).
#
# WHY. The model's own 2001-2023 NPP is 69.8-70.0 GtC/yr (calibration/
# diag_model_npp_modern.R) against every verified modern total (52.7-59.2).
# NPP_GLOBAL_PI = 60 is cited only as a present-day number (R/constants.R);
# option 4 lets the record and an observational modern-NPP row decide.
#
# RULINGS (Marcus 2026-09-29):
#   CENTER -- "the mean of verified totals makes the most sense": the verified
#     modern ACTUAL totals of notes/lit_2026-09-29_npp_global_pi.md:
#       MOD17A3HGF C6.1   52.7   2001-2023, data/obs_npp_hemispheric.rds (READ, not typed)
#       Ito 2011          56.2   GCB 17:3161, doi:10.1111/j.1365-2486.2011.02450.x,
#                                ABSTRACT ONLY (full text 403): 56.2 +/- 14.3, n = 251
#       Haberl et al 2007 59.22  PNAS 104:12942, doi:10.1073/pnas.0704243104,
#                                Table 1, ACTUAL NPP (NPPact), year 2000, full text (PMC1911196)
#     Haberl's 65.51 is POTENTIAL NPP and is excluded: the row scores the
#     model's ACTUAL (cleared) NPP.
#   WIDTH -- "increase the spread because of the small n". The three products'
#     sample sd (n = 3) is itself poorly determined, so sigma is its one-sided
#     84 % UPPER CONFIDENCE BOUND: s * sqrt((n - 1) / qchisq(0.16, n - 1)) --
#     the "+1 sigma" bound on a normal sd from n draws. ⚠ The 0.16 is a choice
#     (named below); it is not fitted.
# ⚠ The three cover different years (2001-23, a meta-analysis, 2000); the row
#   scores the model over NMT_WIN, MOD17's span, and treats the others as
#   estimates of the same modern level.
#
# Output: data/obs_npp_modern_target.rds. Usage: Rscript data-raw/build_npp_modern_target.R
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

NMT_WIN      <- c(2001L, 2023L)
NMT_UCB_TAIL <- 0.16          # one-sided tail of the sd's upper confidence bound (RULING: "increase the spread")
NMT_OUT      <- file.path("data", "obs_npp_modern_target.rds")

mod <- readRDS(ccx_path("data", "obs_npp_hemispheric.rds"))
stopifnot(identical(range(mod$years), NMT_WIN))
prod <- c(MOD17_C61_2001_2023 = mod$global_mean_PgC,
          Ito2011_abstract    = 56.2,
          Haberl2007_actual   = 59.22)
n <- length(prod); s <- stats::sd(prod)
infl <- sqrt((n - 1) / stats::qchisq(NMT_UCB_TAIL, n - 1))
out <- list(centre = mean(prod), sd = s * infl, sd_raw = s, inflation = infl,
            products = prod, win = NMT_WIN, units = "GtC/yr (= PgC/yr), global land NPP",
            provenance = list(built = format(Sys.Date()), script = "data-raw/build_npp_modern_target.R",
              rulings = "centre = mean of verified modern actual totals; sd = 84% one-sided UCB (Marcus 2026-09-29)",
              mod17_source = mod$source,
              note = "Ito 2011 abstract only; Haberl potential 65.51 excluded (row scores ACTUAL NPP)"))
saveRDS(out, ccx_path(NMT_OUT))
cat(sprintf("products %s\ncentre %.3f | raw sd %.3f x %.3f = sigma %.3f GtC/yr | window %d-%d\nwrote %s\n",
            paste(sprintf("%s %.2f", names(prod), prod), collapse = ", "),
            out$centre, s, infl, out$sd, NMT_WIN[1], NMT_WIN[2], NMT_OUT))
