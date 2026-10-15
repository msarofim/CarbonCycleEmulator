"""
fair_vv_co2_spread.py -- FaIR 2.2.4 (calib 1.6.0)'s CO2 CONCENTRATION SPREAD across its 841
configurations on the seven van Vuuren markers, for the comparison with CarboTope's Futures band.

WHY. Marcus 2026-10-15: "How does CarboTope's carbon uncertainty compare to FaIR's?", then "Run
both". FaIRtoFrEDI/scripts/run_fair_vv_for_ccx.py, which made the FaIR scenario runs the app
draws, writes the configuration MEAN of CO2 only (its line 162), so FaIR's CO2 spread on these
scenarios was never stored.

HOW. The exporter is IMPORTED read-only (its paths, constants, marker table and new_fair()), and
its run_one() body is repeated up to f.run(), so the runs are the exporter's runs. Nothing in
FaIRtoFrEDI or in CarboTope's data-raw/ is written. Only this directory is.

GATES.
  G1 identity: the configuration mean of CO2 and of GMST from these runs equals the exporter's
     stored CSV (data-raw/downloads/fair_v160_vv/fair_v160_vv<M>.csv) to G1_TOL. That file is
     another script's output, so the gate cannot compare this script with itself.
  G1m mutation: the same comparison against a DIFFERENT marker's file must fail (power check).
  G2 ordering: p05 <= p50 <= p95 everywhere, and p05 <= mean <= p95.

Usage (CarbonCycleEmulator repo root):
    ~/climate-env/bin/python -I outputs/diagnostics/carbon_spread_20261015/fair_vv_co2_spread.py
No RNG in this script. FaIR's internal variability (stochastic_run, as the exporter leaves it)
uses the posterior's per-config seed column, identical in every run.
"""
from pathlib import Path
import hashlib
import importlib.util
import platform
import subprocess
import sys

import numpy as np
import pandas as pd
from fair.interface import fill, initialise
from fair.io import read_properties

# ---- named constants: every label, window and path derives from these ----
HERE = Path(__file__).resolve().parent
CCX_ROOT = HERE.parents[2]
FTF_ROOT = Path.home() / "Documents/2026/CodeProjects/FaIRtoFrEDI"
EXPORTER = FTF_ROOT / "scripts" / "run_fair_vv_for_ccx.py"
PROBS = (5, 50, 95)                       # percent; the app's FaIR bands are 5-95 %
G1_TOL = 1e-9                             # ppm / K: same runs, so roundoff only
KEY_YEARS = (2050, 2100, 2150, 2200, 2300)
OUT_CSV = HERE / "fair_vv_co2_spread.csv"
OUT_KEY = HERE / "fair_vv_co2_spread_key_years.csv"
OUT_PROV = HERE / "fair_vv_co2_spread_provenance.txt"
DRIVER = "outputs/diagnostics/carbon_spread_20261015/fair_vv_co2_spread.py"


def load_exporter():
    spec = importlib.util.spec_from_file_location("run_fair_vv_for_ccx", EXPORTER)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)          # top level is constants + defs; main() is guarded
    return mod


def git_short(root, path=None):
    cmd = ["git", "-C", str(root), "log", "-1", "--format=%h"] + ([ "--", str(path)] if path else [])
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()


def git_dirty(root, path):
    out = subprocess.run(["git", "-C", str(root), "status", "--porcelain", "--", str(path)],
                         capture_output=True, text=True).stdout.strip()
    return "yes" if out else "no"


def run_marker(ex, marker, emis, scen_name, species, properties, configs, df_configs, params, species_file):
    """The exporter's run_one() up to f.run(), unchanged; returns (years, temp, co2) per config."""
    prescribed = [s for s in species if properties[s]["input_mode"] == "forcing"]
    forcing_file = ex.CAL_DIR / f"volcanic_solar_{marker}.csv"
    key = f"vv{marker}"

    t = ex.new_fair("all", species, properties, configs)
    t.fill_from_csv(emissions_file=None, forcing_file=str(forcing_file))
    forc_arr = t.forcing.sel(scenario="all").values
    del t
    e = ex.new_fair(scen_name, species, properties, configs)
    e.fill_from_csv(emissions_file=str(emis), forcing_file=None)
    emis_arr = e.emissions.sel(scenario=scen_name).values
    del e

    idx = {s: i for i, s in enumerate(species)}
    blank = [s for s in prescribed if np.isnan(forc_arr[:, :, idx[s]]).all()]
    if blank:
        sys.exit(f"ERROR: {forcing_file.name} has no rows for prescribed {blank}")
    ed = [s for s in species if properties[s]["input_mode"] == "emissions"]
    miss = sorted({s for s in ed if np.isnan(emis_arr[:, :, idx[s]]).any()})
    if miss:
        sys.exit(f"ERROR: {emis.name} has NaN for emissions-driven {miss}")

    f = ex.new_fair(key, species, properties, configs)
    f.emissions.loc[dict(scenario=key)] = emis_arr
    f.forcing.loc[dict(scenario=key)] = forc_arr
    f.fill_species_configs(str(species_file))
    f.override_defaults(str(params))
    for sp in prescribed:
        col = f"forcing_scale[{sp}]"
        if col not in df_configs.columns:
            sys.exit(f"ERROR: prescribed {sp!r} has no {col}; would run UNSCALED")
        fill(f.forcing, f.forcing.sel(specie=sp) * df_configs[col].values.squeeze(), specie=sp)

    initialise(f.concentration, f.species_configs["baseline_concentration"])
    initialise(f.forcing, 0)
    initialise(f.temperature, 0)
    initialise(f.cumulative_emissions, 0)
    initialise(f.airborne_emissions, 0)
    initialise(f.ocean_heat_content_change, 0)
    f.run(progress=False)

    years = f.timebounds.astype(int)
    pi = (years >= ex.BASELINE_START) & (years <= ex.BASELINE_END)
    temp = f.temperature.sel(layer=0).values[:, 0, :]
    temp = temp - temp[pi, :].mean(axis=0)[None, :]
    co2 = f.concentration.sel(specie="CO2").values[:, 0, :]
    del f
    return years, temp, co2


def main():
    ex = load_exporter()
    table = ex.resolve_all()
    params = ex.CAL_DIR / f"calibrated_constrained_parameters_{ex.CALIB_VERSION}.csv"
    species_file = ex.CAL_DIR / f"species_configs_properties_{ex.CALIB_VERSION}.csv"
    df_configs = pd.read_csv(params, index_col=0)
    configs = df_configs.index.tolist()
    species, properties = read_properties(str(species_file))
    label = f"{ex.MODEL_LABEL} (calib {ex.CALIB_VERSION})"
    print(f"{label}: {len(configs)} configs; exporter {EXPORTER.name} @{git_short(FTF_ROOT, EXPORTER)}")

    rows, gate = [], []
    stored = {m: pd.read_csv(ex.OUT_DIR / f"fair_{ex.TAG}_vv{m}.csv") for m in ex.MARKERS}
    for m in ex.MARKERS:
        emis, scen = table[m]
        years, temp, co2 = run_marker(ex, m, emis, scen, species, properties, configs,
                                      df_configs, params, species_file)
        cm, tm = co2.mean(axis=1), temp.mean(axis=1)
        s = stored[m]
        if not np.array_equal(s["year"].values, years):
            sys.exit(f"G1 FAIL vv{m}: year axis differs from the stored file")
        d_co2 = float(np.max(np.abs(cm - s["co2_ppm"].values)))
        d_t = float(np.max(np.abs(tm - s["gmst_C"].values)))
        other = ex.MARKERS[(ex.MARKERS.index(m) + 1) % len(ex.MARKERS)]
        d_mut = float(np.max(np.abs(cm - stored[other]["co2_ppm"].values)))
        gate.append(dict(marker=m, max_abs_co2_ppm=d_co2, max_abs_gmst_K=d_t,
                         mutation_vs=other, mutation_max_abs_co2_ppm=d_mut))
        print(f"  vv{m:3s} G1 |mean CO2 - stored| {d_co2:.3g} ppm, |mean GMST - stored| {d_t:.3g} K; "
              f"G1m vs vv{other}: {d_mut:.3g} ppm")
        if not (d_co2 <= G1_TOL and d_t <= G1_TOL):
            sys.exit(f"G1 FAIL vv{m}: these runs are not the exporter's (tol {G1_TOL})")
        if not d_mut > G1_TOL:
            sys.exit(f"G1m FAIL vv{m}: the identity gate cannot tell vv{m} from vv{other}")
        q = np.percentile(co2, PROBS, axis=1)
        if not (np.all(q[0] <= q[1]) and np.all(q[1] <= q[2]) and np.all(q[0] <= cm) and np.all(cm <= q[2])):
            sys.exit(f"G2 FAIL vv{m}: percentiles out of order")
        rows.append(pd.DataFrame({
            "scenario": f"vv{m}", "year": years,
            "co2_mean": cm, "co2_p05": q[0], "co2_p50": q[1], "co2_p95": q[2],
            "co2_sd": co2.std(axis=1, ddof=1)}))

    out = pd.concat(rows, ignore_index=True)
    commit = git_short(CCX_ROOT)
    out["provenance"] = (f"{label}, {len(configs)} configs, van Vuuren markers via {EXPORTER.name}; "
                         f"{DRIVER} @{commit}; ppm; see {OUT_PROV.name}")
    out.to_csv(OUT_CSV, index=False)
    key = out[out["year"].isin(KEY_YEARS)].drop(columns="provenance").copy()
    key["width_5_95"] = key["co2_p95"] - key["co2_p05"]
    key.to_csv(OUT_KEY, index=False, float_format="%.2f")

    lines = [
        f"driver: {DRIVER} @{commit}",
        f"model: {label}; configs: {len(configs)} ({params.name} sha256 "
        f"{hashlib.sha256(params.read_bytes()).hexdigest()})",
        f"runs: {EXPORTER.relative_to(FTF_ROOT.parent)} @{git_short(FTF_ROOT, EXPORTER)} "
        f"(uncommitted changes: {git_dirty(FTF_ROOT, EXPORTER)}), imported read-only; run_one() body repeated to f.run()",
        f"emissions: {ex.EMIS_DIR.relative_to(FTF_ROOT.parent)}; forcing: {ex.CAL_DIR.name}/volcanic_solar_<M>.csv",
        f"span: {ex.START_YEAR}-{ex.END_YEAR - 1} (timebounds); GMST baseline {ex.BASELINE_START}-{ex.BASELINE_END}",
        f"statistics across configs: mean, percentiles {PROBS} (numpy default linear), sd (ddof 1); units ppm",
        "rng: none in this script; FaIR stochastic_run as the exporter leaves it (per-config seed column)",
        f"gate G1 (tol {G1_TOL}): config mean CO2 and GMST equal the exporter's stored CSVs in "
        f"data-raw/downloads/fair_{ex.TAG}_vv/",
        "gate G1m: the same comparison against the next marker's file must exceed the tolerance",
        "gate G2: p05 <= p50 <= p95 and p05 <= mean <= p95 at every year",
        f"platform: {platform.platform()}; python {platform.python_version()}; numpy {np.__version__}; "
        f"pandas {pd.__version__}",
        "",
        pd.DataFrame(gate).to_string(index=False),
    ]
    OUT_PROV.write_text("\n".join(lines) + "\n")
    print(f"\nwrote {OUT_CSV.name}, {OUT_KEY.name}, {OUT_PROV.name}")
    print(key.to_string(index=False, float_format=lambda v: f"{v:.1f}"))


if __name__ == "__main__":
    main()
