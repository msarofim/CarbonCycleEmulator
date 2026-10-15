# Handoff — CarbonCycleEmulator, 2026-08-25b: the ridge is settled; the OBJECTIVE is the question

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean.
**Nothing is running.** All four refit arms finished (8 h 53).
**Tests:** `test-pin-family.R` 42 pass, `test-joos-irf.R` 22 pass. The 2 pre-existing by-design
failures in `test-fluxes.R:99/100` are unchanged; the full suite was NOT re-run today.

**Supersedes** `handoff_2026-08-25_gcb_imbalance_programme.md` entirely — its G2/G3/G4 are retired.
**Read with** `notes/collect_2026-08-25_fert_ridge_refit.md` (the result) and
`notes/prereg_2026-08-25b_fert_ridge_refit.md` (what was promised beforehand).

---

## 0. STATE IN EIGHT LINES

1. **The GCB-imbalance program is CLOSED.** Not a century drift, and 0.43–1.5 σ from zero. §1.
2. **Gate 4's failure is a fertilization SATURATION-SHAPE problem.** Marcus's first-named lever
   (ocean stratification) is genuinely absent from the model **and cannot deliver the trend**. §2.
3. **The pre-registered 4-arm refit FALSIFIED P1**: the free arm returns `fert_k` to **554.98**.
   There is no second basin. §3.
4. **But two gates ARE fixed by saturation and survive the refit** — gate 4 (+0.0138 vs a +0.0148
   target) and **gate 12 at all three horizons**, where the reference fails all three. §3.
5. **Two things break in exchange**: the GCB land sink (+2.12 → +2.97 σ) and the AF *level*. §3.
6. **`rep_dC` does NOT fall.** The frozen scan said 0.150; it lands at 4.734. §3.
7. **So the open question is the OBJECTIVE's weighting**, not a parameter. §4.
8. **Gate 12b (a 300-yr tail test) was added today** and is the first gate that rejects a
   single-exponential carbon cycle. §5.

## 1. What closed (do not reopen)

**G1, the GCB budget imbalance** (`notes/diag_2026-08-25_g1_gcb_seam.md`). The 37.8 ppm "century
drift" is **0.43–1.5 σ** from zero once errors are correlated as a smoothed reconstruction's must
be, it is **not a century drift** (1850–1939 nets 16.6 GtC and changes sign twice; the 1940s+50s
carry **63 %** in 17 % of the years), and the only resolved seam is in **GCB's pre-1959 ocean sink**
(+0.23–0.28 GtC/yr, 3.2–5.3 σ). Growth is exonerated at 6 % **and the test is circular** — GCB's
pre-1959 growth is Joos & Spahni 2008, a reconstruction of the Law Dome record we already score.

**The `luc_arm_pin2` refit was STOPPED** at 1 h 25 (`calibration/output/luc_arm_pin2/README.md` says
so in its first line). It left the largest confound open: the `luc` arm traveled **along** the
fertilization ridge, and that ridge alone puts `rep_dC` at **7.220 (+6.80 σ)**. Consequence:
**08-24c's −5.014 σ headline is UNDERSTATED by ~2×**, not contaminated — the mechanism is worth
**−9.6 to −11.8 σ**. **`sigma_d14c`'s provenance question is still OPEN; an absent run is not a
result.**

## 2. Gate 4, and the lever that could not work

Marcus's mechanism inventory: five of six exist in the model. **Ocean stratification is genuinely
absent** — `R/model.R:846`, the interior flux is `p$kz * gradient` with `kz` **constant**, `w_up` = 0.
**But it cannot deliver the trend:** `kz` moves the AF *level* hard (0.490 at 2000 → 0.415 at 9000)
and its *trend* by **±0.0002 across that entire range**. Building it would have been the wrong lever.

The answer was traveling **along** the ρ = +0.997 (`beta_max`, `fert_k`) ridge at fixed present-day
enhancement — the one direction the historical CO₂ integral cannot identify.

## 3. The refit, collected against its pre-registration

**P1 FALSIFIED.** `ridge_free_from90`, seeded at K = 90 (warm start −3412), climbed back to
`fert_k` **554.98** vs the mode's 554.54, logpost **−1859.32** identical to two decimals, `rep_dC`
restored to 5.566. **No second basin.**

**P2 FALSIFIED, and the mechanism matters.** **Pinning one coordinate of a ρ = +0.997 pair does not
hold the pair.** Every arm was seeded *on* the ridge (enh(420) = 0.2074) and moved *off* it —
0.2614 / 0.2873 / 0.3387 — restoring the CO₂-level fit and `rep_dC` with it (4.967 / 4.734 / 4.138
against the frozen scan's 1.370 / 0.150 / −1.750).

**P4 HOLDS and gate 12 holds too** — both measured at the landed modes, both refit-proof:

| | trend | dec sd | r | land σ | TH20/50/100 | 12b tail |
|---|---|---|---|---|---|---|
| reference | −0.0007 | 0.019 | −0.06 | +2.12 | 11.69/23.81/39.06 ✗✗✗ | 0.707 ✓ |
| pin120 | +0.0107 | 0.030 | +0.48 | +2.62 | 12.28/25.35/41.79 ✓✓✓ | 0.713 ✓ |
| **pin90** | **+0.0138** | 0.036 | +0.52 | **+2.97** | **12.38/25.61/42.20 ✓✓✓** | 0.718 ✓ |
| pin60 | +0.0184 | 0.044 | +0.55 | **+3.72** | 12.50/25.89/42.58 ✓✓✓ | 0.730 ✓ |
| target | +0.0148 | 0.048 | — | 0 | ≥12.2/24.0/39.5 | [0.593, 0.979] |

**P5 NOT SUPPORTED:** `q10` 1.091 → 1.100.

**RETRACTED TODAY:** the morning's "four problems, one direction". Corrected in `CHANGELOG.md`
2026-08-25d and behind a ⛔ block at the top of memory `fert_shape_is_the_common_cause`.

## 4. ⇒ THE INHERITED QUESTION IS THE OBJECTIVE'S WEIGHTING

The model is pulled two ways **by its own likelihood**:

- **strong saturation** ⇒ gate 4's AF variability, gate 12's pulse response, and a FACE response in
  the mature-forest range (3.8–6.8 %);
- **weak saturation** ⇒ the CO₂ station levels and the GCB land sink.

It chooses weak, by **86.7 log-units** at pin90 — and the frozen stream decomposition showed **93 %
of that cost lives in `co2_level_MLO` + `co2_level_SPO`**, the two streams whose absolute level is
absorbed by **`rep_dC`, a nuisance offset sitting at 5.6 prior σ**.

**So the question is not where on the ridge the model sits — that is answered, 555. It is whether
two station-level streams, fitted through a 5.6 σ nuisance offset, should outvote the pulse response
and the airborne-fraction record by two orders of magnitude.** That is a **methodological choice
about the objective** and belongs to Marcus, not to a refit.

Concrete things that would inform it, none run:
- **Price the station-level streams' effective n.** They are annual levels at two stations over ~66
  years, strongly autocorrelated, scored as independent. The ice term already took an
  effective-n correction ([[ccx_d13c_neff]], 12.7 σ → 5.1 σ); **the station levels never have.**
  This is the single highest-value unrun diagnostic.
- **Re-examine `rep_dC`'s role.** If the level is being fitted by an offset anyway, ask what the
  streams are actually contributing beyond shape.
- **Gate 7's own weight.** `LIK_GCB_LAND_SD` = 0.5 with `LIK_LAND_SINK_INFLATE`; the land sink is
  the other stream resisting saturation.

## 5. Gate 12b — new today, and it changes what gate 12 can do

`R/joos_irf.R` + `calibration/diag_joos_irf.R` §3b + `DESIGN.md` §6 + `tests/testthat/test-joos-irf.R`.

**Why:** the TH 20/50/100 integrated test **cannot discriminate structure** — both published
single-exponential carbon cycles (Spencer 2023: 2.05 %/yr over 295 ppm; Dengler & Reid 2023: 42-yr
half-life) **pass it at all three horizons** while our model failed all three.

**The statistic is `IRF(300)/IRF(100)`, and its null is exact:** for any single exponential,
whatever τ, it equals `IRF(100)²`. Parameter-free. Joos 0.787 (own null 0.167); our model 0.707
(own null 0.075); the two one-box models sit **on** their nulls, 16–36× below the floor. The band
[0.593, 0.979] is **CONSTRUCTED** (Table 4's TH-100 relative width borrowed) and labeled so
everywhere; the discrimination does not rest on it. **12b is not a superset of 12a** — a τ = 10⁴ yr
exponential passes 12b and is rejected by 12a — and a test pins the pair.

## 6. Also landed today (not part of the ridge arc)

- **`CCX_PIN_PARAMS` is family-general.** It was hardcoded lognormal, so `fert_k` and `beta_max`
  (both `tr = "logit"`) could not be pinned at all. One expression now covers all three families:
  `prior(x) = dnorm(u(x), u0, PIN_SD) − log_jac(u(x))`, which sums with the Jacobian to a plain
  normal in `u`. **Reproduces the old lognormal to 7.1e-15**, so every earlier pinned run still
  reproduces. Sharpness gate derives from the transform, not the value.
- **The CO₂-lifetime literature sweep**, `notes/lit_2026-08-25_co2_lifetime_confusion.md` (4 parts)
  and **Marcus's 2011 Essenhigh comment**, now in-repo at `app/www/sarofim_essenhigh_comment_2011.doc`
  with a transcription at `notes/lit_2011_sarofim_essenhigh_comment.md`. Five corrections were made
  to the `.doc` on Marcus's instruction, all pre-2011 information (latest year cited: 2010).
- **The tool is being renamed `CarboTope`** (Marcus leaning). Only collision is an apparently
  unmaintained glycobiology web server; nothing on CRAN/PyPI/GitHub. The `ccx_` prefix need not
  change — public name and internal prefix can differ.

## 7. NON-OBVIOUS STATE — read before touching anything

- **`grep` SILENTLY SKIPS `textutil` OUTPUT.** Its HTML contains NUL bytes, so `file` calls it
  "data" and plain `grep -o` prints **nothing**. **Use `grep -a`.** I reported "0 superscripts"
  three times from this and it was wrong every time.
- **Pinned arms' logposts are NOT comparable to free ones.** The pin swaps `fert_k`'s
  `dunif(20,2000)` prior for a near-delta, worth **+11.33 to +12.21**. Subtract before comparing.
  Laplace evidence is not comparable at all.
- **The seed-copy trap, with a twist.** The four `ridge_*` dirs were seeded with **modified** mode
  files (at their own ridge cell) and `logpost = NA_real_` on purpose, so a seed can never be
  misread as a fit. All four now hold **real** fits. `calibration/seed_fert_ridge_arms.R` rebuilds
  them.
- **`luc_scale` was left FREE in these arms**, deliberately and after a corrected first launch — it
  is a constant multiplier on E_LUC and cannot create an AF *trend*, so it is not an escape route
  for gate 4. Recorded in the prereg.
- **Frozen-vector costs are upper bounds and this session proved how badly.** The refit recovered
  **15–19×** more than the frozen scan predicted. Never read a frozen conditional optimum as a
  prediction of where a refit lands.
- Everything in 08-25's §8, 24b §9, 23c §6, 23b §5 and 24a §7 still applies.

## 8. OPEN FOR MARCUS

1. **§4's objective-weighting question** — the real one, and it is his.
2. **The station-level effective-n diagnostic** — highest-value unrun item, and it feeds (1).
3. **Whether to keep the pinned arms at all.** They are scientifically informative and the posterior
   rejects them; they are currently at `calibration/output/ridge_*` and are **SCRATCH**.
4. **The FACE choice** (from 08-25 §7) is unchanged: option (b) was withdrawn, so it is
   report-only plus the shape/limit facts.
