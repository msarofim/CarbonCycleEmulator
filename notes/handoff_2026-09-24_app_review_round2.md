# Handoff — 2026-09-24. **Marcus's SECOND app review is triaged, its ten COPY items are shipped and browser-verified, and ALL FIVE RULINGS ARE NOW TAKEN. The next session builds F1 → F2 → F4, investigates F3 via FaIR, and opens Q3 — which is the one that could move a number.**

> ⚠ **IF YOU ARE A FRESH SESSION: every path in this file is relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** The standing rule
> launches sessions from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd), so a bare
> `notes/...` will NOT resolve and the handoff will look missing. This exact friction cost the
> first two tool calls of the 09-24 session. Prefix with the absolute path above, or `cd` there.
>
> Self-contained. **Read first, in this order:** `notes/review_2026-09-24_marcus_app_comments.md`
> (the triage) · CHANGELOG **09-24 (a)** · then **§3 below**, which is the only part containing
> work not yet done.
> ⚠ `~/.claude/CLAUDE.md` applies. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY — read
> `INDEX_ccx_ref.md` before answering anything about the app, `rep_dC` or the objective.

## 1. What this session did
R2 was ruled (prior UNCHANGED), IHDE was declined before it opened, the repo got a private remote,
`INDEX_diag` was split, and then Marcus's 09-24 comments arrived and became the work.
Commits: `b616956` · `fb81450` · `053e277` · `62d7b67` · `50cd822` (+ `76d9bac` in FaIRtoFrEDI).
⭐ **The model is untouched.** `v1.0-hilda29l` at `3d1b0c0` is still the tag; no objective, mode
file, parameter or prior moved. Everything is app copy, notes, tests and memory.

## 2. ⭐⭐ THE FIVE RULINGS, taken 2026-09-24 — record them, they gate the next session
| # | ruling | Marcus |
|---|---|---|
| **C1 / C5** | **Use my versions.** C1 keeps the "never told how the carbon divides … it is the next tab" clause his rewrite dropped; C5 keeps the prescribed-temperature distinction and drops only the pedantic tail. **Both already shipped and verified — this ratifies them, nothing to do.** | "Use your versions of C1 & C5" |
| **F5** | **APPROVED — Scenarios and Build-your-own span 1900–2150**, and the history→scenario splice sitting mid-frame is **accepted**. ⚠ That was the whole objection, so it is now a build item, not a question. | "I'm okay with the history->scenario splice being midframe" |
| **F1 → F2 → F4** | **Build order fixed.** F1 the driver panel, then F2 the residual panels, then F4 the temp/CO₂ radio. | "Do F1, then F2, then F4" |
| **F3** | **INVESTIGATE FIRST**: can FaIR estimate the ENSO residual? **If not, caveats in the text only.** See §4 — the answer is a qualified yes and the qualification matters. | "can we use FaIR to estimate the ENSO residual? Otherwise, just add caveats" |
| **Q3** | **PURSUE** — separate forest regrowth from CO₂ fertilisation. "It may fix some of the mismatches." ⭐ §5 gives a TESTABLE hypothesis for which mismatch. | "I think this is worth pursuing" |

## 3. What is BUILT vs what is NEXT
**BUILT and browser-verified (`50cd822`, pushed):** all ten COPY items C1–C10, zero
`shiny-output-error` on every one, old wording confirmed absent. Suite `app|review` **117 / 0**.
**NEXT, in Marcus's order:**
1. **F1 — a third panel showing the DRIVER itself** (volcanic AOD by year, the Niño3.4 index by
   year, emissions by year). ⭐ **Cheapest thing on the list**: every driver is already in
   `app_build_forcing()`, so this is a plot, not a computation.
2. **F2 — residual panels**, "full model minus measured" and "experiment minus measured". The
   alignment machinery exists (Keeling card 1's residual pair). ⚠ Marcus flagged the complexity
   risk himself — keep it to the second panel.
3. **F4 — the temperature/CO₂ radio on "Build your own" and "Pulse lab"** (it already exists on
   Scenarios). Self-contained.
4. **F5 — the 1900–2150 span.** ⚠ It changes the x-range of every futures figure; re-check the
   splice caption still reads correctly with the splice mid-frame.

## 4. ⭐⭐ F3 — CAN FaIR ESTIMATE THE ENSO RESIDUAL? **A qualified YES, and the qualification is the finding.**
**The mechanism that makes it possible:** FaIR is a **FORCED-RESPONSE** model — it has no ENSO and
no internal variability at all. So `observed GMST − FaIR forced GMST` **is** an estimate of internal
variability, and the ENSO-congruent part is recoverable by regressing that residual on the Niño3.4
index (with a lag; the atmospheric response lags the index).

**The assets already exist, across two repos:**
- CCX's temperature driver is **observed IGCC GMST**, `data/forcing_gmst.rds` (`R/forcing.R:725`,
  `FORC_GMST_PRE1850 = 0`). CCX already carries a FaIR-derived `data/climate_module.rds` — but that
  is for FUTURE temperature, not a historical forced series.
- FaIR GMST baselines are in the SIBLING repo: `FaIRtoFrEDI/fair_outputs/fair_baseline_gmst_*.csv`,
  **FaIR 2.2.4 (calib 1.6.0), 841 configs**.

⛔⛔ **BUT THE REASON TO DO IT IS NOT THE ONE THE COMMENT GIVES, AND THIS IS THE PART TO CARRY.**
CCX currently sees ENSO **TWICE**: once through the observed GMST driver, which CONTAINS ENSO's
temperature signature, and again through the explicit Niño3.4 index that `gamma_enso_*` acts on.
⇒ **There is a live double-counting question**, and Marcus's #12 ("disentangle the long-term warming
effect from the ENSO impacts on temperature, and then add the ENSO temperatures back into the ENSO
effect instead") is exactly that instinct. **Measure the overlap before building anything.**

⚠ **FOUR CAVEATS, all of which must be stated at the gate:**
1. The residual is **internal variability + forcing error + obs error**, not ENSO alone. Volcanic
   response error and aerosol uncertainty land in it too; so do PDO/AMO.
2. It is **config-dependent** — which of the 841 FaIR members is "the" forced response is a choice.
   Use the median AND report the spread; do not quietly pick one.
3. ⛔ **Acting on it is a REFIT, not a text change.** Removing the ENSO temperature signal from the
   GMST driver changes what `gamma_enso_*` is absorbing, so every fitted value moves. **The
   objective is FROZEN at #13** (freeze record §4.1) and a driver change is at least as large as an
   objective change. **Marcus's fallback — "otherwise, just add caveats to the text" — is the
   cheap branch and should be costed against the refit before anyone starts.**
4. ⚠ Like-for-like: FaIR's GMST and IGCC must be on the **same reference window** before
   differencing, or the residual carries a constant offset that is pure artefact.

**Recommended first step (cheap, no model change):** difference the two series, regress the residual
on Niño3.4, and report how much of the ENSO temperature signal the GMST driver is ALREADY carrying.
That number decides whether F3 is a build or a caveat, and it is a few hours, not a refit.

## 5. ⭐⭐ Q3 — forest regrowth vs CO₂ fertilisation, with a TESTABLE hypothesis
**Today: in this model CO₂ fertilisation IS the land sink** — there is no separate land-uptake
mechanism (`R/mechanisms.R`, the `fertilisation` caveat says so in as many words).

⭐ **THE HYPOTHESIS THAT MAKES THIS WORTH DOING, and it is testable:** the model crosses from land
net-source to net-sink in **1971**; the measured budget crosses in **1989** — an **18-year** gap
(CHANGELOG 09-22 (s)). If a SINGLE fertilisation term has to do the work of BOTH fertilisation and
regrowth, it must be tuned strong enough to cover both — and since regrowth was small early in the
record and grew later, an over-strong fertilisation term would make the sink appear **TOO EARLY**.
⇒ **An early crossing is exactly the signature a missing regrowth term would produce.** That is a
prediction Q3 can be tested against, not a hope.

⚠ **It also bears on Q1** (Marcus asked twice, #7b and #15, why the model's land sink exceeds GCB's
in the last decade) — same term, opposite end of the record. **Treat Q1 and Q3 as ONE
investigation.** ⛔ Note gate 7 PASSES (land 3.09 vs GCB), so this is not a gate failure; it is the
app's own GCB panel and the recent decade.
⛔ **Cost: a new land pool or flux, at least one new fitted name, and a REFIT.** Same freeze
consideration as F3.

## 6. Still OPEN, unmeasured — do not report these as settled
- ⛔⛔ **Q4: "more than half the model's wobble remains" HAS NO COMPUTED SOURCE.** It is prose in
  `R/mechanisms.R`'s `enso$caveat`, and it describes a **three-way-off experiment the app CANNOT
  RUN** — `c_mech` is `radioButtons`, single-select. Marcus (#18) is surprised by it. **Measure it
  before defending it**, and if it holds, ask whether a claim the reader cannot reproduce belongs
  in the app.
- **Q2 (#14)** — is the Revelle effect on year-to-year SCATTER really that large? He is surprised
  ⇒ the "implausible result = bug" discipline says measure, do not reassure.
- **Q5 (#25)** — anything more recent than Joos et al. (2013) for the pulse response? Belongs on
  Known-issues card 5.

## 7. Non-obvious state to carry
- ⚠ **A PREVIEW SERVER IS RUNNING** on `http://127.0.0.1:7788`, started via `preview_start`
  (serverId `622f3c4c-0354-4d75-8e4e-ef7abf84f150`). Stop it via the process holding the RESOURCE
  (`lsof -nP -iTCP:7788 -sTCP:LISTEN -t`), **never `pkill -f`** on the runApp string.
- ⛔⛔ **`preview_start` STARTED THE WRONG SERVER AND SAID NOTHING.** Asked for `ccx-app`, it
  launched **`docket-site` on port 8765** — the harness resolves `launch.json` from the SESSION root
  (`FaIRtoFrEDI/`), which has no `ccx-app`, and it **fell back silently instead of erroring.**
  `app/DEPLOY.md` predicted this; its workaround (a temporary entry in the session root's TRACKED
  `launch.json`) worked and **has been reverted** — verify with `git -C FaIRtoFrEDI status`.
- ⛔ **`nohup Rscript … &` from Bash DOES NOT behave as expected**, and I misdiagnosed it once: the
  process did NOT die, it was **orphaned to `ppid 1`** and kept running, so I ended up with **two
  instances racing for port 7788**. The tell is `ps` showing the work process with `ppid 1`.
  **Always confirm how many instances exist before concluding one died.**
- ⚠ **THE COPY RATCHET IS SENSITIVE TO LINE WRAPPING**, not only wording: a `paste()` re-wrap split
  "an ENSO index and volcanic aerosol" across two literals and the ratchet went red on unchanged
  rendered text. **Keep asserted phrases contiguous inside one string literal.**
- ⛔ **A RATCHET ENTRY WAS EDITED WHILE CORRECTLY FAILING.** W4 was superseded by Marcus's C3, so
  its required phrase moved to C3's wording (pre-09-22 phrase still forbidden, reason recorded in
  `test-app-review-copy.R`). **Flagged to Marcus for override; he has not objected, but he has not
  explicitly ratified it either** — unlike C1/C5, which he did.
- **The three DEPLOY blockers are unchanged and all Marcus's:** `APP_FEEDBACK_URL` and
  `APP_REPO_URL` are both `"SET-BEFORE-DEPLOY"` (⚠ update `test-review-cards.R` when set, do not
  delete it); start-up must be **re-timed on an IDLE machine** (73 s idle / 148 s contended — NOT
  done, load was 6.7–13.6 all session); and the hosting plan's concurrency limits.
- ⭐ **The repo now has a PRIVATE remote**, `msarofim/CarbonCycleEmulator` — 914+ commits and both
  tags. Public was declined. `main` is pushed and clean.
- ⚠ **`CarboTopeSubstack.docx` is untracked in the repo root — Marcus's drafting.** Do not read,
  edit or commit it. Its `~$` lock is now gitignored (`~$*` added 09-24).
- ⚠ **The EGU memo's uncaptured prose is a WITHDRAWN concern** — Marcus 09-24: "that version is
  obsolete, and we are working on new versions." ⛔ But `fair_outputs/egu_fair_levels_v160_egu.csv`
  is still uncommitted in FaIRtoFrEDI and is NEWER than HEAD's (09-21 `2d40652`, 48 rows, 8 arms
  incl. `noegu50_zero2100` vs 09-20 `ff05175`, 42 rows, 7 arms). **The new memo versions will build
  off it; commit it before citing it.**
- ⚠ **`INDEX_ccx_ref.md` is at 16,954 B of its 18,432 B HARD ceiling** (~1.5 KB headroom) after
  this session's two additions — **the next split candidate**, and `INDEX_ccx.md` (15,716) and
  `INDEX_diag.md` (15,402) are over their 14 KB soft targets too. Root `MEMORY.md` is 14,098 B of
  CONTENT (strip the `<!-- -->` blocks first) against a 12 KB soft. ⛔ Per
  [[memory_index_split_beats_trim]], **split rather than trim** — and Marcus asks for splits
  explicitly, so do not restructure the tree unprompted.
- **Memory updated this session:** `ccx_app_beta_blockers` (REWRITTEN — it was quoting a superseded
  era), `ccx_shiny_app` (three retractions marked incl. the "~20 s cold" that DEPLOY.md had already
  corrected), `ccx_ihde_declined` (new), `tolerance_scaled_to_spread_can_be_blind` (new),
  `ccx_rep_dc_prior` (R2 ruled), `INDEX_infra` (the remote), `INDEX_diag` **SPLIT** →
  `INDEX_diag_conv.md`.
