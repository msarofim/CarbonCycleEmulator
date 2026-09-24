# Handoff — 2026-09-24 (b). **F1 is SHIPPED and browser-verified. F3 is ANSWERED BY MEASUREMENT and the answer is "caveat, not refit". The next session builds F2, then F4, then F5 — and Q3/Q1 is the one that could still move a number.**

> ⚠ **IF YOU ARE A FRESH SESSION: every path here is relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** The standing rule
> launches sessions from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd), so a bare
> `notes/...` will not resolve. Prefix with the absolute path, or `cd` there.
>
> **Read first, in this order:** `notes/handoff_2026-09-24_app_review_round2.md` (the five rulings
> — still the governing document) · CHANGELOG **09-24 (b)** · then **§3 below**, the only part
> containing work not yet done.
> ⚠ `~/.claude/CLAUDE.md` applies. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY — read
> `INDEX_ccx_ref.md` (the app) and `INDEX_ccx_var.md` (ENSO) before answering anything here.

## 1. What this session did
Marcus's order was **F1 → F2 → F4**, with **F3 to be investigated first**. F1 is built and
verified; F3 is measured and closed as a caveat. **F2, F4 and F5 are NOT started.**
Commit: **`bf7e879`** (one commit, both items). ⭐ **The model is untouched** — `v1.0-hilda29l`
at `3d1b0c0` is still the tag, objective #13 still frozen, no parameter or prior moved.

## 2. ⭐⭐ F3 IS ANSWERED — and the answer is not the one the comment expected
`calibration/diag_f3_enso_in_the_gmst_driver.R`. Full detail in CHANGELOG 09-24 (b) and memory
`ccx_enso_double_count_measured`.

| question | answer |
|---|---|
| Can FaIR estimate the ENSO residual? | **Yes.** Power check passes: FaIR's forced series on the index is −0.0022 ± 0.0104 °C/°C, p = 0.84. β = **+0.115 ± 0.014 °C per °C at a +4-month index lead**, partial R² 0.47. The lag was scanned in BOTH directions and +4 months is the canonical one. |
| ⭐⭐ Is FaIR NEEDED? | **No.** Regressing the OBSERVED record directly gives **+0.111 vs +0.115** — 0.2 of one se apart — while the 841 configs move β by **57 % of its own value**. FaIR adds nothing and imports an ambiguity the direct route avoids. |
| ⭐⭐ Does it matter for CARBON? | **Barely.** On the app's own estimator at `hilda29l`: temperature channel **−3.4 %**, `gamma_enso` **−22.8 %**, both **−21.8 %** (NOT additive). Across the 5–95 % config range the temperature channel is **2.5–4.3 %** ⇒ **no config brings them within 5×.** |
| Verdict | ⛔ **CAVEAT, not refit.** Marcus's fallback branch is the one the measurement supports. |

⚠ **The residual is internal variability + forcing error + obs error** (PDO/AMO and
volcanic-response error land in it too), so every number is an **UPPER BOUND** on the ENSO part.
⚠ **What is still OWED if he wants the caveat written**: the actual sentence in the app. The
measurement says what it should say; nobody has drafted it. Per the standing rule, reader-facing
copy states the current fact and carries **no fix history**.

## 3. What is NEXT, in Marcus's order
1. **F2 — residual panels**, "full model minus measured" and "experiment minus measured", on the
   second panel. He flagged the complexity risk himself; the alignment machinery exists (Keeling
   card 1's residual pair). ⚠ The new driver panel is now the THIRD panel on that tab — decide
   whether F2's residual goes on the growth panel (his words: "the second panel") or becomes a
   fourth. **That is a question for him, not a default.**
2. **F4 — the temperature/CO₂ radio** on "Build your own" and "Pulse lab" (it exists on
   Scenarios). Small, self-contained.
3. **F5 — the 1900–2150 span** on Scenarios and Build-your-own. APPROVED, with the mid-frame
   splice accepted. ⚠ Re-check the splice caption reads correctly once the splice is mid-frame.
4. **Q3 + Q1 as ONE investigation** — forest regrowth vs CO₂ fertilisation. ⭐ Still the only open
   item that could move a number, and the testable hypothesis is unchanged: the model crosses land
   source→sink in **1971** against the measured **1989**, and an over-strong single fertilisation
   term doing the work of both is exactly what makes the sink appear too early. ⛔ Costs a new pool
   or flux, a new fitted name and a REFIT — same freeze consideration F3 had.

## 4. Still OPEN, unmeasured — do not report these as settled
- ⛔⛔ **Q4: "more than half the model's wobble remains" still has no computed source in a
  DELIVERABLE**, and the app cannot run the three-way-off experiment it describes (`c_mech` is
  single-select `radioButtons`). ⚠ **New this session**: a code comment in `R/mechanisms.R`'s
  `enso` entry DOES carry numbers (ENSO −23 %, temperature −22 %, volcanic −8 %, all three
  −43 %), and **this session's independent run reproduces the ENSO leg exactly (−22.8 %)**. So
  the figure is probably right — but it is still prose the reader cannot reproduce in the app.
  **Measure the three-way case and then decide whether the claim belongs in the app.**
- **Q2 (#14)** — is the Revelle effect on year-to-year SCATTER really that large? Unmeasured.
- **Q5 (#25)** — anything more recent than Joos et al. (2013) for the pulse response? Card 5.

## 5. ⚠ Non-obvious state to carry
- ⛔⛔ **`preview_start` STILL STARTS THE WRONG SERVER, and the cwd does not help.** Asked for
  `ccx-app` it launched **`docket-site` on 8765** — twice, this session, once with the session's
  primary working directory already changed to `CarbonCycleEmulator/`. ⇒ **the harness resolves
  `launch.json` from the SESSION ROOT (`FaIRtoFrEDI/`), not the cwd**, and falls back silently.
  ⭐ **The workaround used this session avoids touching FaIRtoFrEDI's tracked `launch.json`
  entirely**: start it from Bash with `run_in_background`
  (`Rscript -e "shiny::runApp('app', port=7788, host='127.0.0.1', launch.browser=FALSE)"`) and
  point the browser pane at `http://127.0.0.1:7788` with `navigate`. Prefer this to the DEPLOY.md
  workaround — it leaves no tracked file dirty.
- ⚠ **A PREVIEW SERVER IS RUNNING** on `http://127.0.0.1:7788` (PID via
  `lsof -nP -iTCP:7788 -sTCP:LISTEN -t`; kill THAT, never `pkill -f` the runApp string).
  ⚠ **Start-up took ~2–4 min** at load 2–3 this session, longer than the 73 s idle figure.
- ⚠ **`get_page_text` RETURNS THE WRONG TAB.** Shiny keeps every tab in the DOM and the tool's
  main-content heuristic picks tab 1 whatever is selected. Use
  `javascript_tool: document.querySelector('.tab-pane.active').innerText` instead — that is how
  every copy check in this session was made.
- ⛔ **`git add -A` STAGES `CarboTopeSubstack.docx`** — Marcus's untracked drafting in the repo
  root. It was caught and unstaged this session. **It is still untracked and still unignored**, so
  the next `git add -A` grabs it again. ⚠ **Ask him whether to gitignore it**; do not decide.
- ⚠ **`ccx_global_co2()` lives in `app/R/plots.R`, not `R/`**, so it is not on the path in a
  `calibration/` diagnostic. Inline it rather than sourcing plots.R into a numerical script.
- ⚠ **MEMORY BUDGETS TIGHTENED BY THIS SESSION.** `INDEX_ccx_ref.md` is now **17,586 B** of its
  18,432 hard ceiling (~850 B headroom — it was ~1.5 KB) and `INDEX_diag.md` is **16,410 B**, over
  its 14 KB soft target and split only on 09-23. ⛔ Per [[memory_index_split_beats_trim]] **split
  rather than trim** — and **Marcus asks for splits explicitly**, so do not restructure unprompted.
  **Flag both to him at the start of the next session.**
- **The three DEPLOY blockers are unchanged and all Marcus's**: `APP_FEEDBACK_URL` and
  `APP_REPO_URL` both `"SET-BEFORE-DEPLOY"` (⚠ update `test-review-cards.R` when set, do not
  delete it); start-up **re-timed on an IDLE machine** (still not done; load was 2–3 all session,
  better than 09-23's 6.7–13.6 but not idle); and the hosting plan's concurrency limits.
- ⚠ **`fair_outputs/egu_fair_levels_v160_egu.csv` is STILL uncommitted in FaIRtoFrEDI** and is
  newer than HEAD's. The new EGU memo versions will build off it; **commit it before citing it.**
- **W4's ratchet entry is still flagged and unratified** — edited while correctly failing (C3
  superseded it). Marcus has not objected and has not ratified. Unchanged from 09-24 (a).

## 6. Memory written this session
`ccx_enso_double_count_measured` (new — the F3 answer), `ccx_diag_must_use_mode_base` (new — the
process trap, see below), `ccx_shiny_app` (F1 section appended), `INDEX_ccx_var` (F3),
`INDEX_ccx_ref` (F1), `INDEX_diag` (the trap).

⭐ **The transferable one is `ccx_diag_must_use_mode_base`**: a diagnostic built on
`ccx_default_params()` + `md$par_mode` instead of `ccx_mode_base()` + `ccx_mode_par_with_pins()`
is **a different model from the app's, is internally consistent across all its arms, and errors
on nothing**. It was caught only because there was an external anchor to check — the app's printed
0.27 ppm/yr and −23 %. ⇒ **give every multi-arm diagnostic ONE number the app or a gate already
prints, and check it reproduces before reading any arm.**
