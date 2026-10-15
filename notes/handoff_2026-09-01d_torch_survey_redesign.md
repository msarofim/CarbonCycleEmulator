# Handoff — CarbonCycleEmulator, 2026-09-01d
# **THE TORCH SURVEY IS RE-DESIGNED FOR THE 25-PARAMETER MODEL. STILL YOURS TO SUBMIT.**
# **09-01c said "launch it". Read §1 before you do — the array it described had no baseline.**
# **The decision §2 of 09-01c left owed is ANSWERED, with the reasoning; override it if you disagree.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at **`95b872f`**.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use
`git -C <abspath>`.

**Reads before this one:** `calibration/torch/README.md` (the design, now re-cut) and
`handoff_2026-09-01c_torch_launch.md` (what was ready). **Nothing is adopted**; `CCX_MODE_CANONICAL`
is untouched. Suite **1365 / 6 FAIL / 2 skip**, the same six.

---

## 0. STATE IN SIX LINES

1. ⛔ **NEITHER KNOWN BASIN IS A MODE OF THIS SPACE, so the survey as staged had nothing to rank a
   result against.** Fixed by three new fixed ids, not by a caveat. §1
2. ⛔ **The dispersion was diluted 8.4 % by a bookkeeping artifact** — 0.9592 should have been
   **1.0466**. §2
3. ✅ **The N = 40 decision is ANSWERED: keep 40, and make ROUND 2 A SUBSET, not the same array.** §3
4. ✅ **Preflighted for ids 0–5, 25, 45; end-to-end for 4/5/25; and through the real sbatch body from
   a freshly extracted bundle.** Bundle rebuilt, **2.1 MB**. §4
5. ⚠ **The Mac serial polish is now largely REDUNDANT with ids 3–4** — run it for the Hessian, not
   for the mode. §5
6. ⛔ **Claude still cannot submit.** VPN, gateway password, Duo, device-code. §6

---

## 1. ⛔ WHAT 09-01c GOT WRONG, AND IT WAS NOT A DETAIL

09-01c said ids 1 and 2 "must re-find −1548.01 / −1496.01", and its §4 noted in passing that neither
reference point is a mode of the 25-parameter space. **Those two statements cannot both stand, and
the second one is the load-bearing one**: it makes the survey's verdict — "did anything beat
−1496.01?" — a comparison of a 25-parameter optimum against a 21-parameter migrated point
[[like_for_like_forcing]].

**Measured on the shipped objective (4 evaluations, reproduces `diag_enso_objective_leverage.R`):**

| point | log-post |
|---|---|
| migrated incumbent | **−1551.1222** |
| migrated new basin | **−1500.0507** |
| new basin + ocean ENSO **+0.10 each** | **−1498.1420** (**+1.9087**) |
| incumbent + ocean ENSO +0.10 each | −1550.8275 (+0.2947) |
| new basin + **ocean +0.326 each, land ×1.734** | −1507.6925 (−7.6418) |

⇒ **THE BASELINE A SURVEY IS JUDGED AGAINST MUST BE PRODUCED BY THE SURVEY**, on the same machine
and the same objective. The array's fixed head therefore grew **3 ids → 6**:

| id | start |
|---|---|
| 0 | COLD hand-set init |
| 1 | INCUMBENT, migrated — **UNSEEDED control** |
| 2 | NEW BASIN, migrated — **UNSEEDED control** |
| **3** | incumbent + ocean ENSO **+0.10 each** (the objective's own conditional optimum) |
| **4** | new basin + the same |
| **5** | new basin + the **OBSERVATION-implied** partition (ocean +0.326 each, land ×1.734) |

⭐ **Ids 1/2 are kept unseeded ON PURPOSE**, beside 3/4: the pair is the only thing that says what
the seeding was worth, and the collector prints that difference.

⭐ **Id 5 is conditionally WORSE and is started anyway.** It begins where GCB's measured ENSO sink
slopes say the partition is; a frozen slice scores that at −7.72. But a conditional sign is a
**hypothesis about a refit, not a prediction of one** — the gate-pricing arc measured **253 log-units
of pure frozen-slice artifact** [[ccx_gates_priced]], and 09-01g's compensating-error state is
precisely other coordinates absorbing an ENSO change. One task buys the answer to "started where the
OBSERVATION says the partition is, does the fit stay near there?"

**The collector changed with it.** Its verdict is an ordering against the **best FINAL value among
ids 1–5** (naming any that are missing), and it now reports **BEST DISPERSED separately from BEST
FOUND** — only a dispersed start can answer "is there a third basin", and with the fixed starts
seeded the top of the table is quite likely to be one of them [[no_power_null]].

## 2. ⛔ THE DISPERSION WAS 8.4 % TOO NARROW, FOR A BOOKKEEPING REASON

`MS_SPREAD` is the per-coordinate RMS separation between the two known basins. **Four of the 25
coordinates were migrated in BOTH files**, so their separation belongs to the migration contract and
not to the basins: the ocean pair differs by **exactly 0**, the land pair by **0.0100** — the retired
scalar cut in half. Averaging them in multiplied the whole dispersion by **√(21/25) = 0.9165**.

**RMS over all 25 = 0.9592. Over the 21 that at least one reference point FITTED = 1.0466.** The pool
is now the second, derived from `attr(, "migrated")` — the field the migration itself records — so
the next split fixes itself, and the excluded names are **printed**.

⚠ **This does NOT give the four ENSO coordinates a scale of their own**, and the code says so at the
point of use. They are dispersed at the shared pooled sd, which is an **assertion**: their own
separation is structurally zero and no second basin exists to measure it against. 09-01j is the check
that it is not silly — at ~1.05 they land **6–9 conditional sds** out against **325–430** for the
stiffest coordinates. **If you want them dispersed on their own scale, that is a choice you have to
make; nothing here measured one.**

## 3. ✅ THE DECISION 09-01c LEFT OWED, ANSWERED — AND THE ANSWER IS NOT "40 OR MORE"

The question was posed as a width question. **It is a depth question.** At 25 parameters the
Nelder-Mead simplex has **26 vertices**, so each task converges less far in the same wall, and the
09-01 production-shape measurement already said most tasks land in the **−1500s, unconverged**.

⇒ **N stays at 40, and ROUND 2 IS A SUBSET.**
- **Round 1**: `sbatch --array=0-45%10` — every fixed id, every dispersed id.
- **Round 2**: **the six fixed ids plus the best ~8 dispersed ids** from `summary.csv`, same command,
  same output directory; each resumes from its own checkpoint.

⛔ **Do NOT re-submit `0-45` a second time**, which is what 09-01c and the old README advised. A start
50+ log-units behind after round 1 is not a third-basin candidate; converging it costs a full task and
changes no verdict. **The fixed ids are the exception and are always re-submitted** — they are the
baseline the verdict is an ordering against.

⚠ **What this trades away, said out loud** [[no_power_null]]: a truncated start is ranked on a value
it had not finished climbing to, so a deep basin that happened to start slowly can be dropped in round
1. That is why the cut is the best **~8**, not the best 2, and why OUT-OF-TIME is printed beside every
rank.

**What did NOT change**: `CCX_MS_MAXIT = 6000` (the **wall**, not the cycle budget, stops a round —
3 × 6,000 evals is ~111 min at 0.37 s/eval, so a 180 min task does not reach two cycles); the
dispersion **center** (still the COLD init); and the objective and parameter table —
`port_targets.csv` still stands at `53ef03d`, `n_par = 25`, and **nothing needed it re-run**.

## 4. ✅ WHAT WAS VERIFIED, AND HOW

- **Preflight, ids 0, 1, 2, 3, 4, 5, 25, 45** — all eight `PORT GATE (a) PASSED`, rel **7.6e-16 to
  2.5e-14**. ⚠ On the Mac that gate is near-tautological; **its real test is the first Torch task.**
- **End-to-end, ids 4, 5, 25** on a 3 min budget — exit 0, checkpointed, `PORT GATE (b)` ordering OK,
  and the shortened-restart path exercised (id 25 climbed **−168,724 → −4,754** in one 476-eval
  restart).
- **Through the real sbatch body**, from a freshly extracted copy of the rebuilt bundle
  (`CCX_PROJ` + `CCX_SKIP_MODULES`) — same three start values to the digit.
- ⭐ **A GUARD FOUND BY MUTATION-TESTING THE GUARD.** The first cut dispatched the seeded ids as
  `id == MS_SEED_IDS[["new_obs"]]`; deleting an entry then died at *"subscript out of bounds"* three
  frames from the cause and **never reached the gap guard written for exactly that case**. Dispatch is
  now through `names(MS_SEED_IDS)[match(id, ...)]`, and **both directions fire with the reason**.
  ⇒ **an unreachable guard is not a guard** [[mutation_test_gates]].
- **Suite 1365 / 6 FAIL / 2 skip**, the same six. ⚠ A 7th appeared on the first run —
  `test-parity.R:235`, the 50 ms/run performance budget, at **0.0530 s** — and it is **CONTENTION,
  not a regression**: three optimizer tasks were running beside the suite (load 7.6) and the file
  passes 57/57 alone [[eta_in_days_is_not_a_slow_run]].

⚠ **Use a FRESH output directory.** The default moved to
`calibration/output/multistart_20260901_enso25` — it names the **parameter set**, not a date.
`calibration/output/multistart_20260831/` is empty and is for a 22-parameter build.

## 5. ⚠ THE MAC SERIAL POLISH IS NOW LARGELY REDUNDANT

09-01c §4 recommended running `run_modefind_pump_arms.R` on the Mac in parallel. **Ids 3–4 now do
that job on Torch, port-gated and seeded.** The Mac run still earns its place for one thing the
survey deliberately does not produce — **the Hessian** — and it costs no fairshare, so running it is
not wrong. ⚠ **But it warm-starts UNSEEDED** (`ARM_WARM = TRUE` → `par_mode` through
`ccx_migrate_par_set()`, so the ocean pair is 0): it has to find the +1.91 for itself, with
Nelder-Mead, in 25 dimensions. Nothing was changed in that driver.

## 6. THE LAUNCH, IN ORDER

⚠ **Claude cannot do any of this.** Full command list is in `calibration/torch/README.md`.

1. **Ship it.** `/tmp/ccx_torch_bundle.tar.gz`, **2,114,388 bytes** (`du -h` rounds to 3.0M — that is
   allocated blocks). Rebuild with `bash calibration/torch/make_bundle.sh` if the repo moves; re-run
   `Rscript calibration/make_port_targets.R` FIRST only if the **parameter table** changed.
2. `bash calibration/torch/setup_torch.sh` (once).
3. **Preflight array**: `CCX_MS_PREFLIGHT=1 sbatch --array=0-5,25,45 --time=00:15:00 …` — ~2 min/task.
   **Read the s/eval it prints and size the run on THAT.**
4. **Read PORT GATE (a) in the logs.** A mismatch is the one result that stops everything: it means
   Torch does not reproduce the Mac's objective. **It is not a reason to widen a tolerance.**
5. **Round 1**: `sbatch --array=0-45%10 …` — and **look at the first wave** before walking away.
6. **Collect**, then **round 2 = `0-5` plus the best ~8**. §3.

## 7. NEXT, AFTER THE SURVEY LANDS

1. **Read the three numbers the fixed head produces**: what the ENSO seeding was worth at each basin
   (ids 3−1 and 4−2), and whether id 5 held near the observation-implied partition or fell back.
2. **Then** the third-basin question, from BEST DISPERSED.
3. **Adopt** — `run_post_refit_adoption.R`, which refuses anything not on this parameter set.
4. **Ratify the ENSO prior** (`handoff_2026-09-01b` §5) — each of the four keeps N(0, 2), which widens
   the implied prior on the land TOTAL by √2. **Still the only open methodological choice** that
   predates this session.
5. **A profile or Hessian on the four**, which is what turns structural identifiability into
   demonstrated precision.
6. ⚠ **`sinfo -o "%P %l %m %c"` is still unrun** — `cs`'s wall limit is unknown, and it only matters
   for a possible long-wall phase 2.
7. ⚠ **The app still ships UNCALIBRATED DEFAULTS** since 08-31 — `app/global.R` skips any mode whose
   `param_names` differ and the canonical mode is a 21-parameter file. Unchanged, still a separate
   decision.
