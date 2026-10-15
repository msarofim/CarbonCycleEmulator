# =====================================================================
# lib_martin_shape.R -- a SESSION-LOCAL override of ccx_pump_shape() that
# replaces the GLODAP DIC-excess profile with a MARTIN remineralization shape
# (Martin et al. 1987 DSR 34:267: F(z) = F(z_s) (z/z_s)^-0.858), integrated
# with the model's OWN K(z) so the pump's diffusive-return construction
# (ccx_pump_export()) turns it into Martin's per-layer source.
#
# Source AFTER R/. Set MS_ARM to "glodap" (bit-identical pass-through),
# "martin_tail" (GLODAP above the interface nearest MS_SPLICE_M, Martin below,
# flux-continuous) or "martin_full" (Martin from the mixed-layer base), and
# MS_P to the parameter list whose K(z) applies. Shared by
# diag_td0_martin_shape.R and diag_td0b_martin_kz_scan.R (2026-09-08h) so the
# two cannot drift. Nothing here is adopted; nothing in R/ is touched.
# =====================================================================
MS_MARTIN_B <- ccx_const("MARTIN_B")   # registered R/constants.R 2026-09-14 h; was the literal 0.858
MS_SPLICE_M <- 1000
MS_ARMS     <- c("glodap", "martin_tail", "martin_full")
if (!exists(".ms_shape_glodap", inherits = TRUE)) .ms_shape_glodap <- ccx_pump_shape
MS_ARM <- "glodap"; MS_P <- NULL
ccx_pump_shape <- function(grid) {
  sh <- .ms_shape_glodap(grid)
  if (identical(MS_ARM, "glodap")) return(sh)
  stopifnot(!is.null(MS_P), MS_ARM %in% MS_ARMS)
  nl  <- grid$nl
  zi  <- cumsum(grid$dz)[seq_len(nl)]          # interface depths; z_1 = h_ml
  K   <- ccx_kz_profile(MS_P, grid)            # the model's OWN K at each interface
  dzm <- diff(grid$depth_mid)                  # == aux$dz_mid
  Fg  <- K * diff(sh) / dzm                    # GLODAP-implied interface flux, shape units
  ks  <- if (identical(MS_ARM, "martin_full")) 1L else which.min(abs(zi - MS_SPLICE_M))
  Fm  <- Fg
  Fs  <- if (ks == 1L) 1 else Fg[ks]           # flux-continuous at the splice
  Fm[ks:nl] <- Fs * (zi[ks:nl] / zi[ks])^(-MS_MARTIN_B)
  s2 <- c(0, cumsum(Fm * dzm / K))
  s2 / s2[length(s2)]
}
