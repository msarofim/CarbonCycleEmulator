# =====================================================================
# build_cmip6_npp_seasonal_shape.py -- THE OBSERVED-ANALOGUE SEASONAL SHAPE OF
#   NH/SH TERRESTRIAL NPP, FROM A PROCESS-MODEL ENSEMBLE
#   -> data/obs_npp_seasonal_shape_cmip6.rds  (via .npz + an R converter)
#
# WHY THIS EXISTS. `SEAS_NPP_AMP_SH` was derived from MOD17A2HGF, and 2026-08-27l
# showed that constant is ONE POINT ON A FLAT RIDGE: across phi = -15.75 to -50
# the shape residual moves 12.9 -> 11.9 % (one point) while the fitted amplitude
# moves 0.97 -> 0.30 (3.2x). Marcus ruled (2026-08-27): re-derive off a NON-MODIS
# product, MOD17 being a single point of failure for a constant that now carries
# the whole seasonal arc.
#
# WHY CMIP6 AND NOT TRENDY. TRENDY is the named target and is access-by-request
# (Sitch); its site does not resolve from here. CMIP6 `npp` (Lmon, historical) is
# the same CLASS of evidence -- process land models, no satellite anywhere in the
# chain, so fully independent of MOD17's LUE algorithm -- and it is open. It also
# covers 36 models against TRENDY's ~18.
#
# ⚠ WHAT THIS IS NOT. These are MODELS, not observations. Marcus accepted that
# explicitly for a PEDAGOGICAL tool (2026-08-27), and the acceptance is the
# provenance: this product may NOT be described as an observational constraint.
# What it buys is INDEPENDENCE FROM MOD17 and, uniquely among the candidates,
# the quantity itself -- every other option (SIF, FLUXCOM, inversions) is a GPP
# proxy or a NET flux, and reproduces the "neither end is NPP" problem that
# opened this whole question, in a new instrument.
#
# THE SPREAD REPORTED IS ACROSS MODELS, NOT ACROSS YEARS. MOD17's product put 5
# YEARS in `shape_by_year` because its uncertainty was interannual. Here the
# dominant uncertainty is structural, so the columns are MODELS and the spread is
# the ensemble's. The field keeps MOD17's NAME so diag_seas_rectification.R
# ingests it unchanged; `col_kind` records which it is so nothing reads it wrong.
#
# ONE MEMBER PER MODEL, deliberately. CanESM5 has 65 members and GISS-E2-1-G 46;
# taking all of them would weight the ensemble by how many runs an institute
# could afford, not by structural diversity. r1i1p1f1 where it exists.
#
# HEMISPHERIC AGGREGATION. CMIP6 `npp` is a flux PER UNIT LAND AREA (the data
# request's area-type is `land`), so the hemispheric total is
# sum(npp * areacella * sftlf/100), NOT sum(npp * areacella) -- the latter
# overweights partial-land coastal cells. Both `areacella` and `sftlf` are pulled
# per model; where either is missing the fallback is an analytic cos(lat) cell
# area and/or the npp mask itself, and WHICH WAS USED IS RECORDED PER MODEL so a
# reader can drop the fallbacks and see whether anything moves.
#
# Usage:  python data-raw/build_cmip6_npp_seasonal_shape.py
# =====================================================================
import csv, json, sys, warnings, collections
import numpy as np, xarray as xr

warnings.filterwarnings("ignore")

CAT       = "/tmp/pangeo-cmip6.csv"
OUT_NPZ   = "data-raw/downloads/cmip6_npp_seasonal_shape.npz"
YR0, YR1  = 1995, 2014          # last 20 yr of historical; CMIP6 historical ends 2014
PREF_MEM  = "r1i1p1f1"

rows = list(csv.DictReader(open(CAT)))
def pick(var, table, source, exp=None):
    c = [x for x in rows if x["variable_id"] == var and x["table_id"] == table
         and x["source_id"] == source and (exp is None or x["experiment_id"] == exp)]
    if not c: return None
    c.sort(key=lambda x: (x["member_id"] != PREF_MEM, x["member_id"], x["grid_label"]))
    return c[0]

npp_rows = [x for x in rows if x["variable_id"] == "npp" and x["table_id"] == "Lmon"
            and x["experiment_id"] == "historical"]
models = sorted(set(x["source_id"] for x in npp_rows))
print(f"{len(models)} models with npp Lmon historical", flush=True)

def open_z(z):
    return xr.open_zarr(z.replace("gs://", "gs://"), consolidated=True, storage_options={"token": "anon"})

def cell_area(lat, lon):
    R = 6371000.0
    lat = np.asarray(lat, float); lon = np.asarray(lon, float)
    dlon = np.abs(np.gradient(lon)) * np.pi / 180.0
    edges = np.concatenate(([lat[0] - (lat[1]-lat[0])/2],
                            (lat[:-1] + lat[1:]) / 2,
                            [lat[-1] + (lat[-1]-lat[-2])/2]))
    edges = np.clip(edges, -90, 90)
    band = 2*np.pi*R**2*np.abs(np.sin(np.radians(edges[1:])) - np.sin(np.radians(edges[:-1])))
    return (band[:, None] / (2*np.pi) * dlon[None, :])

out, meta = {}, []
for m in models:
    try:
        r = pick("npp", "Lmon", m, "historical")
        ds = open_z(r["zstore"])
        # ⚠ 360-DAY CALENDARS HAVE NO 31 DECEMBER. Slicing to "-12-31" raises
        # inside cftime for UKESM1-0-LL and every other 360_day model -- it is a
        # calendar error, not a data gap, and dropping the model on it would have
        # silently deleted a major structural family from the ensemble.
        npp = ds["npp"].sel(time=slice(f"{YR0}-01-01", f"{YR1}-12-30"))
        if npp.time.size < 12:
            print(f"  {m:20s} SKIP: {npp.time.size} months in window", flush=True); continue
        lat = ds["lat"].values; lon = ds["lon"].values
        # --- weights -------------------------------------------------
        wsrc = []
        ar = pick("areacella", "fx", m)
        if ar is not None:
            A = open_z(ar["zstore"])["areacella"].values; wsrc.append("areacella")
        else:
            A = cell_area(lat, lon); wsrc.append("cos(lat) analytic")
        sf = pick("sftlf", "fx", m)
        if sf is not None:
            L = open_z(sf["zstore"])["sftlf"].values / 100.0; wsrc.append("sftlf")
        else:
            L = np.ones_like(A); wsrc.append("npp-mask only")
        if A.shape != npp.shape[-2:] or L.shape != npp.shape[-2:]:
            print(f"  {m:20s} SKIP: weight shape {A.shape}/{L.shape} vs {npp.shape[-2:]}", flush=True); continue
        W = np.nan_to_num(A * L)
        # --- hemispheric totals, kgC/s -> PgC/yr ---------------------
        v = npp.values                      # (t, lat, lon)
        v = np.where(np.isfinite(v), v, 0.0)
        hemi = {}
        for h, sel in (("NH", lat > 0), ("SH", lat < 0)):
            tot = np.einsum("tij,ij->t", v[:, sel, :], W[sel, :])   # kgC/s
            hemi[h] = tot * 1e-12 * 86400 * 365.25                  # PgC/yr
        # ⚠ GATE: NPP IS A STRICTLY POSITIVE FLUX. SAM0-UNICON returns it with
        # the opposite sign (-29.0/-19.7 PgC/yr), which would pass silently into a
        # unit-mean normalisation and invert that model's whole seasonal shape.
        # Rejected here, LOUDLY, rather than filtered downstream.
        if hemi["NH"].mean() <= 0 or hemi["SH"].mean() <= 0:
            print(f"  {m:20s} REJECT: non-positive NPP "
                  f"(NH {hemi['NH'].mean():.1f}, SH {hemi['SH'].mean():.1f} PgC/yr)"
                  f" -- sign convention differs; excluded", flush=True)
            continue
        mon = npp["time.month"].values
        for h in ("NH", "SH"):
            clim = np.array([hemi[h][mon == k].mean() for k in range(1, 13)])
            out[f"{h}|{m}"] = clim
        meta.append(dict(model=m, member=r["member_id"], grid=r["grid_label"],
                         weights=" x ".join(wsrc), nmonths=int(npp.time.size),
                         NH_PgC=float(hemi["NH"].mean()), SH_PgC=float(hemi["SH"].mean())))
        print(f"  {m:20s} ok  NH {hemi['NH'].mean():6.1f}  SH {hemi['SH'].mean():6.1f} PgC/yr"
              f"  [{' x '.join(wsrc)}]", flush=True)
    except Exception as e:
        print(f"  {m:20s} FAIL: {type(e).__name__}: {str(e)[:90]}", flush=True)

np.savez(OUT_NPZ, meta=json.dumps(meta),
         **{k: v for k, v in out.items()})
print(f"\nwrote {OUT_NPZ}: {len(meta)} models")
