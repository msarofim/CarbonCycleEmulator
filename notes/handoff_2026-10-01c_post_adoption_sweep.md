# Handoff 2026-10-01 (c): the post-adoption sweep. Two What-if switches fixed, the pulse box a NAMED RED, the review list written. Next: Marcus's rulings, then the app copy (D1), ribbons and the assessment

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use
> a bare `cd` in a Bash call; use `git -C` or absolute paths.
>
> **Read first:**
> 1. this file;
> 2. ⭐ **`notes/review_2026-10-01c_open_decisions.md`: THE list for Marcus.** §0 is what this session
>    changed; §A is app text now false at hilda33d; §B the rulings, each with options and a recommendation;
>    §C the 13 older unruled items;
> 3. CHANGELOG **2026-10-01 (g)** (this session). (f) and the unmerged branch's (h) are other sessions'
>    provenance work (§4);
> 4. memory: `ccx_hilda33d_adopted.md` (its "Post-adoption sweep" section),
>    `switch_test_at_defaults_has_no_power.md` (new), `ccx_pulse_spline_ringing.md` (the flip that missed
>    its refit);
> 5. the previous handoff, `notes/handoff_2026-10-01b_hilda33d_adopted.md`. Its §2 items are re-listed in
>    the review note as B1–B4, still unruled.

---

## 1. Where things stand

- **The canonical is still `hilda33d`** (objective #14). Nothing about the fit changed this session.
- **Main is pushed** at this handoff's commit, on top of `aa35024`.
- **Fixed (`4fd433d`): two What-if switches were incomplete at hilda33d.** Their tests ran at defaults,
  where both D2 paths are 0.
  - "Warming's effect on the carbon cycle" now also zeroes `npp_tsens`. It had removed −5.26 of
    −6.78 ppm (2024).
  - "Our emissions" now also zeroes `ndep_NH` / `ndep_SH`. "Nature alone" read 277.0 ppm, not 282.3.
  - New tests in `tests/testthat/test-mechanisms.R`: under each switch, the canonical is BLIND to its
    driver (exactly 0 change under a +1 K climate record, or with every human carbon input doubled).
    Each test carries a column inventory. Mutation-tested.
  - Verified in the app: warming off 418, emissions off 282, fertilisation off 483 ppm, against 425.
  - **Full suite at `4fd433d`: 5482 passed, 0 failed, 0 errors, 5 skipped**
    (`outputs/diagnostics/suite_20261001_post4fd433d_all.log`).
- ⛔ **NAMED RED: `test-pulse-linearity.R`, 5 failures.** It fails on every tree that contains
  `outputs/diagnostics/pulse_vs_tcre_20261001.csv`, i.e. `aa35024` onward. This is DELIBERATE.
  - The box's constants (`app/global.R:839–847`: `APP_PULSE_LIN_SPREAD` 4.2,
    `APP_PULSE_PER1000_BY_HORIZON` 1.43 / 1.20 / 1.03 / 0.97, `APP_PULSE_LIN_SRC`) are hilda29l's.
  - hilda33d measures 1.44 / 1.38 / 1.36 / 1.41 at +20 / 50 / 100 / 200 yr, with a 2.5 % size spread.
  - The test's direction assertion ("falls with horizon") and the box's sentence ("NOT flat in when you
    look", `app/server.R:905–924`) are now FALSE.
  - ⛔ **Do not re-pin until Marcus has written the sentence (review A2).** Then change the sentence, the
    constants, the source date and the direction assertion TOGETHER.
- **`diag_pulse_vs_tcre.R`** stamps its mode and commit in the log and CSV. Its anchor is now 1.36, read
  off the running app on 10-01; the driver computes 1.359, so the anchor passes.
- **Measured for B7** (ribbons):
  - one draw (spin-up plus the seven vV futures to 2150) costs ≤ 2.8 s;
  - one log-posterior evaluation costs about 0.2 s at fresh parameters (0.83 s on the first call);
  - the canonical's stored logpost reproduces exactly (−1405.249036).

## 2. Decisions for Marcus (NOT ruled)

All are in the review note with options and numbers. Recommendations in brief:

| # | item | my recommendation |
|---|---|---|
| §A | app text now false: card 6 backwards (caption "ΔAIC −33.07 in the simpler version's favour"); the pulse box; four "fertilisation is the only land sink" sentences; card 4 (`w_enso_l2` 11.91 ± 1.81 vs Meinen [14, 25]); card 5 (ocean 60 vs 59 %); "two-pool land"; drivers without N deposition | his wording. Card 6: retire or rewrite. |
| B1 | D2 choice 4: does the NPP readout include the retention flux? | exclude (67.67, z +1.50) and quote +0.50 GtC/yr beside D4 |
| B2 | the version label `v1.0-hilda29l` while the app runs hilda33d (no test pins it) | a new release name (his) plus a label-vs-loaded-mode test |
| B3 | the AIC gate's row set under mixed objectives | drop the two moved GCB rows when the arms' D3 gates differ; card 6's live ΔAIC uses the same rule |
| B3b | `CCX_MODE_PINNED_PARENT` is hilda29l's free parent; hilda33d has none | re-document it now; a #14 free-parent wave only if he wants the pins re-priced |
| B4 | the drafted labels for the four gated names | `ndep_ret`'s "stored" reads as NET, but 10.19 is GROSS (net 7.0) |
| B5 | the fertilisation switch: behaviour or words? | change the words; it stays CO₂ fertilisation only |
| B6 | the emissions-interpolation flip (`35f38dc`, "option 1") MISSED the #14 refit | put it on the next refit's launch checklist, or flip and restamp now |
| B7 | posterior ribbons | Laplace, 1000 draws, 5–95 %, vV futures first; MCMC later as the check |
| B8 | the new assessment record | ask whether to draft the evidence before or after B1–B3 |
| §C | 13 older items: deploy checklist, R2, σ-audit, `ra_ratio`, q10 split, P1 wording, scenario descriptors, `f_luc_wood` / `kz_deep_frac`, the sink→source caveat, the `INDEX_ccx_phi` CLAUDE.md listing, two 09-24 questions, three unratified edits | — |

## 3. Next steps (after the rulings)

1. **The app copy (D1 + §A), in Marcus's words.** Then:
   - card 6: retire, or rewrite with the B3 row rule applied to its live ΔAIC (`app/R/review.R:391–400`);
     the caption verdict (`app/R/plots_review.R:340`) must follow the sign;
   - the pulse box: the sentence, then re-pin the constants and the test (§1);
   - the drivers list and table (`app/server.R:79–80`, `1208–1221`) gain N deposition (`data/forcing_ndep.rds`,
     the vV-harmonised NOx + NH₃ emissions proxy);
   - the version label plus its test (B2), and DEPLOY.md lines 36, 87 and 101.
2. **B3 / B3b in code:** the row-set rule in `tests/testthat/test-mode-file.R:306–330`, and the stale
   red-#1 / red-#2 comment blocks there.
3. **B6:** flip `CCX_EMIS_METHOD_DEFAULT` and restamp, or put it on the refit launch checklist.
4. **B7, ribbons:**
   - a driver that draws, runs and stores quantiles in `data/`, with the SEED recorded in the artifact
     (global rule), and run twice for byte-identity;
   - the app reads the quantiles; it never runs draws live.
5. **B8:** the assessment / freeze record, on the 09-21 template.
6. **Not re-verified (from the audit; review A9):**
   - verdict phrases printed regardless of the computed value: `app/R/plots_review.R:168–169`, `:202–203`
     and `:235`, and `app/server.R:178–183`;
   - the imbalance panel's framing;
   - the AOD label in anomaly mode;
   - the box diagram's N-retention arrow.

   Check each before editing.

## 4. State

- **Running:** only the app preview (`ccx-app`, port 7788). It was restarted this session on the
  `4fd433d` code, so it has the switch fixes. It can be stopped.
- **Other sessions:**
  - **`claude/youthful-blackburn-fbc009` is NOT merged.**
    - What it does: one `ccx_git_stamp()` (`R/provenance.R`) for 71 drivers, with a test and a lint.
    - It claims **CHANGELOG 10-01 (h)**, so this handoff's entry is **(i)** to keep the letters unique.
    - It has already merged main through `aa35024`, and replaced `diag_pulse_vs_tcre.R`'s inline stamp
      with `ccx_git_stamp()`.
    - Its reported clean suite is at `45ccd21`, before that merge. After it, expect the named red there too.
  - `claude/compassionate-leavitt-a7e631` is merged (`4be643b`); its worktree remains.
- **Disposable:** `~/ccx_frozen/suite_20261001f`, this session's frozen suite copy (its log is in
  `outputs/diagnostics/`). `suite_20261001g` belongs to the other session.
- **Branch `emissions-interp-constant` (`35f38dc`) still exists, unmerged** (B6).
- `carbotopecomment.9.26.26.docx` is Marcus's; leave it. `outputs/diagnostics/smoke/` stays untracked by
  convention.
- ⚠ The root `MEMORY.md` is still over its 12 KB soft budget. That is pre-existing and was not touched
  this session.
