# Handoff 2026-11-11: group B decision sheet, one row pending

Continues `notes/handoff_2026-11-11_group_b.md` (the plan). Read with `CLAUDE.md`, `~/.claude/CLAUDE.md` and the
sheet itself, `notes/decision_sheet_2026-11-11_group_b.md`. CHANGELOG 2026-11-11 (q).

## 1. What this session did

Marcus's three answers (from the previous handoff): wording is draft-only; design and science go to a decision sheet
first; nothing ships until he chooses. The sheet is written and committed (`0168444b`), with every item B1–B21 and B10.
It was sent to Marcus as a draft. **No app text or code has changed.** The app code is still the live `64d91397`
(`git diff 64d91397 HEAD -- app R data src` is empty).

Last commit: `6bade1d2`. Working tree clean apart from this note.

## 2. The one open item: card 7's `k_w` row (B20)

- **What is running:** the `k_w` = 1446 price profile at `hilda31fl`, the 10-13 recipe unchanged
  (`calibration/run_price_profile.R`, two starts in parallel, A = the canonical's mode, B = warm from
  `calibration/output/refit_20261005_kw1446_hilda_csl3v0kaidgbe/mode_fit_pumpN.rds`; 300 CPU-min budget each).
- **Where:** frozen worktree `~/ccx_frozen/20261111_kw1446_profile_hilda31fl` at `6c6cc9fd` (downloads linked per
  file, 79 + 3). Launch script `~/ccx_frozen/20261111_kw1446_profile_hilda31fl_launch.sh` (re-running it resumes from
  the checkpoints). Logs `~/ccx_frozen/20261111_kw1446_profile_hilda31fl_{A,B}.out`. R PIDs **87528 (A), 87529 (B)**;
  the pids file lists the same numbers. Outputs land in the worktree's
  `outputs/diagnostics/price_profile_20261111_hilda31fl/profile_k_w_{A,B}.rds`.
- **State at 17:05:** both passed the reproduction gate (canonical logpost −1050.120651, diff 0); after cycle 1's first
  Nelder–Mead pass A is at −1078.58, B at −1071.73 (31.5 CPU-min each). 10-13's run converged in 2 cycles at 133 and
  184 CPU-min, so expect it around 18:30–19:30. A background waiter in the old session watches the PIDs; a new session
  must check them itself (`kill -0 87528; kill -0 87529`, never a `pgrep -f` loop).
- **When it finishes:**
  1. Check both `.out` files end in "CONVERGED" and the two starts agree (10-13: 1.3e-6 in logpost). If they disagree
     by more than the 0.5 cycle tolerance, say so and do not quote a number.
  2. Copy the two `profile_k_w_{A,B}.rds` (and `_ckpt.rds`, the `.out` files and the launch script into `logs/`)
     byte-identical into the main repo's `outputs/diagnostics/price_profile_20261111_hilda31fl/`, as on 10-13.
  3. `Rscript calibration/diag_price_profile_read.R --dir=outputs/diagnostics/price_profile_20261111_hilda31fl`:
     likelihood by row and family, the prior ledger (does `hs_asx_frac` still carry most of the prior cost?), the
     posterior price. Its section 4 compares with the 10-05 read; put 10-13's numbers beside them by hand
     (`price_profile_20261013_hilda31w/read_k_w_20261013.log`: likelihood +6.2149, atmospheric Δ¹⁴C +7.094, δ¹³C −2.676,
     `hs_asx_frac` −19.917 = 88 %, posterior price −15.40).
  4. `Rscript calibration/diag_card3_kw_diseq_scan.R --profile=outputs/diagnostics/price_profile_20261111_hilda31fl/profile_k_w_A.rds`:
     gate D and the row families at the re-fitted point. Its PROFILE GATE requires the dg path to reproduce the
     profile's stored rows (< 1e-4); smoke-tested 11-11 (the canonical as a fake profile 1.1e-10 PASS; `kz` ×1.05
     5.5 FAIL). This rewrites the committed `card3_kw_diseq_scan_20261111_hilda31fl.{log,rds}` with the extra section;
     the scan part is deterministic, so only the new section should differ (check with `git diff`).
  5. Fill the sheet's B20 "Card 7, measured: PENDING" paragraph and settle the card 3 recommendation. The question:
     with everything re-fitted, do the atmospheric δ¹³C rows still hold `k_w` up? At `hilda31w` they did not (−2.68
     against +7.09 for Δ¹⁴C), which is why the sheet recommends cutting card 3's sentence: it conflicts with card 7's
     "the data prefer the literature value". If the δ¹³C rows now hold, switch the recommendation to option (a).
  6. Commit, add a CHANGELOG line under (q) or a new (r), send Marcus the updated sheet. Update the fill-in page
     too: https://claude.ai/artifact/MTiQHcqrUMichcsaNx8vMC (source `outputs/diagnostics/groupb_20261111/group_b_sheet_page.html`,
     screenshots from `shots/`). Edit the `b20-card7` item (drop `pending`, fill `found`, options, `rec`), then publish
     with `url` set to that link (read it first with the Artifact tool's `read`). Marcus's choices live in the page's
     store, collection `decisions`, one document per item id (`b19`, `b20-card3`, …, `b9-1` …); read them with
     ArtifactData `list`, not by asking.
  7. Remove the frozen worktree (`git -C <repo> worktree remove ~/ccx_frozen/20261111_kw1446_profile_hilda31fl`) once
     the outputs are copied and the read reproduces from the copies.

## 3. Findings this session (in the sheet, with sources)

- **B19:** card 4's "on the What-if tab's measure it is less" was an estimator mismatch. On both like-for-like
  estimators the model tracks Niño 3.4 more closely than the record at every lag (both peak together: 5 months on card
  4a's, 11 on the What-if tab's). The 10-15 reading paired model annual-mean differences with GCB Jan-to-Jan, which
  shifts the model's peak by 6 months. `calibration/diag_card4_enso_estimators.R`, seed 20261111, two runs identical.
- **B20 card 3:** mixed layers want `k_w` ×0.78 / ×0.87; hemisphere averages ×0.90 (N) / ×1.19 (S, faster); cold boxes
  and the asymmetry nowhere in ×0.70–1.30. `calibration/diag_card3_kw_diseq_scan.R`.
- **B21:** SST half-amplitudes 67 % (N) / 91 % (S) of ERSSTv5; least influential model parameters on the map; moving to
  the measured values changes the Keeling seasonal chart by −3.6 % / −6.8 %. `calibration/diag_card7_sst_amp.R`.
- **B4 (new):** since batch A's A2, El Niño off (+0.161 ppm) and volcanic off (+0.217) both print "+1 ppm", because the
  full model's 2024 level is 425.433; the "year-to-year mechanisms" sentence is unreachable.
  `outputs/diagnostics/groupb_20261111/groupb_numbers.R`.
- **B14:** annual means remove the airborne-fraction band from 1755 on (year-to-year change ≤ 1.1 points); the monthly
  swing drops below 5 points only in 1908. Prototypes A/B/C were run in the real app (throwaway worktree, removed; diff
  `outputs/diagnostics/groupb_20261111/proto_b14_worktree.diff`).
- **In passing:** the Pulse lab legend loses the ₂ of "CO₂" at 768 px (B18 #5); `server.R`'s comment above
  `output$c_resid` claims shared x limits it does not have (B15).

## 4. Traps met this session

- **`Shiny.setInputValue` changes the server's input but not the widget.** A screenshot then shows "Both" while the
  chart draws the south. Load a bookmark URL (`?_inputs_&tabs=…&k_hemi=%22SH%22`) instead; `cdp_shoot.py`'s `{"url": …}`
  step does this.
- **A fitted name is not always in `APP_PARAMS`:** `bomb_total`, `luc_scale`, `rep_dC` live in `APP_BOMB_TOTAL` etc., and
  `sigma_d14c`, `grad_off_*`, `imb_share_*` are likelihood-only. A gate comparing the app with the mode file must
  handle both (B19's driver does).
- **`ccx_obs_co2_scored()` returns the whole obs list**; the monthly frame is its `$co2`.
- **Running a committed diagnostic with a new option overwrites its committed outputs.** Restore with `git checkout`
  before committing the driver change (done once here).
- **Temporary `.claude/launch.json` entries** for prototypes: reverted after each start (`git checkout -- .claude/launch.json`);
  the file is clean now.

## 5. Running or left behind

- Profile processes 87528 / 87529 and the frozen worktree (section 2). Nothing else: headless Chrome (9341) killed,
  the app server on 7788 and both prototype servers stopped, the prototype worktree removed.
- The sheet is also a fill-in page (Marcus asked for it): https://claude.ai/artifact/MTiQHcqrUMichcsaNx8vMC, private,
  db capability, 37 decisions saved to collection `decisions` as he picks them (empty at publish, checked).
