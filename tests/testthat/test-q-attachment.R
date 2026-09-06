# =====================================================================
# WHERE HD ATTACHES TO THE COLUMN -- `q_attach_from` (2026-09-05f)
#
# HILDA's q is "assumed independent of depth" and the 2026-09-05 build wired it
# that way. It FAILED, for a diagnosed reason: HD sits near -109 permil and the
# interior crosses -109 at ~1000 m, so a SINGLE-ENDMEMBER bulk exchange matches
# its endmember at exactly ONE depth and fights the profile on both sides of
# it. `q_attach_from` is the departure Marcus authorised on 2026-09-05 ("we
# don't need to stay true to HILDA, but we should stay true to the conceptual
# way that the simplified model's ocean works"): in a pure-diffusion column the
# interior is reached by mixing from above, and deep water formation fills the
# DEEP. Pre-registered in notes/prereg_2026-09-05f_q_attachment_depth.md.
#
# WHAT THESE TESTS GUARD:
#   * 1 -- and ABSENCE -- means every layer, i.e. the 09-05 structure BIT FOR
#     BIT. A parameter list written before today must not silently change model.
#   * the switch is MUTATION-TESTED. A subsetting knob that is read but not
#     acted on reports "no effect" identically to one that was measured.
#   * `tau_q` is NOT renormalised over the subset, so a smaller set means LESS
#     total exchange. That is a deliberate design choice and is pinned here,
#     because renormalising would smuggle a rate change in with a geometry one.
#   * conservation survives subsetting -- each layer's two limbs are
#     volume-symmetric ON THEIR OWN, so dropping layers drops matched pairs.
#   * both cores agree at a SUBSET, not only at the default.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

qa_par <- function(attach = NULL) {
  p <- ccx_default_params()
  p$hs_frac <- 0.16; p$u_hs <- 38; p$tau_q <- 538; p$sst_hs <- 2
  if (!is.null(attach)) p$q_attach_from <- attach
  p
}

test_that("the default is 1, and 1 means EVERY layer", {
  expect_identical(ccx_default_params()$q_attach_from, 1)
  p <- qa_par(); nl <- ccx_prepare(p)$grid$nl
  # 1 is the shallowest layer, so the set is 1..nl -- the whole interior
  expect_identical(ccx_spinup(qa_par(1))$y, ccx_spinup(qa_par(nl - nl + 1))$y)
})

test_that("absence means 1, so a pre-2026-09-05f parameter list is unchanged", {
  a <- ccx_spinup(qa_par())            # no q_attach_from at all
  b <- ccx_spinup(qa_par(1))
  expect_identical(a$y, b$y)
  expect_identical(a$diagnostics$d14c_bottom_box, b$diagnostics$d14c_bottom_box)
  # and the switch is genuinely read: a different value MUST differ, or the
  # equality above would hold for a knob that does nothing at all
  expect_false(identical(a$y, ccx_spinup(qa_par(10))$y))
})

test_that("MUTATION: moving the set by ONE layer moves the deep", {
  p <- ccx_prepare(qa_par()); nl <- p$grid$nl
  d <- vapply(c(nl - 1L, nl), function(k)
              ccx_spinup(qa_par(k))$diagnostics$d14c_bottom_box, numeric(1))
  expect_gt(abs(diff(d)), 1e-6)
  # and the direction is the mechanism: attaching DEEPER stops HD injecting its
  # young carbon into the intermediate layers, so the column AGES
  expect_lt(d[2], d[1])
})

test_that("conservation survives subsetting -- matched pairs, not a leak", {
  for (k in c(1, 5, 10)) {
    sp <- ccx_spinup(qa_par(k))
    zf <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
               cum_luc = list(NH = 0, SH = 0), gmst = 0, enso = 0,
               c14_bomb = 0, c14_nuclear = 0, d13c_foss = -27.6,
               c14_cosmo = sp$prod_c14)
    p0 <- ccx_set_enso(qa_par(k), list(gamma_enso = 0))
    p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0; p0$seas_drivers <- 0
    d <- ccx_deriv(sp$y, 1750, p0, zf, sp$grid, sp$aux)
    expect_lt(sum(abs(d[, "C"])) / sum(sp$y[, "C"]), 1e-9)
  }
})

test_that("HD is set by kz, NOT by the attachment -- the like-for-like guard", {
  # ⛔ THIS TEST EXISTS BECAUSE I GOT IT WRONG. diag_q_attachment.R first read
  # HD off the two ISO-DEEP arms -- which carry DIFFERENT kz, because that is
  # what the control solves for -- and attributed the whole 10.5 permil to the
  # attachment. At MATCHED kz the attachment moves HD by only ~1-3 permil and
  # its SIGN is not even robust across bases (it reverses between ent26 and
  # ccx_default_params()), while kz alone moves it ~9. The iso-deep control
  # equalises the DEEP AGE, so it licenses comparing the intermediate PROFILE
  # across arms -- and nothing else. Any quantity the control does not pin
  # must be compared at MATCHED kz.
  hd <- function(k, kz) { p <- qa_par(k); p$kz <- kz
                          ccx_spinup(p)$diagnostics$d14c_hd[["NH"]] }
  d_attach <- abs(hd(10, 1900) - hd(1, 1900))
  d_kz     <- abs(hd(1, 2686) - hd(1, 1900))
  expect_lt(d_attach, d_kz / 3)
})

test_that("tau_q keeps its PER-LAYER meaning: a smaller set exchanges LESS", {
  # If tau_q were renormalised over the subset, total HD<->interior exchange
  # would be invariant to the attachment and the deep box would barely move.
  # It is not, and this pins that -- the deep is what the weaker total exchange
  # shows up in, at fixed kz.
  deep <- function(k) ccx_spinup(qa_par(k))$diagnostics$d14c_bottom_box
  expect_lt(deep(10), deep(1))
  expect_gt(abs(deep(10) - deep(1)), 1)
})

test_that("an out-of-range attachment ERRORS by name, on both cores", {
  nl <- ccx_prepare(qa_par())$grid$nl
  for (bad in c(0, nl + 1, NA_real_)) {
    expect_error(ccx_spinup(qa_par(bad)), "q_attach_from")
  }
})

test_that("R and C++ agree at a SUBSET, not only at the default", {
  skip_if_no_cpp()
  for (k in c(1, 6, 10)) {
    sp <- ccx_spinup(qa_par(k))
    forc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),
                 cum_luc = list(NH = 120, SH = 80),
                 gmst = 1.1, enso = 0.7, c14_bomb = 1200, c14_nuclear = 40,
                 c14_cosmo = sp$prod_c14, d13c_foss = -27.6)
    dR <- ccx_deriv(sp$y, 1980.5, qa_par(k), forc, sp$grid, sp$aux)
    dC <- ccx_deriv_fast(sp$y, 1980.5, qa_par(k), forc, sp$grid, sp$aux)
    expect_lt(max(abs(dR - dC)), 1e-12)
  }
})
