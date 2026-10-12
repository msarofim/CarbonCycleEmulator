import sys, numpy as np, pandas as pd
sys.path.insert(0, "/Users/MarcusMarcus/Documents/2026/CodeProjects/FaIRtoFrEDI/scripts")
import run_fair_vv_pulse_grid_for_ccx as G
import run_fair_vv_for_ccx as vv
from fair.io import read_properties
from fair.interface import fill
m, y = "H", 2030
table = vv.resolve_all(); emis, scen = table[m]
params = vv.CAL_DIR / f"calibrated_constrained_parameters_{vv.CALIB_VERSION}.csv"
sf = vv.CAL_DIR / f"species_configs_properties_{vv.CALIB_VERSION}.csv"
df = pd.read_csv(params, index_col=0); configs = df.index.tolist(); sp, pr = read_properties(str(sf))
# a hook: zero one CO2 feedback term after the posterior is loaded (monkeypatch FAIR.override_defaults)
from fair import FAIR
orig = FAIR.override_defaults
def run_pair(term):
    def patched(self, *a, **k):
        orig(self, *a, **k)
        if term:
            self.species_configs[term].loc[dict(specie="CO2")] = 0.0
    FAIR.override_defaults = patched
    common = (m, emis, scen, sp, pr, configs, df, params, sf)
    b = G.build_arm(*common, None, 0.0); p = G.build_arm(*common, y, G.PULSE_GTCO2)
    FAIR.override_defaults = orig
    af = (p["air"] - b["air"]) / G.PULSE_GTCO2
    yrs = b["years"]; post = yrs > y
    return af, yrs, post
for term in [None, "iirf_temperature", "iirf_uptake", "iirf_airborne"]:
    af, yrs, post = run_pair(term)
    print(f"{str(term):18s} max AF after release {af[post].max():.4f}; configs ever > 1: {int((af[post] > 1).any(axis=0).sum())}; "
          f"mean AF 2130 {af[yrs == 2130].mean():.3f}, 2300 {af[yrs == 2300].mean():.3f}")
