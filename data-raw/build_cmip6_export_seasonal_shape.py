# =====================================================================
# build_cmip6_export_seasonal_shape.py -- THE SEASONAL SHAPE OF OCEAN EXPORT
#   PRODUCTION, per hemisphere and per BAND (the LS column vs the HS box),
#   from the CMIP6 historical ensemble's monthly sinking-POC flux at 100 m
#   -> data-raw/downloads/cmip6_export_seasonal_shape.{npz,csv,_meta.json}
#      -> data/obs_export_seasonal_shape_cmip6.rds (build_export_seasonal_prior.R)
#
# WHY THIS EXISTS (2026-09-16). O5 (the seasonal export, prereg 09-15 f) gave
# the model a summer-peaked factor on every pump limb, s_h(t) = 1 + amp x
# sigma_h x sin(2 pi (t - (3.5 + lag)/12)), and its probe passed with amp
# PINNED at 1 and lag scanned. Before `pump_seas_amp` / `pump_seas_lag` can
# enter the table they need a PRIOR with a SOURCE. The mean export's own source
# (Nowicki 2022, data/obs_pump_export_prior.rds) is ANNUAL -- its release has no
# time axis (checked 09-15) -- so the seasonality needs another product.
#
# WHY CMIP6 epc100. The same class of evidence Marcus accepted for the LAND
# NPP shape (2026-08-27; build_cmip6_npp_seasonal_shape.py): process models, no
# satellite in the chain, open, and -- uniquely among the candidates -- the
# QUANTITY ITSELF (sinking POC flux), not an NPP proxy with a seasonal e-ratio
# on top. 21 models carry epc100 Omon historical in the Pangeo catalogue.
# ⚠ WHAT THIS IS NOT. These are MODELS, not observations; the product may NOT
# be described as an observational constraint (the 08-27 acceptance is the
# provenance). The satellite NPP climatology (Oregon State) is the
# observational CROSS-CHECK, a LOWER bound on export seasonality; the SOM-FFN
# SO pCO2 seasonal amplitude (data/obs_so_pco2_seas_amp.rds) is the
# out-of-sample RESULT row.
#
# THE HORIZON. epc100 is the flux at 100 m; the model's export leaves the ML
# base (h_ml 65 m at the canonical; Nowicki's euphotic depth 68 m). Sinking at
# tens of m/day, the 35 m difference lags the flux by days, not weeks, and
# attenuates it by the Martin factor uniformly -- the SHAPE (relative
# amplitude, phase) is what is read, and it survives that.
#
# THE BANDS follow the model's geometry: LS = |lat| < HS_LAT (the diffusive
# column, both surface boxes), HS = |lat| >= HS_LAT (the HILDA high-latitude
# box), per hemisphere; HS_LAT is the model's 57.14 deg (R/model.R, hs_frac
# 0.16 on a uniform sphere). Cells are weighted by areacello (Ofx); a model
# without it on the same grid is SKIPPED and said so (no analytic fallback on
# a curvilinear ocean grid). Ice is not masked: export under ice is ~0 in the
# models themselves.
#
# THE ESTIMATOR mirrors the model's factor: the first harmonic of the
# 1995-2014 monthly climatology at month CENTRES, amp_rel = |harmonic| / mean,
# peak month (decimal, from 1 Jan), and the model's own lag convention:
#   NH peaks at 6.5 + lag  (mid-July at lag 0)  ->  lag = peak - 6.5
#   SH peaks at 0.5 + lag  (mid-January)        ->  lag = peak - 0.5 (mod 12, in [-6, 6))
# Also recorded: the rectification ratio (peak month / mean, a sine has 1 +
# amp) so a reader can see how far a bloom is from a sinusoid, and the fraction
# of the seasonal variance the first harmonic carries.
#
# Usage:  python data-raw/build_cmip6_export_seasonal_shape.py
#         (needs /tmp/pangeo-cmip6.csv or PANGEO_CAT set; anonymous GCS)
# =====================================================================
import csv, json, os, warnings
import numpy as np, xarray as xr
warnings.filterwarnings("ignore")

CAT       = os.environ.get("PANGEO_CAT", "/tmp/pangeo-cmip6.csv")
OUT_NPZ   = "data-raw/downloads/cmip6_export_seasonal_shape.npz"
OUT_CSV   = "data-raw/downloads/cmip6_export_seasonal_shape.csv"
OUT_META  = "data-raw/downloads/cmip6_export_seasonal_shape_meta.json"
YR0, YR1  = 1995, 2014
PREF_MEM  = "r1i1p1f1"
HS_LAT    = 57.14                     # deg, the model's HS boundary (hs_frac 0.16, uniform sphere)
VAR, TABLE = "epc100", "Omon"
# epc100 is in mol m-2 s-1 (CMIP6 Omon); PgC/yr = mol/s x 12.011 g/mol x s/yr x 1e-15.
# ⚠ The first pass (09-16) used the NPP script's kg factor and printed means 83x too
# large; the SHAPE was unaffected (unit-free). The units attribute is now GATED.
MOL_C_G = 12.011
MOL_S_TO_PGC_YR = MOL_C_G * 1e-15 * 86400 * 365.25
EXPECT_UNITS = ("mol m-2 s-1",)

rows = list(csv.DictReader(open(CAT)))
def pick(var, table, source, exp=None, grid=None):
    c = [x for x in rows if x["variable_id"] == var and x["table_id"] == table and x["source_id"] == source
         and (exp is None or x["experiment_id"] == exp) and (grid is None or x["grid_label"] == grid)]
    if not c: return None
    c.sort(key=lambda x: (x["member_id"] != PREF_MEM, x["member_id"], x["grid_label"] != "gn", x["grid_label"]))
    return c[0]
def open_z(z): return xr.open_zarr(z, consolidated=True, storage_options={"token": "anon"})
def latlon(ds, da):
    for cand in ("latitude", "lat", "nav_lat"):
        if cand in ds.coords or cand in ds.variables:
            L = ds[cand].values; break
    else: raise KeyError("no latitude coordinate")
    if L.ndim == 1:                      # rectilinear: broadcast to the field's last two dims
        L = np.broadcast_to(L[:, None], da.shape[-2:])
    return np.asarray(L, float)
def harmonic(clim):
    mc = (np.arange(12) + 0.5) / 12.0
    a = 2 / 12 * np.sum(clim * np.cos(2 * np.pi * mc)); b = 2 / 12 * np.sum(clim * np.sin(2 * np.pi * mc))
    mean = clim.mean(); amp = np.hypot(a, b)
    peak = (np.arctan2(b, a) / (2 * np.pi) * 12) % 12          # months from 1 Jan, decimal
    resid = clim - mean - (a * np.cos(2 * np.pi * mc) + b * np.sin(2 * np.pi * mc))
    var_tot = np.sum((clim - mean) ** 2); frac1 = 1 - np.sum(resid ** 2) / var_tot if var_tot > 0 else np.nan
    return dict(mean=float(mean), amp_rel=float(amp / mean) if mean > 0 else np.nan, peak_month=float(peak),
                rect=float(clim.max() / mean) if mean > 0 else np.nan, frac_h1=float(frac1))
def lag_of(h, peak):
    lag = (peak - (6.5 if h == "NH" else 0.5) + 6) % 12 - 6      # in [-6, 6)
    return float(lag)

models = sorted(set(x["source_id"] for x in rows if x["variable_id"] == VAR and x["table_id"] == TABLE and x["experiment_id"] == "historical"))
print(f"{len(models)} models with {VAR} {TABLE} historical", flush=True)
out, meta = {}, []
for m in models:
    try:
        r = pick(VAR, TABLE, m, "historical"); ds = open_z(r["zstore"])
        da = ds[VAR].sel(time=slice(f"{YR0}-01-01", f"{YR1}-12-30"))
        if da.time.size < 12: print(f"  {m:20s} SKIP: {da.time.size} months", flush=True); continue
        un = str(ds[VAR].attrs.get("units", "")).strip()
        if un not in EXPECT_UNITS: print(f"  {m:20s} SKIP: units '{un}' not in {EXPECT_UNITS}", flush=True); continue
        ar = pick("areacello", "Ofx", m, grid=r["grid_label"])
        if ar is None: print(f"  {m:20s} SKIP: no areacello on grid {r['grid_label']}", flush=True); continue
        A = np.asarray(open_z(ar["zstore"])["areacello"].values, float)
        if A.shape != da.shape[-2:]: print(f"  {m:20s} SKIP: areacello {A.shape} vs field {da.shape[-2:]}", flush=True); continue
        LAT = latlon(ds, da)
        v = da.values; v = np.where(np.isfinite(v), v, 0.0); A = np.nan_to_num(A)
        if v.mean() < 0: print(f"  {m:20s} REJECT: negative export (sign convention)", flush=True); continue
        mon = da["time.month"].values
        rec = dict(model=m, member=r["member_id"], grid=r["grid_label"], nmonths=int(da.time.size), units=un)
        for h, hs in (("NH", LAT > 0), ("SH", LAT < 0)):
            for band, bs in (("LS", np.abs(LAT) < HS_LAT), ("HS", np.abs(LAT) >= HS_LAT)):
                W = A * (hs & bs)
                tot = np.einsum("tij,ij->t", v, W) * MOL_S_TO_PGC_YR             # PgC/yr
                clim = np.array([tot[mon == k].mean() for k in range(1, 13)])
                out[f"{h}_{band}|{m}"] = clim
                hh = harmonic(clim); hh["lag_mo"] = lag_of(h, hh["peak_month"])
                rec[f"{h}_{band}"] = hh
        meta.append(rec)
        print(f"  {m:20s} ok  " + "  ".join(f"{k} {rec[k]['mean']:.2f} PgC/yr amp {rec[k]['amp_rel']:.2f} pk {rec[k]['peak_month']:4.1f} lag {rec[k]['lag_mo']:+4.1f}"
                                         for k in ("NH_LS", "SH_LS", "NH_HS", "SH_HS")), flush=True)
    except Exception as e:
        print(f"  {m:20s} FAIL: {type(e).__name__}: {str(e)[:100]}", flush=True)
np.savez(OUT_NPZ, meta=json.dumps(meta), **out)
lines = ["series,month,value"] + [f"{k},{i+1},{v[i]:.10g}" for k, v in out.items() for i in range(12)]
open(OUT_CSV, "w").write("\n".join(lines) + "\n"); open(OUT_META, "w").write(json.dumps(meta, indent=1))
print(f"\nwrote {OUT_NPZ} / {OUT_CSV} / {OUT_META}: {len(meta)} models")
if meta:
    for k in ("NH_LS", "SH_LS", "NH_HS", "SH_HS"):
        a = np.array([x[k]["amp_rel"] for x in meta]); l = np.array([x[k]["lag_mo"] for x in meta]); rc = np.array([x[k]["rect"] for x in meta])
        print(f"{k}: amp_rel median {np.nanmedian(a):.2f} [IQR {np.nanpercentile(a,25):.2f}, {np.nanpercentile(a,75):.2f}]  lag median {np.nanmedian(l):+.1f} mo [{np.nanpercentile(l,25):+.1f}, {np.nanpercentile(l,75):+.1f}]  peak/mean median {np.nanmedian(rc):.2f}")
