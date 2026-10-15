# QUEUED — three jobs cued up for when the refit lands (Marcus 2026-08-17)

**The machine belongs to the refit until it finishes.** Marcus's instruction this session: *finish the
refit first; cue up the land-use-change merge, the test-failure diagnosis, and the item-4 spec for
when it finishes.* Nothing below was run. Everything below is prepared to the point where it is
turnkey.

**BEFORE ANY OF IT: handoff 16g §5.3 is still job 0** — read the per-stream table and check whether
`co2_level_SPO` / `co2_level_MLO` recovered, **before** the Laplace evidence. If they stayed large in
both arms, both modes are bad, N-vs-D is uninformative, and job C's spec becomes the live path rather
than a filed document.

```bash
tail -40 ~/Documents/2026/CodeProjects/CarbonCycleEmulator/calibration/output/pump_arms/_run.log
```

---

## Job A — merge `luc-veg-debit` into `main` (16g item 9) — **DONE 2026-08-18**

> **COMPLETED.** Fast-forwarded on Marcus's instruction 2026-08-18. `main` = `luc-veg-debit` =
> `e2c9238`; HEAD moved to `main`; `luc-veg-debit` **kept, not deleted**. Pre-merge `main` was
> `0b7371c` — the recovery ref if this ever needs undoing (`git branch -f main 0b7371c`).
> **Fast-forward was chosen over a squash** because it is the *recoverable* option: a squash can
> always be produced later from preserved history, while an un-squash is impossible — and this
> project leans on per-commit provenance for bisecting the pump and gradient work. The 4 test
> failures rode along, as job B was not run first; they are pre-existing and not pump-related.
>
> *Original assessment below, retained.*


**ASSESSED READ-ONLY THIS SESSION, AND IT IS EASIER THAN THE HANDOFFS SUGGEST: this is a strict
fast-forward.**

| check | result |
|---|---|
| `git rev-list --count main..HEAD` | **96** commits ahead |
| `git rev-list --count HEAD..main` | **0** — main has nothing this branch lacks |
| conflict scan (`git merge-tree`, read-only) | **none** |
| diffstat | 187 files, +38,324 / −274 |

So there is no merge commit to resolve and **no working-tree change at all** while sitting on
`luc-veg-debit` — it is a ref update. That also means it would not have disturbed the running refit;
it is queued because Marcus said finish the refit first, not because it is risky.

```bash
git -C ~/Documents/2026/CodeProjects/CarbonCycleEmulator branch -f main luc-veg-debit
```

**Before running it, decide two things that are genuinely Marcus's:**
1. **Does `main` want 96 commits as a fast-forward, or a squash/merge commit** that records the arc as
   one unit? The fast-forward keeps every step's provenance, which this project has leaned on
   repeatedly; a squash loses the ability to bisect the pump and gradient work.
2. **Is the branch in a mergeable state given 4 known test failures?** They are pre-existing and not
   pump-related (job B), but merging carries them onto `main`. Fixing first is defensible; so is
   merging and tracking them.

## Job B — diagnose the 4 test failures (16f §8, carried since 2026-08-15)

**Named, not counted** — from 16f §8:

| test | failure | 16f's triage |
|---|---|---|
| `test-pulse.R` | af(100) = 0.213 vs bar > 0.30 | *unbenchmarked* ballpark on a **declining** ssp119 background; the protocol-matched gate 12 **passes** (12.4 / 25.6 / 41.9 yr) |
| `test-luc-permanence.R` (×2) | the fossil reference arm; a case needing `f_luc_wood = 1` | — |
| `test-mechanisms.R` | ENSO 0.30 vs bar > 0.5 | — |

16f's own words: *"All four are plausibly stale gates rather than physics failures — but nobody has
diagnosed them, so that is an assessment, not a verdict."*

**⚠️ THE STANDING RULE MAKES THIS THE DANGEROUS ONE.** A "stale fixture" label has already hidden a
real bug in this project for five handoffs
(`~/.claude/.../memory/feedback_explained_away_test_failure_is_data.md`), and the repair rule is
**derive, never re-baseline** (`feedback_stale_fixture_repair_derive_dont_rebaseline`): fix a bar by
curvature, closed form, or measured residual — never by moving it to where the code lands. Three of
these four have a *number* and no derivation behind it. Treat "plausibly stale" as the hypothesis to
attack, not the answer.

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && Rscript tests/run_tests.R 2>&1 | tail -60
```

**Do this AFTER the refit** — the suite runs the model and would compete for cores. Expected shape of
the work: for each bar, find where the number came from (commit that introduced it), then either
derive it properly or demonstrate the failure is real. Any bar that cannot be derived should be
**deleted or marked explicitly unbenchmarked**, not loosened.

## Job C — the σ-inflation spec (16g item 4)

**WRITTEN THIS SESSION: [`spec_2026-08-17_sigma_inflation.md`](spec_2026-08-17_sigma_inflation.md).**
Spec only — nothing implemented, nothing proposed for the objective, and it stays Marcus's call.

What it now contains that the decision was previously missing: the form and why the normalization
term is load-bearing; the **quadrature assumption stated rather than buried** (`σ_rep` is a bias, not
a random error); why bias-correction is not the alternative (the like-for-like target rewards a large
`h_ml` and was already rejected for it); the build/PCHIP design; and six named gates including a
mutation test.

**The one input still missing is the COST, and it is post-refit by construction.** 16g's "inflation
recovers 21 % of the skip's gain (2.14 of 10.01 log-units)" was computed **with alkalinity's `σ_rep`
unavailable**. It must be re-derived over all three rows before it is quoted. Expect a small change —
ALK's ratio is 0.02–0.07 in band, the smallest of the three — but expecting small is not measuring
it, and this is exactly the class of number that gets quoted for three handoffs. Re-deriving needs the
model's own gradient at each `h_ml` (16g part 4b), hence the machine.

**Spec's own recommendation, offered not taken:** decide *after* §5.3. If the CO₂-level streams
recovered under the bound, inflation is a posterior-run question and can wait for the sampler. If they
did not, it becomes the live alternative and the re-derivation is the first thing to run.

---

## Done this session, for the record

Both committed, both zero-compute, neither touched the running refit:

- **`89dfb5a`** — 16g item 5: `R/likelihood.R`'s "1.61 σ at 184" corrected to the gate's own **0.80 σ**
  (and "0.09" to 0.07). Comment-only; verified the diff reaches no executable line.
- **`7ea5c4b`** — 16g item 4's blocker discharged: **alkalinity's `σ_rep` measured**, and 16g's "would
  need a new download" was **wrong** — the data was already on disk in the file the target itself was
  built from. ALK is the **best-behaved of the three rows** (0.02–0.07 in band, 0.02–0.34 overall).
  `calibration/diag_alk_sigma_rep.R`, 3 gates + 3 predictions, all pass.

**Open items NOT touched:** 16g items 1 (§5.3), 2 (N-vs-D), 3 (`recompute_hessian.R` +
re-derive `ARM_HESS_EPS` at 20 parameters), 6 (pilot MCMC), 7, 8.
