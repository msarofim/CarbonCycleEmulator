# REVIEW 2026-09-24 — Marcus's second round of CarboTope comments, triaged

Source: `CarboTopecomments.9.24.26.docx` (received 09-24, 28 paragraphs, ~26 actionable items).
Plain body text — **no Word comments and no tracked changes**, so nothing is hidden in the file.
Marcus's standing instruction at the top: *"Wording updates are suggestions: improve the wording
as applicable."* ⇒ the COPY class is delegated, not merely proposed.

Classes: **COPY** (wording, his text supplied) · **FEATURE** (new work) · **Q** (a question to
measure or answer, not edit) · **RULING** (a methodological choice that is his).

⛔ **Nothing in this note is implemented by the note itself.** What was implemented is recorded in
CHANGELOG 09-24 and named per item below.

---

## 0. TWO ITEMS WERE MEASURED, AND HIS INSTINCT WAS RIGHT ON ONE OF THEM

### ⭐⭐ #19 — the air-sea caveat describes a coupling THAT DOES NOT EXIST. He is right.
The `ocean_sink` switch carries: *"This closes the air-sea interface completely, which also stops
the ocean exchanging ¹³C and ¹⁴C. **The isotope panels are not meaningful with this switch on.**"*
Marcus: *"But we can't look at how this impacts the isotope panels, right? So this is not really
worth knowing."*

**MEASURED in `app/server.R`.** The switch is `input$c_mech`, and it drives exactly **six** outputs:
`c_plot`, `c_growth`, `c_growth_note`, `c_blurb`, `c_takeaway`, `w_luc_note`. The isotope panels are
**not among them** — `output$i_d13c` and `output$i_d14c` both render from **`APP_HIST$out`**, the
fixed historical run, and `app_run_mechanisms()`'s counterfactual never reaches them.

⇒ **The caveat is not merely unhelpful, it is misleading**: it implies the reader could switch the
mechanism off and then go and look at a degraded isotope panel. They cannot — the isotope panels do
not move. **Rewrite, do not delete**: the true and useful statement is that the switch's effect on
the isotopes is *not shown anywhere in the app*.
⚠ **METHOD NOTE, because I got this wrong once first.** My initial check reported "zero references
to the switch" from `grep "input\$c_"` — in a BRE, `$` is an END-OF-LINE ANCHOR, so that pattern can
never match and returns 0 for a string that occurs 7 times. **A zero from a grep whose pattern holds
a regex metacharacter is not evidence of absence.** Use `grep -F`. The conclusion survived; the
evidence for it did not.

### ⚠ #13 — the Pinatubo DATE in his suggested text is wrong, and the fix is not the obvious one
Marcus: *"note that the 1992 Pinatubo explosion is where this effect is most visible."*
**Pinatubo erupted in June 1991**, not 1992. The *effect* peaks in 1992, which is presumably what he
means, and the repo's own measurement agrees: the AOD → diffuse-light → NPP path is worth **1.53 ppm
at its largest in 1991–95** (the matched `gamma_diff` 0.25-vs-0 pair, CHANGELOG 09-22 (o)).
⇒ Write it as **"the 1991 Pinatubo eruption, whose effect on the carbon cycle peaks in 1992"**.
Saying "the 1992 Pinatubo explosion" in a public teaching app is the kind of thing a reviewer
catches, and the app's whole premise is that a reader can trust its facts.

---

## 1. COPY — delegated, and implemented unless flagged
| id | where | change |
|---|---|---|
| C1 | `app/server.R` Keeling takeaway | his rewrite. ⚠ **FLAGGED** — see §3 |
| C2 | `app/server.R` `w_luc_note` | his land-use rewrite (regrowth + fertilisation named as the cause) |
| C3 | `app/ui.R` airborne fraction | his rewrite ("ratio of emissions to the rise", "should not be attributed to one factor alone") |
| C4 | `R/mechanisms.R` `warming_feedback$blurb` | "stops noticing the warming" → **"this amplifying feedback goes away"** |
| C5 | `R/mechanisms.R` `warming_feedback$caveat` | he doubts it is relevant ("we only care about warming because of its carbon-cycle effects"). ⚠ **FLAGGED** — see §3 |
| C6 | `R/mechanisms.R` `ocean_sink$caveat` | rewrite per §0 — the isotope effect is NOT SHOWN, rather than "not meaningful" |
| C7 | `app/R/review.R` | "what would you constrain it with?" → **"what do you suggest as possible ways to address this offset?"** |
| C8 | `app/ui.R` | "names the calibration was not allowed to move" → **"parameters"** |
| C9 | `app/ui.R:470` Under the hood | delete "The model is told these; it does not work them out." |
| C10 | `R/mechanisms.R` `volcanic$blurb` | add Pinatubo **with the 1991/1992 distinction of §0** |

## 2. FEATURE — none built; they need a priority order
- **F1 (#11a) — a third panel showing the DRIVER itself** (volcanic AOD by year, the ENSO index by
  year, emissions by year). Cheap and high value: every driver is already in `app_build_forcing()`,
  so this is a plot, not a computation. **Recommended first.**
- **F2 (#11b) — residual panels**, "full model minus measured" and "experiment minus measured", on
  the second panel. He flags the complexity risk himself. Needs the observation series aligned to
  the model's annual grid — the machinery exists on the Keeling tab (card 1's residual pair).
- **F3 (#12) — disentangle long-term warming from the ENSO temperature signal**, and move the ENSO
  temperature into the ENSO effect. ⛔ **This is not a UI change.** The model does not compute its
  own temperature; it is DRIVEN by the observed IGCC record, which contains both. Splitting them
  needs a decomposition of the observed temperature the repo does not have — the same blocker
  already recorded for the volcanic thermal half (`R/mechanisms.R` volcanic caveat) and for C6 of
  the 09-22 round. **RULING, and probably a "no" for the beta.**
- **F4 (#21) — the temperature/CO₂ radio on "Build your own" and "Pulse lab"** (it exists on
  Scenarios). Small, self-contained.
- **F5 (#22) — Scenarios and Build-your-own span 1900–2150.** ⚠ Changes the x-range of every futures
  figure and therefore what the reader sees first; 1900 also puts the SPLICE (history → scenario,
  09-22 (y)) in the middle of the visible range rather than near its left edge. **RULING** — it is a
  presentation choice, not a bug fix.

## 3. ⚠ TWO COPY ITEMS I DID NOT APPLY BLIND
- **C1 — his Keeling rewrite DROPS a claim the current text exists to make.** His version ends
  *"...it is not an abstract regression, it can only adjust variables that represent physical
  values"* — true, good, and worth keeping. But it drops *"what it is never told is how the emitted
  carbon divides between air, land and ocean — that comes out of the bookkeeping, and it is the
  next tab"*, which is (a) the one honest "not fitted" claim the panel can make (the code comment
  above it says exactly that: *"The honest claim is narrower and still worth making"*) and (b) the
  hand-off that sends the reader to the next tab. **Proposed: take his sentence AND keep the
  divides/next-tab clause.** Drafted in the implementation; overrule me if you meant to cut it.
- **C5 — he may be right, and the reason matters.** The caveat explains that under
  `warming_feedback` off, the climate still warms and only the carbon cycle's response is removed.
  He says that is irrelevant "because in this model we only care about warming because of its
  carbon cycle effects." ⚠ **But that is exactly what makes the caveat load-bearing**: a reader who
  does not know the temperature is PRESCRIBED will read "switch off the warming feedback" as
  "switch off the warming". Proposed: keep the distinction, drop the "so the two effects can be
  told apart" tail, which is the part that reads as pedantry.

## 4. Q — measure or answer, do not edit
- **Q1 (#7b) — why is the model's land sink larger than GCB's in the last decade?** He asks for this
  twice (also #15). Gate 7 PASSES (land 3.09 vs GCB), so this is about the app's own GCB bar panel
  and the recent decade specifically, not a gate failure.
- **Q2 (#14) — is the Revelle effect on year-to-year SCATTER really that large?** He is surprised.
  ⇒ [[implausible result = bug]] applies: **measure before reassuring.**
- **Q3 (#15) — could forest regrowth be separated from CO₂ fertilisation, and would it close the GCB
  gap?** ⛔ Structural: in this model fertilisation IS the land sink (`R/mechanisms.R` fertilisation
  caveat). **RULING.**
- **Q4 (#18) — is >half the wobble really the emissions record's own year-to-year shape?** He is
  surprised, expecting emissions to be smooth apart from COVID / the USSR / 2008. ⚠ The claim is
  **asserted prose in `R/mechanisms.R`'s `enso$caveat`, not a computed takeaway** — I could not find
  a measurement behind it. **This one is a candidate app error and should be measured first.**
- **Q5 (#25) — anything more recent than Joos et al. (2013) for the pulse response?** A literature
  question; the answer belongs on Known-issues card 5.

## 5. Rulings I need
1. **F5** — the 1900–2150 span (it moves the splice into mid-frame).
2. **F3** — the ENSO/warming temperature split (blocked on a decomposition the repo lacks).
3. **Q3** — forest regrowth as a separate sink from fertilisation (a model change).
4. **C1 / C5** — the two copy items in §3, where his edit and the panel's purpose disagree.
5. **Priority order for F1, F2, F4.**

---

## 6. FOUND WHILE IMPLEMENTING — two things the comments did not ask about

### ⛔⛔ Q4's experiment CANNOT BE RUN IN THE APP, which strengthens his suspicion
The `enso` caveat claims: *"even with El Niño, the warming response and the volcanic light effect
**ALL switched off**, more than half the model's wobble remains."* But the switch is
`radioButtons("c_mech", ...)` (`app/ui.R:230`) — **single-select, one mechanism at a time.** The
reader cannot switch three off at once, and neither can the app.
⇒ The sentence asserts the result of a **three-way-off experiment the UI cannot perform**, and I
could find no computed source for the "more than half" figure — it is prose in `R/mechanisms.R`,
not a takeaway derived from a run. ⚠ Marcus's surprise (#18) is therefore pointed at a number with
**no visible provenance**. **Measure it before defending it** — and if it holds, consider whether a
claim the reader cannot reproduce in the app belongs in the app at all.

### ⚠ THE COPY RATCHET FIRED, and only one of its two hits was real
`test-app-review-copy.R`'s "all 28 of Marcus's 2026-09-22 copy items are still applied" went RED:
- **K2 was a FALSE ALARM OF MY OWN MAKING.** My C1 rewrite wrapped "an ENSO index and volcanic
  aerosol" across two `paste()` string literals, so the contiguous phrase vanished from the source
  blob although the rendered sentence was unchanged. ⇒ **The ratchet is sensitive to LINE WRAPPING
  inside `paste()`, not just to wording.** Fixed by re-wrapping, not by touching the test.
- **W4 was a REAL supersession.** Marcus's C3 replaces the 09-22 airborne-fraction wording
  wholesale, so the item's required phrase ("not a clean score for the sinks") is gone *on his own
  instruction*. ⛔ **I edited the ratchet entry** — kept the pre-09-22 phrase as still-forbidden,
  moved the required phrase to C3's — and recorded the reason in the test. **This is a test I
  changed while it was correctly failing; flagging it explicitly so Marcus can overrule.** The
  alternative (leaving it red) would pin the app to a superseded round.
