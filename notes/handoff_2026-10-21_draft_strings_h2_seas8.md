# HANDOFF 2026-10-21 (4): ENSO full year; the draft-string pass; H2 and the seasonal-tracer tests at hilda31w (nothing deployed)

**Supersedes** `notes/handoff_2026-10-21_scan_items_built.md`. Written on Marcus's request ("Write the handoff note"),
2026-10-21.

- **Start here:** CHANGELOG **2026-10-21 (o)–(u)**; this note's §3 item 1.
  Memory: `ccx_h2_tested_and_priced` (its 10-21 section), `ccx_seas8_tracer_conflict_hilda31w` (new), and their lines in
  `INDEX_ccx_ocean.md` / `INDEX_ccx_seas.md`.
- **main = the commit that adds this note, pushed.** The last app-facing commit is `fd6d09c3`; everything after it is
  diagnostics, outputs, CHANGELOG and notes. No branches, no worktrees (all four frozen ones removed), no servers.
- **Live app = revision `01a15f80` from `6cf56879`** (unchanged today). Every app change below is committed and NOT
  deployed.

## 1. What was done

| | commits | outcome |
|---|---|---|
| full suite @ `3d2dc9fb` (code = `42899ee8`) | `9c9ada24` | 9,169 passed, 0 failed, 1 skipped (standing `l2-enso-limb`), 233 warnings, 21.6 min; linked (81). README test line cites it. (p) |
| ENSO Covers | `605365d9` | Drivers table: 1948–2025, the last year with all twelve Niño 3.4 months (record ends July 2026); `app_full_years()`; test pins it + mutation (fails 2 when reverted). "list" kept. (o) |
| draft-string pass | `f7c42da8`, `fd6d09c3` | A subagent audited every draft marker against recorded rulings (CSV chart names were already approved 10-20 h). Marcus approved 1–3, 5–7, 11, 12; gave his wording for 4 (`PULSE_TAG_DECAY_NOTE`) and 8 (the seasonal paragraph, `server.R` ~1220); held 9 and 10. App-facing tests 2,469 / 0 at `fd6d09c3`. **The full suite was NOT rerun after `605365d9`.** (q) |
| H2 tests | `84295883`, `d951b44a` | Both had `hilda31w` results from 10-13 (I first said they had not). Rerun on today's code: identical. The climate effect's share of the CO₂ effect stays −13.4 to −14.0 % over `kz` ×½–×2 (GCB −7.1 %, models −4.2 to −10.7): mixing is not the share's cause. No-warming gap −0.062 ± 0.044 (matched MC, p 0.16). Per-K ratio 1.8 ± 0.5. New `calibration/diag_h2_intercept_ar1.R`. (r) |
| item 8's tests | `06eff707` | Subagent, six `diag_seas8_*` drivers. The CO₂ and δ¹³C seasonal cycles conflict; δ¹³C rows lose 18.7 in the joint fit (CO₂ 3.8), at MLO, where the cycle is nearly all land. MLO δ¹³C/ppm 0.89× [0.86, 0.93]. SPO land/ocean split inside the observed intervals; limbs add. Ocean channels: SST +0.006 ‰/ppm (opposite sign to land), SPO ocean limb −0.0205 (half the land's). (s) |
| ε test | `7c32d7c8`, `35bdd5aa` | ε held at 18.35 (MLO signature then matches): the δ¹³C loss stays 17.2, so ε is not the cause; the cause is TIMING. Observed MLO δ¹³C leads CO₂'s antiphase by 0.144 mo; the model gives +0.01 to +0.10 in every fit. Total logpost +9.0 at 18.35 after the block refit; SPO signature worsens to 1.35×. (t) |
| lint | `06eff707` | `test-git-stamp-lint.R` was red from `84295883` (`diag_h2_intercept_ar1.R` called git directly); fixed with `ccx_git_stamp()`, outputs regenerated on a clean tree. |

## 2. Decisions (Marcus, verbatim)

- ""list" is fine; end ENSO at the last full year"
- "Approve 1-3. 4: "Most of the tagged atoms leave the atmosphere within a couple of decades, because carbon in the air
  exchanges with the land and ocean every year. The increase in CO2 concentration lasts for longer, because carbonate
  chemistry limits how much extra carbon the ocean can take up." Approve 5-7. For 8: I note that if in reality the
  seasonal cycle is made up of those two opposing cyclical responses, then there must be a way that they can work
  together. In any case, I would simplify to, "A likely reason they disagree: the model's seasonal cycle is the sum of
  land plants which have a strong 13C fingerprint, and the surface ocean without a fingerprint. The two tracers respond
  differently to the seasonal pattern, and the fit splits the difference." Approve 11 & 12. Explain 9 & 10 more
  thoroughly." (His "CO2"/"13C" set as CO₂/¹³C, flagged.)
- "Run the two H2 tests at hilda31w first, as well as the tests for 8. "Response" instead of "structural" is fine."
  (The CLASS is approved; the gloss's wording is still open.)
- "Run the ε test first"
- **Not asked:** whether to redeploy anything after `6cf56879`.

## 3. Open items

1. **Three wording calls for Marcus**, all on screen now, each with the test result that bears on it:
   - **8**, What pins down what? (`app/server.R` ~1220, his text): "splits the difference" is supported; the cause is a
     timing offset inside the land-driven cycle at MLO, not the land/ocean sum; "the surface ocean without a fingerprint"
     is right in size, wrong in sign for the SST channels and at SPO. The draft said "almost no"; asked, not answered.
   - **9**, the `response` gloss (`app/R/review.R` ~62–64): "the process is in the model, but it reacts by the wrong
     amount, and refitting the same model does not fix it." The last clause is consistent with H2 test 1 but rests on
     one-name perturbations, not a refit.
   - **10**, card 8's detail (`app/R/review.R` ~899–905): "Our leading explanation is that this model's ocean mixes
     vertically so strongly …" is not supported by H2's discriminating test; his following sentence "Mixing less would
     help this issue at the cost of …" holds in GtC/yr, not in the share. Title ("about twice") still holds.
2. **Then the redeploy path, unchanged from the last handoff:** full suite at the commit that settles item 1 (copy
   `~/ccx_frozen/suite_20261021_3d2dc9fb.sh`, change the commit in its three places, `git worktree add --detach`, link
   `data-raw/downloads` per file, run in the background); bundle `app/make_deploy_bundle.sh <dir> <commit>`; ask Marcus;
   hand him `Rscript -e 'rsconnect::deployApp("<dir>", appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account =
   "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)'`; live checks (revision via
   `rsconnect:::clientForAccount(...)$getContent(<id>)$current_revision`, every tab at 1440 × 900,
   `outputs/diagnostics/scan_items_20261021/check_scan_ui.py` against `https://carbotope.org/`, the ENSO Covers year, the
   Under the hood takeaway). The precomputes do not need a rebuild (no stored label changed).
3. **Science follow-ups, Marcus's call, not app blockers:** a seasonally varying ε, or separate photosynthesis /
   respiration signatures, for the 0.144-mo lead (both need R + C++ core changes and a refit); a refit with ε at the C3
   value (+9.0 logpost unrefitted elsewhere); the share's cause in card 8 (untested candidates); the joint fit's
   `sst_seas_amp_NH` strain (z −1.84 at 16.2, −3.39 at 18.35, while both solo fits raise it); the model's MLO CO₂
   amplitude trend +0.024 /yr against +0.009 observed.
4. **Carried over:** f_plot's alt text is "Futures" in all three modes; capacity (raise memory to 2–4 GB before a live
   class); cold start ~8 s; the marketing list; post 1 stays the feedback channel; iOS Safari needs a simulator runtime
   (ask first); rebuild the precomputes at each adoption or stored-label change.

## 4. Non-obvious state

- **The deploy is Marcus's to run** (the auto-mode classifier refuses `deployApp()`); memory `ccx_connect_cloud_deploy`.
- **Loading the app overwrites a global `f`.** It bit again today: the app-facing runner's loop variable was `f`, so it
  reported 39 files / 1,909 instead of 42 / 2,469, with 0 failures either way. Use another name (`.af_file`).
- **Before saying a diagnostic was not run at the canonical, `ls outputs/diagnostics | grep hilda31w`.** I quoted the
  previous canonical's CHANGELOG entry as if it were current.
- `hilda31w` is not registered by name in `CCX_MODE_FILES`; `diag_ocean_climate_gobm.R` takes
  `CCX_OC_MODE="hilda31w=calibration/output/refit_20261013_hilda31w_wtc_hilda_csl3v0kaidgbemwtc/mode_fit_pumpN.rds"`.
- **seas8 drivers:** `CCX_SEAS8_OUT`, `CCX_SEAS8_SCREEN_DIR`, `CCX_SEAS8_EPS`. The "seasonal rows + priors only"
  design does NOT reproduce the mode (2.00 sd); use design B (every row minus the other tracer's seasonal rows). Under
  `CCX_SEAS8_EPS` the joint-fit gate is self-agreement from three starts. The ε run's launch script is in
  `outputs/diagnostics/seas8_20261021_hilda31w/eps18p35/logs/`.
- **New calibration drivers must call `ccx_git_stamp()`**, never `git` directly (`test-git-stamp-lint.R`).
- The session's safety check refuses `rm -f $VAR/…`; use a fresh directory or `"${VAR:?}"/…`.
- Launch scripts kept: `~/ccx_frozen/suite_20261021_3d2dc9fb.sh`, `~/ccx_frozen/h2_20261021_fd6d09c3.sh`.
- Scratchpad only (lost with the session): the fixed app-facing runner and its list (42 files: every test that greps for
  `file.path(.root, "app")`, `app/R/`, `app/global.R`, `shinyAppDir` or `"app"`).
