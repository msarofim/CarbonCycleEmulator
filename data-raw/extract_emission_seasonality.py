#!/usr/bin/env python3
# =====================================================================
# extract_emission_seasonality.py -- REVIEW ITEM 5c, the heavy-data step.
#
# WHY THIS EXISTS. ccx_build_forcing() spreads ANNUAL fossil and land-use
# emissions across months with a smooth annual-conserving interpolation, i.e.
# with NO within-year seasonal cycle at all. Real emissions have one, and the
# model's single free NEP amplitude (`seas_amp_NH`) absorbs the difference:
# moving seas_amp_NH 12 -> 13 GtC/yr, an 8.3 % change and about the size of the
# omitted input seasonality, is worth 101 log-units in the objective, of which
# co2_seasonal_MLO supplies 131.5. So the fitted land seasonal amplitude is
# currently paying for an input error.
#
# This script does the parts that need h5py/openpyxl and a gigabyte of input,
# and writes two SMALL csvs that data-raw/build_emission_seasonality.R turns
# into data/forcing_emission_seasonality.rds. Same split as the GLODAPv2 build:
# the bulk inputs are gitignored, the extraction is scripted and documented, and
# a fresh clone re-runs this before the R build.
#
#   INPUTS (both gitignored, see MANIFEST.csv for URLs and checksums)
#     data-raw/downloads/gfed/GFED4.1s_YYYY.hdf5   16 files, 2001-2016, ~1.2 GB
#     data-raw/downloads/EDGARv432_CO2_1970-2012m.xlsx              ~26 MB
#
#   OUTPUTS (small, committed)
#     data-raw/downloads/seasonality_fire.csv
#     data-raw/downloads/seasonality_fossil.csv
#
# ---------------------------------------------------------------------
# THREE METHODOLOGICAL CHOICES, none silently resolved.
#
# 1. WHICH FIRES ARE LAND-USE CHANGE? E_LUC is not "fire". GFED partitions
#    carbon into SAVA / BORF / TEMF / DEFO / PEAT / AGRI. Savanna and
#    agricultural-waste burning are RECURRING cycles whose regrowth returns the
#    carbon within a year or two -- they are not land-use CHANGE and GCB's E_LUC
#    does not carry them as a net source. Boreal and temperate forest fire is
#    mostly natural wildfire. The land-use-change subset is DEFO + PEAT
#    (deforestation, degradation, and peat). BOTH are written out, so the choice
#    is visible and the sensitivity is one column away rather than a re-run.
#
# 2. CLIMATOLOGY PERIOD 2001-2016. GFED4.1s's own header says estimates from
#    2017 are extrapolated from active fires, "carry a larger uncertainty" and
#    "are not suitable for trend analyses" -- so the beta years are excluded.
#    2001 is the start of the MODIS burned-area record the product is built on;
#    1997-2000 use a different calibration and are excluded for homogeneity.
#
# 3. FOSSIL SECTORS. EDGAR's IPCC-1996 codes. GCB's "fossil" is fuel combustion
#    + cement + flaring, so category 1 (Energy: 1A combustion, 1B fugitive) and
#    2A (mineral products, which is where cement sits) are kept; 4 (agriculture),
#    5 (LULUCF) and 6 (waste) are dropped. Kept and dropped totals are both
#    printed so the split can be checked rather than trusted.
#
# WHAT THIS SCRIPT DOES NOT DECIDE. It writes hemispheric monthly climatologies.
# Whether they are applied as a fixed shape or a time-varying one, and how the
# annual totals are re-conserved afterwards, is the R build script's business.
# =====================================================================

import csv
import os
import sys

import h5py
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DL = os.path.join(ROOT, "data-raw", "downloads")

GFED_YEARS = range(2001, 2017)          # see choice 2
GFED_LUC_PARTS = ("DEFO", "PEAT")       # see choice 1
GFED_ALL_PARTS = ("SAVA", "BORF", "TEMF", "DEFO", "PEAT", "AGRI")
MONTHS = [f"{m:02d}" for m in range(1, 13)]

# EDGAR IPCC-1996 top-level codes kept as "fossil" -- see choice 3.
EDGAR_KEEP_PREFIX = ("1A", "1B", "2A")
EDGAR_YEARS = range(1970, 2013)


# ---------------------------------------------------------------------
# 1. FIRE -- GFED4.1s
# ---------------------------------------------------------------------
def extract_fire():
    rows = []
    for yr in GFED_YEARS:
        path = os.path.join(DL, "gfed", f"GFED4.1s_{yr}.hdf5")
        if not os.path.exists(path):
            sys.exit(f"missing {path} -- see MANIFEST.csv for the URL")
        with h5py.File(path, "r") as f:
            lat = f["lat"][:]
            area = f["ancill/grid_cell_area"][:]
            nh = lat > 0
            for mi, mm in enumerate(MONTHS, start=1):
                C = f[f"emissions/{mm}/C"][:]            # g C / m^2 / month
                gC = C * area                            # g C / month
                # partitioning/C_XXXX are FRACTIONS of C in that month
                luc = np.zeros_like(gC)
                for p in GFED_LUC_PARTS:
                    luc += gC * f[f"emissions/{mm}/partitioning/C_{p}"][:]
                rows.append(dict(
                    year=yr, month=mi,
                    all_NH=gC[nh].sum(), all_SH=gC[~nh].sum(),
                    luc_NH=luc[nh].sum(), luc_SH=luc[~nh].sum()))
        print(f"  GFED {yr} done", flush=True)

    out = os.path.join(DL, "seasonality_fire.csv")
    with open(out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    # --- console receipts, so the numbers can be sanity-checked here ---
    a = np.array([[r["all_NH"], r["all_SH"], r["luc_NH"], r["luc_SH"]] for r in rows])
    tot = a.sum(axis=0) / len(GFED_YEARS) / 1e15         # PgC/yr
    print(f"\nGFED4.1s {min(GFED_YEARS)}-{max(GFED_YEARS)} mean, PgC/yr:")
    print(f"  all fire   NH {tot[0]:.3f}  SH {tot[1]:.3f}  global {tot[0]+tot[1]:.3f}")
    print(f"  DEFO+PEAT  NH {tot[2]:.3f}  SH {tot[3]:.3f}  global {tot[2]+tot[3]:.3f}")
    print(f"  LUC share of all fire: {(tot[2]+tot[3])/(tot[0]+tot[1]):.3f}")
    print(f"wrote {out}")


# ---------------------------------------------------------------------
# 2. FOSSIL -- EDGAR v4.3.2 monthly, aggregated to hemispheres by country
# ---------------------------------------------------------------------
def extract_fossil(hemi_map):
    import openpyxl
    path = os.path.join(DL, "EDGARv432_CO2_1970-2012m.xlsx")
    if not os.path.exists(path):
        sys.exit(f"missing {path} -- see MANIFEST.csv for the URL")
    wb = openpyxl.load_workbook(path, read_only=True)
    ws = wb[wb.sheetnames[0]]

    acc = {}          # (year, month) -> [NH, SH]
    kept = dropped = 0.0
    unknown = {}
    header_seen = False
    for row in ws.iter_rows(values_only=True):
        if not header_seen:
            header_seen = row and row[0] == "IPCC-Annex"
            continue
        if row is None or row[2] is None or row[6] is None:
            continue
        iso, ipcc, year = row[2], str(row[4]), int(row[6])
        vals = [v if isinstance(v, (int, float)) else 0.0 for v in row[7:19]]
        tot = sum(vals)
        if not ipcc.startswith(EDGAR_KEEP_PREFIX):
            dropped += tot
            continue
        kept += tot
        h = hemi_map.get(iso)
        if h is None:
            unknown[iso] = unknown.get(iso, 0.0) + tot
            h = "NH"                      # see the note in the R build script
        for mi, v in enumerate(vals, start=1):
            k = (year, mi)
            if k not in acc:
                acc[k] = [0.0, 0.0]
            acc[k][0 if h == "NH" else 1] += v

    out = os.path.join(DL, "seasonality_fossil.csv")
    with open(out, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["year", "month", "fossil_NH_Gg", "fossil_SH_Gg"])
        for (yr, mi) in sorted(acc):
            w.writerow([yr, mi, acc[(yr, mi)][0], acc[(yr, mi)][1]])

    print(f"\nEDGAR v4.3.2 CO2, {min(EDGAR_YEARS)}-{max(EDGAR_YEARS)}:")
    print(f"  kept (1A/1B/2A) {kept/1e6:.2f} Gt CO2 ; dropped {dropped/1e6:.2f} Gt CO2"
          f"  ({kept/(kept+dropped):.3f} kept)")
    if unknown:
        top = sorted(unknown.items(), key=lambda kv: -kv[1])[:10]
        share = sum(unknown.values()) / kept
        # NOT an error: SH_ISO lists only countries with a meaningful southern
        # share, so everything else falls through to the NH default BY DESIGN.
        # The list is printed so a large emitter cannot be defaulted silently --
        # eyeball it, every name should be unambiguously northern.
        print(f"  defaulted to NH: {len(unknown)} ISO codes, {share:.4f} of kept"
              f" mass. Largest (all should be northern): {[t[0] for t in top]}")
    nh = sum(v[0] for v in acc.values()); sh = sum(v[1] for v in acc.values())
    print(f"  NH share of kept fossil CO2: {nh/(nh+sh):.4f}"
          f"  (ccx_build_forcing's FORC_FOSS_NH_SHARE is 0.95)")
    print(f"wrote {out}")


# ---------------------------------------------------------------------
# Country -> hemisphere. A GEOGRAPHIC JUDGMENT, so it is explicit and
# auditable rather than buried in a lookup nobody reads. Only countries with a
# meaningful SOUTHERN share are listed; everything else defaults to NH, and the
# unmapped mass is printed above so the default cannot hide a large emitter.
# Straddlers are assigned by where the POPULATION and industry sit, not by the
# centroid: Indonesia's emissions are Java-dominated (south), Brazil's are
# Sao Paulo / Rio (south), Kenya's Nairobi is ~1 S but its emissions are small.
# ---------------------------------------------------------------------
SH_ISO = {
    "AUS", "NZL", "ARG", "CHL", "URY", "PRY", "BOL", "PER", "BRA",
    "ZAF", "ZWE", "ZMB", "MOZ", "AGO", "NAM", "BWA", "MWI", "MDG", "TZA",
    "IDN", "PNG", "FJI", "SLB", "VUT", "TLS", "COD", "COG", "GAB",
    "LSO", "SWZ", "MUS", "COM", "SYC", "WSM", "TON", "NCL", "PYF",
}


def main():
    hemi = {iso: "SH" for iso in SH_ISO}
    what = sys.argv[1] if len(sys.argv) > 1 else "both"
    if what in ("fire", "both"):
        extract_fire()
    if what in ("fossil", "both"):
        extract_fossil(hemi)


if __name__ == "__main__":
    main()
