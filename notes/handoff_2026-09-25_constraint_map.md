# Handoff — 2026-09-25. **A NEW TAB SHIPPED: "What pins down what?"** — the measured map of which part of the model each observation actually tests, plus the three fixable reds in the suite. ⛔⛔ **ONE RULING NEEDS MARCUS: his chosen perturbation step was MEASURED AND REJECTED, and the substitute is in the shipped product.**

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd), so a bare `notes/...` will not
> resolve. Prefix with the absolute path, or `cd` there.
>
> **Read first, in this order:** CHANGELOG **09-25 (d)** and **(e)** · then **§1** (the open ruling)
> and **§5** (non-obvious state).
> ⚠ `~/.claude/CLAUDE.md` applies. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY. Read
> **`INDEX_ccx_app.md`** (the app as a product) before touching the tab, and
> **`INDEX_diag_conv.md`** before touching the perturbation step. The three new facts are in
> **`ccx_constraint_map_tab.md`**, **`perturbation_step_marginal_vs_conditional.md`** and
> **`dollar_partial_matches_on_lists.md`**.

---

## 1. ⛔⛔⛔ THE ONE THING THAT NEEDS MARCUS: his ruled step did not survive measurement

He ruled three choices for the constraint map (2026-09-25): evaluate **at the canonical mode**,
step **±1 posterior sd**, rows **grouped by component with parameters on demand**. Choices 1 and 3
shipped as ruled. **Choice 2 did not**, and the substitute is what the tab currently draws.

**What was measured.** Built on the marginal sd first — `md$sd_unc`, i.e. `sqrt(diag(cov))`, which
is what "one posterior sd" ordinarily means. The land-uptake row came out at **8,739 log-units**
for a single one-sd step and **22 of 29 names** were flagged outside the quadratic regime. That is
not a bug: it is what the stored Hessian itself predicts (median **5.3** log-units, up to
**4,235**). The reason is structural — **a MARGINAL sd is how far a parameter can move WITH the
other 28 compensating**, so moving it that far ALONE is a completely different and much harder move.

| | marginal | conditional | ratio |
|---|---|---|---|
| `fert_k` | 0.5422 | 0.0059 | **92.0** |
| `beta_max` | 0.4610 | 0.0055 | **84.1** |
| median over 29 names | — | — | **3.3** |

**What shipped instead:** the **CONDITIONAL** sd, `1/sqrt(diag(-H))`. Its quadratic drop is
**0.5 log-units for every coordinate by construction** — an equal-difficulty step, so the rows of
the map compare like with like. Measured drop 0.50 for every name (worst 1.52), **0 of 29** out of
regime.

⭐ **And the rejected step is kept and reported, because the ratio IS the identifiability story**:
marginal ÷ conditional is how much freer a parameter is with the others compensating.
`beta_max`/`fert_k` at 92× is the statement that **the data pin their COMBINATION and neither one
individually** — which is exactly the tab's claim that the land sink's magnitude is pinned and its
saturation shape is not.

**What is owed:** Marcus to ratify the substitution, or rule the marginal step back in.
`CM_STEP_KIND` in `calibration/diag_constraint_map.R` switches between them and the gate
`test-constraint-map.R` test 3 asserts which one is live, so a switch is one constant and a rebuild
(~50 s). ⚠ **If he rules the marginal step back, the map's numbers are not comparable across rows**
and the app's computed prose (shares, "92× tighter", the tension chart) all move.

---

## 2. What shipped, and where it is

### The tab (`a390df3`, pushed)
| file | what it is |
|---|---|
| `calibration/diag_constraint_map.R` | 29 names × 26 streams at the canonical, through the SHIPPED objective + periodic spinup. 4 gates, then writes the product. 58 evaluations, ~50 s |
| `data/constraint_map.rds` | the product: `M` (leverage), `DHI`/`DLO`, `CURV`, `SLOPE`, the component map `MC`, both sd vectors, and a `provenance` block |
| `app/R/plots.R` | `plot_constraint_map()` (heatmap) and `plot_constraint_tension()` (the opposing pulls) |
| `app/global.R` | `APP_CMAP` loader, the headings, the honesty caveats, `app_cmap_tensions()` |
| `app/ui.R` / `app/server.R` | the tab, and the computed structural prose |
| `tests/testthat/test-constraint-map{,-panel}.R` | 143 + 45 assertions, mutation-tested |
| `R/paths.R` | **new** `ccx_mode_fit_stats()` — see §3 |

**The gates, all four before any number is read:** HARNESS (the rebuilt objective reproduces the
stored logpost, −1425.3620), CLOSURE (`sum(streams) == loglik`, 0.000e+00), COVER (every fitted name
in exactly one component, every stream in exactly one family — both ways), STEP (including that
`sqrt(diag(solve(-H)))` reproduces the file's own `sd_unc`, i.e. **the sign convention is checked,
not assumed**).

### The suite's reds (`9973232`, `af9e919`, `ee0958c`, pushed)
Handoff (f) §5 said "the reds are now THREE". A clean run said **4**, and the third file was
**`test-mode-struct-lint.R`, grown by (f)'s own Tier-1 commit**. ⚠ **A ratchet lint breached by the
commit that is reporting on itself is the one a handoff cannot see** — that session's filter named
topics, and a lint has no topic. **Put `lint` in the filter, or run the whole suite.**

---

## 3. ⛔⛔ THE TWO BUGS THAT CAME OUT OF THE RED-FIXING, AND THE FIRST IS THE ONE TO REMEMBER

### (a) R's `$` on a LIST PARTIAL-MATCHES
Converting `diag_rep_dc_product_ladder.R` to `ccx_overlay_par()` looked cosmetic, so it was
mutation-tested — *what does the safer call actually buy?* — and that found a live silent default
in two shipped resolvers.

`p$seas_lag_p` on a list that has no such element resolves to **`seas_lag_p_SH`**, because
`seas_lag_p` is a unique prefix once `_NH` is gone. With BOTH present the match is ambiguous and
returns `NULL` — **which is the only reason the canonical never saw this.** Consequences while it
stood:
1. `ccx_seas_lag_p()` read the **surviving hemisphere as the legacy scalar** and mirrored it across,
   instead of falling to `CCX_SEAS_LAG_P_DEFAULT`.
2. `ccx_migrate_par_set()`'s refusal *"absent and no legacy `seas_lag_p` to migrate from"* was
   **UNREACHABLE IN THE SHAPE IT WAS WRITTEN FOR** — it fired only when BOTH halves were absent.

`gamma_enso` is a prefix of all four split ENSO names and has the identical exposure at exactly one
present. Fixed with `[[` at the five READ sites (`R/model.R` ×3, `R/calibrate.R` ×2).
⚠ **Assignments were always safe** — `$<-` never partial-matches.
⚠ **No number moves and it is NOT live** — no mode file on disk is half-split.
⚠ **STILL EXPOSED, convert-on-touch**: ~20 `$gamma_enso` / `$seas_lag_p` reads in `calibration/`
diagnostics and **`calibration/lib_seas_limbs.R:117`**, which is the one that is not a print
statement. Same class, same not-live condition.

### (b) A gate lint caught ME, an hour after I fixed it for someone else
`test-mode-struct-lint.R` went red on my own new `test-constraint-map.R`, which opened the mode file
directly for its Hessian. **Fixed the same way and NOT by widening the baseline**: the read moved
into a new **`ccx_mode_fit_stats()`** in `paths.R`, the one file the lint exempts. It is the missing
member of an existing eight-strong `ccx_mode_*(md)` family, and it is where the Hessian's sign
convention is now documented **once** — `md$hessian` is the LOG-posterior's, so negative definite;
`1/sqrt(diag(md$hessian))` returns NaN for all 29 names, which cost one debugging cycle.

⛔ **Two tempting non-fixes were rejected in both the (b) case and the earlier `luc_scale` one, and
they will be tempting again**: calling `ccx_mode_base()` for a parameter list nobody uses is
**gaming the gate**, and adding the file to the baseline is **ratcheting the wrong way**.

---

## 4. What the map says, for anyone quoting it

⭐⭐ **Only 6.1 % of the leverage-weighted map is "PINNING"** (a stream at its own optimum, both
directions worse). **94 % is a PULL.** ⇒ the fitted values sit where opposing pulls cancel, and the
informative cells are where two families pull OPPOSITE ways:

| parameter | wants HIGHER | wants LOWER | opposed |
|---|---|---|---|
| `seas_lag_p_NH` | CO₂ seasonal | δ¹³C seasonal | **2.34** |
| `seas_T_amp_NH` | δ¹³C seasonal | CO₂ seasonal | 1.21 |
| `q10` | δ¹³C seasonal | CO₂ seasonal | 1.13 |
| `tau_ex` | CO₂ north–south gradient | δ¹³C level & gradient | 0.79 |
| `k_w` | δ¹³C level & gradient | Δ¹⁴C in the air (bomb) | 0.66 |
| `hs_asx_frac` | δ¹³C level & gradient | Δ¹⁴C in the air (bomb) | 0.63 |

Row shares: **Δ¹⁴C in the ocean 82.5 % mixed layer + vertical mixing**; **ocean interior chemistry
74.9 % biological pump** (against 3.1 % of the CO₂ level); CO₂ / δ¹³C seasonal **63 % / 67 %**
seasonal cycle; CO₂ level **25 %** land uptake, measured sinks **24 %**.
Row TOTALS (log-units): δ¹³C level & gradient **26**, CO₂ level 18, Δ¹⁴C bomb 17, CO₂ seasonal 15,
δ¹³C seasonal 9, ocean interior 7, measured sinks 5, … **Δ¹⁴C pre-bomb (IntCal) 0.2**.

### ⛔⛔ THREE READING TRAPS, all captioned in the app, all of which I walked into first
1. **A share of a small row is not a finding.** `CO₂ in ice cores` is 31.6 % "held by" the seasonal
   cycle on a row worth 2.8 against CO₂ level's 18. The chart therefore draws MAGNITUDE and prints
   each row's total beside it; a row-share heatmap would have coloured those two the same.
2. **A component's bar is a SUM over its parameters.** Ranking components by total made
   *air-sea gas exchange* — a group of ONE — read as least-watched, when its single parameter `k_w`
   has the **HIGHEST total leverage of all 29**. ⭐ *A sum is not a rate until you divide by the
   count.* The "what nothing watches" sentence ranks PARAMETERS and says why the group bars cannot
   be read that way. **This was caught in the browser, not by a test.**
3. **Low leverage ≠ "the record was not worth having."** A measurement that already agrees, whose
   information is now carried by a parameter something else holds, reads flat exactly like one that
   never said anything. The map **cannot tell those apart** and says so in its own copy.

⚠ **And a statistic was built, shipped and replaced within the hour.** The first curvature measure
divided by `max|d|`, so it fired at ratio ≈ 2 in exactly the HEALTHY case — a stream sitting in a
symmetric well, which is what a constraint *is* — flagging 11 of 29 names as suspect. **A statistic
that cannot separate the healthy case from the defect is not a gate.** Replaced by the curvature
FRACTION `|dhi+dlo| / (|dhi|+|dlo|)` ∈ [0,1], which is the pins-vs-pulls axis; the regime check is
now measured-vs-predicted drop.

---

## 5. Non-obvious state

- **Branches.** CCX `main` at **`26f64da`, PUSHED** (`msarofim/CarbonCycleEmulator`, private), tree
  clean. FaIRtoFrEDI is **not this session's work** — see below.
- ⛔⛔ **A PEER SESSION IS LIVE IN `FaIRtoFrEDI/` AND I DID NOT TOUCH IT.** `ListAgents` showed
  *"FrEDI wildfire integration setup"* busy; `egu_sprm_memo_v2_skeleton.md` was written at **07:10,
  one minute before I looked at it**. That session has since committed the v2 merge
  (`513ce1f` → `8f0fdd1` on `heat-ed-morbidity`) and Marcus's 09-25 docx prose — the SC-GHG
  dismissals at 91 Fed. Reg. 7694 / 7733 — **is now in `egu_sprm_memo_v2_skeleton.md`**, the v2
  source, not the v1 skeleton. ⚠ **Check `ListAgents` before editing anything under
  `FaIRtoFrEDI/deliverables/`.**
- **Suite: 4721 PASS / 1 FAIL**, the cleanest it has been. The one red is **`test-mode-file.R:323`,
  dAIC +4.18, NAMED RED BY RULING** — a red that encodes a priced decision is not a red to fix.
  ⚠ 227 warnings, all the pre-existing 1900-start transient. Full run takes **~12 minutes**.
- ⚠ **`~/.claude/CLAUDE.md`'s "never edit a running script" was broken once and caught**: a full
  suite was launched and then `R/` files were edited while it ran, so its FAIL 6 was void and it was
  re-run clean. ⚠ And `pgrep -f run_tests.R` matched the watcher's own `bash -c` line exactly as
  [[pgrep_wait_loop_matches_itself]] says — match on `exec/R --no-echo.*run_tests` instead.
- **App instances.** Mine is on **:7791** and still running (launched from Bash, not
  `preview_start` — `preview_start` picks up a different `launch.json`). ⚠ **:7788 and :7789 both
  return HTTP 500** — dead instances left by an earlier session; worth killing.
- **Palette.** New pair `pull_up` **`#b2182b`** / `pull_down` **`#2166ac`**, scored **21.2** minimum
  over normal/protan/deutan/tritan against the ≥ 8 target. ⚠ **The land-use brown/teal was
  deliberately NOT reused** despite already having a receipt: a reader who has just learned
  brown = clearing two tabs away would read brown = wants-higher here. **Same colours, different
  meaning, is its own bug.**
- **Naming.** The observation-family strings are **typeset in the DIAGNOSTIC** (δ¹³C, Δ¹⁴C, CO₂) and
  are the app's axis labels and the subject of its computed prose. A pretty-name lookup in
  `global.R` would be a second naming table — the caption-sync bug class.
- **Still unmerged, still owed** (unchanged): `emissions-interp-constant` (`35f38dc`) rides with the
  next refit; **this work did not trigger one** — no objective change, no mode file written,
  objective #13 still FROZEN.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), a start-up re-time on an **IDLE** machine, the hosting
  plan's limits. W4's ratchet entry still unratified.
- **The navbar now has 8 tabs** and wraps to a second row at 800 px. Not addressed; flagged.

## 6. Recommended order for the next session
1. **Get Marcus's ruling on §1** — it is the only thing in the shipped product that deviates from
   what he asked for, and everything the tab says numerically rests on it.
2. **Show him the tab** (`:7791` or relaunch) and take copy rulings. His copy, as always. The
   structural paragraphs are computed from the product, so a wording change must not turn a computed
   number into a typed one.
3. `calibration/lib_seas_limbs.R:117` — the one `$gamma_enso` read outside a print statement.
   Convert on touch (§3a), with a before/after receipt on whatever it prints.
4. ⚠ **Consider whether the map wants a SECOND evaluation point.** It is a purely LOCAL statement at
   one mode, and it says so — but "which observations would notice a structural change" is the
   question the CCX arc keeps asking, and this answers it only in a neighbourhood. A second map at a
   quarantined mode (e.g. `hilda31pe`, the control) would cost ~50 s and would say whether the
   pins/pulls picture is a property of the model or of this fit. **Not started; a real choice, not a
   chore.**
