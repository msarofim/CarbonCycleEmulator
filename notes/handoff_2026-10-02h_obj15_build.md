# HANDOFF 2026-10-02 (h) — build the ENSO lag, the Law Dome rows and the gate repairs; then one two-arm refit (objective #15)

**Start here.**
1. Launch from `FaIRtoFrEDI/` and move into this repo with `change_directory`. The memory keyspace follows the launch
   directory.
2. Read, in order:
   - this note;
   - `notes/plan_2026-10-02_obj15_lag_iced13c.md` (the work itself: W1–W5, the open choices, the refit mechanics);
   - `notes/audit_2026-10-02_design_vs_build.md`;
   - memory `INDEX_ccx_var.md` → `ccx_enso_response_too_early`, `ccx_design_audit_and_obj15_plan`.
3. The governing rules are in both CLAUDE.md files (global and project). Rule 1 needs an R↔C++ parity test for any core
   change; rule 2 needs a citation for every number.

## 1. What we are doing and why
- Marcus asked why switching ENSO off does not hurt the What-if fit.
- **Measured:** the model's land ENSO response arrives ~5 months early. DESIGN's fitted lag `L_MEI` was never built.
  - Diagnostic: `calibration/diag_enso_growth_fit.R` → `outputs/diagnostics/enso_growth_fit_20261002.*` (CHANGELOG 10-02 x).
- He chose **"Do it right. Option 2"**: build `L_MEI` on the LAND term, fitted, U(0, 12) months, then refit.
- First he had DESIGN.md audited for other never-built items (10-02 y). Then he ruled (10-02 z):
  - **Law Dome ice δ¹³C row IN.**
  - **Ice-core CO₂ cut to pre-1958.**
  - **The fitted-NPP₀ line retired** (D4 stands).
  - **Gates 5, 6, 7, 11 and P7 repaired before the new mode is scored.**
  - **D1:** every registered version moves to objective #15, restamped at priced moves, old copies quarantined.
  - **D2:** a lag-0 CONTROL arm runs alongside the lag arm.
  - **A fresh session for the build** (this note).

## 2. Still open (bring each to Marcus with numbers)
- **D3, how the lag is identified.**
  - A conditional probe by a subagent (not yet reproduced) says the current rows prefer **2–3 months**, via the GCB
    land sink and the seasonal-coefficient rows. The growth timing says **5**.
  - **After W1–W3, profile the NEW objective over L in a committed script, with the ENSO amplitude re-optimized.**
  - The growth-rate row was declined 09-26 (memory `ccx_growth_objective_declined`: "needs a NEW reason"). This may be
    that reason; its three objections still stand.
- **D4, the σ of the ice δ¹³C row** (W2). Also check whether the PI δ¹³C anchor already uses Law Dome (circularity),
  and the end year (DESIGN: "pre-1990").
- **D5, compute.** Two arms × 24 starts: Mac ~18 h, Torch ~6 h. **Say the verdict out loud.** Every sbatch needs
  Marcus's go.
- **W5, the `[VERIFY]` priors** (`k_w`, `tau_ex`). A literature search ran 10-02; its result is in §5 below. A changed
  value is an objective change and goes to Marcus before #15 is assembled.

## 3. Suggested order
1. **W1, the lag build.** It is the largest piece and touches the C++ core.
   - Give the land term its own input. `N_FORCING` stays 19.
   - Generalize the label gate to several gates.
   - Use C¹ (Catmull-Rom) interpolation, init 6 months.
   - Absent = bit-identical.
   - Parity, exactness, segment-history and switch tests; mutation-test them.
2. **W3, then W2:** the ice rows, and the σ proposal for D4.
3. **Assemble objective #15** (D1): price and restamp every registered mode, quarantine the old copies with a README,
   and keep `test-mode-file` green.
4. **W4, the gate repairs**, each mutation-tested.
5. **D3:** the lag profile on #15. Rule with Marcus.
6. **D5**, then launch both arms (frozen worktree, copy `data-raw/downloads/nuclear14c`, preflight, explicit
   `CCX_MS_OUTDIR`).
7. **Adopt:** promote, Hessian, the scorecard with the repaired gates, comparison on likelihood; then the app switch
   and re-running `diag_enso_growth_fit.R` on the new mode.

## 4. State that is not obvious
- **Git.** `main` is in sync with origin. Everything from this session is committed and pushed (HEAD = this note's
  commit), and nothing is half-built.
- **App preview.** The `ccx-app` server runs on **localhost:7788**, on the current code. Marcus has used the link today.
  ⚠ A hidden or zero-size browser tab shows "figure margins too large" on the Keeling plots; that is an artifact.
- **Untracked and Marcus's** — never commit or edit these:
  - `carbotopecomment.9.26.26.docx`: implemented, 10-02 w;
  - **`carbotopecomments.10.2.26.docx`: NEW and unread.** Ask him before working through it.
- **Untracked and deliberately so:** `outputs/mcmc_smoke/`, `outputs/diagnostics/smoke/`.
- **Rulings still binding from earlier today:** the app's bands stay HELD (MCMC arc closed, 10-02 u). Card 6's text is
  Marcus's to word; the facts are in `notes/card6_facts_2026-10-02.md`.
- **Items from Marcus's 10-02 comment round that are mine, for his rewording:**
  - the seasonal-tracer theory (Pins tab);
  - the to-zero temperature sentence;
  - the OWID clause;
  - the FaIR help text;
  - the Under-the-hood nitrogen sentence.
- **A conflict flagged to him, not resolved:** his land paragraph says the sink grows "due to CO₂ fertilisation"; A3
  (10-01) had removed that single-cause wording because N-deposition retention is a second sink.

## 5. W5 result — prior citations
*(appended when the literature search finished; see below)*
