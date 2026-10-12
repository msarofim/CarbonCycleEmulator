import sys, numpy as np, pandas as pd
sys.path.insert(0, "/Users/MarcusMarcus/Documents/2026/CodeProjects/FaIRtoFrEDI/scripts")
import run_fair_vv_pulse_grid_for_ccx as G
import run_fair_vv_for_ccx as vv
from fair.io import read_properties
m, y = "H", 2030
table = vv.resolve_all(); emis, scen = table[m]
params = vv.CAL_DIR / f"calibrated_constrained_parameters_{vv.CALIB_VERSION}.csv"
sf = vv.CAL_DIR / f"species_configs_properties_{vv.CALIB_VERSION}.csv"
df = pd.read_csv(params, index_col=0); configs = df.index.tolist(); sp, pr = read_properties(str(sf))
common = (m, emis, scen, sp, pr, configs, df, params, sf)
base = G.build_arm(*common, None, 0.0); pu = G.build_arm(*common, y, G.PULSE_GTCO2)
yrs = base["years"]; af = (pu["air"] - base["air"]) / G.PULSE_GTCO2; dT = pu["temp"] - base["temp"]
post = yrs > y
over = af > 1
print("timebounds with any AF>1:", yrs[over.any(axis=1)][:5], "...", yrs[over.any(axis=1)][-5:] if over.any() else None)
print("configs ever >1:", int(over.any(axis=0).sum()), "of", len(configs))
i = np.unravel_index(np.argmax(np.where(post[:, None], af, -1)), af.shape)
print("max AF", af[i], "at year", yrs[i[0]], "config", configs[i[1]])
print("AF at y+1 (max over configs):", af[yrs == y + 1].max(), " AF at y+2:", af[yrs == y + 2].max())
rT = df["iirf_temperature"] if "iirf_temperature" in df.columns else None
if rT is not None:
    ever = over.any(axis=0)
    print("iirf_temperature: configs >1 median %.3f vs others median %.3f" % (rT.values[ever].median() if hasattr(rT.values,'median') else np.median(rT.values[ever]), np.median(rT.values[~ever])))
print("pulse warming at max-AF config/time: %.3f K; background T there %.2f K" % (dT[i], base["temp"][i] - base["temp"][(yrs>=1850)&(yrs<=1900), i[1]].mean()))
# AF trajectory of the max config
c = i[1]
for yy in [y+1, y+5, y+20, y+50, y+100, y+150, y+200, y+250]:
    k = np.where(yrs == yy)[0]
    if len(k): print(f"  cfg {configs[c]} t={yy}: AF {af[k[0], c]:.4f}  dT {dT[k[0], c]:.3f} K")
np.save("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/g5/maxcfg.npy", np.array([c]))
