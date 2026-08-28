# =====================================================================
# build_carbontracker_land_shape.py -- THE SEASONAL CYCLE OF NH/SH LAND NEE
#   FROM AN ATMOSPHERIC INVERSION -> data-raw/downloads/ct2022_land_shape.npz
#
# WHY THIS EXISTS. Marcus ruled (2026-08-27) that `SEAS_NPP_AMP_SH` be re-derived
# off a non-MODIS product, and named CAMS. CAMS needs a Copernicus ADS account +
# API key; NOAA CarbonTracker CT2022 is the same PRODUCT CLASS -- a global
# inversion of the surface CO2 network -- and is open. Substitution approved.
#
# ⚠⚠ TWO WARNINGS, AND THEY ARE THE WHOLE REASON THIS FILE HAS A LONG HEADER.
#
# (1) IT IS CIRCULAR, BY CONSTRUCTION. CarbonTracker is constrained by the
#     surface CO2 network, which INCLUDES MLO and SPO -- the very records the
#     model is scored against. Agreement between this product and the model's
#     seasonal CO2 is therefore NOT evidence: some of it is guaranteed. Marcus
#     accepted the circularity explicitly for a pedagogical tool (2026-08-27).
#     The acceptance is not a licence to quote the agreement as a test.
#     [[no_power_null]] -- a structurally guaranteed null reads exactly like a
#     real negative, so state the circularity everywhere this product appears.
#     ⚠ AND THE CIRCULARITY IS NOT UNIFORM: SH land has very few constraining
#     sites, so CT's SH LAND seasonality is substantially its PRIOR (a biosphere
#     model), not its data. That cuts the circularity and raises a different
#     problem -- in the SH this is closer to a process model wearing an
#     inversion's clothes. Do not treat NH and SH as equally observational.
#
# (2) IT IS NEE, NOT NPP -- SO IT CANNOT RE-DERIVE THE CONSTANT LIKE-FOR-LIKE.
#     `seas_npp_amp_SH` scales the PRODUCTIVITY half of the model's land cycle;
#     the model's NET land flux is that term PLUS the q10 soil-respiration term.
#     An inversion constrains the SUM. Marcus's instruction (2026-08-27) is to
#     report BOTH: (a) a NET-FLUX check in its own column, which is the quantity
#     the arc is actually failing (SPO SH-local land 0.906 vs an observed 0.683),
#     and (b) a model-mediated constant, backed out by adding the model's own
#     respiration -- which is model-signature-dependent in exactly the way
#     handoff 27k warns about for the inversion's "observed" land.
#     THE POINT OF DOING BOTH IS TO MEASURE THAT DEPENDENCE, NOT ASSERT IT SMALL.
#
# ⚠ (3) NEE HAS A NEAR-ZERO ANNUAL MEAN, so the unit-mean normalisation the
#     MOD17 pipeline uses (`unitmean`, divide by the annual mean) is UNDEFINED
#     here -- it divides by a small net sink and explodes. Everything downstream
#     of this file must work on ANOMALIES scaled by peak-to-peak, never on
#     unit-mean shapes. This is why CT cannot simply be dropped into
#     diag_seas_rectification.R the way the CMIP6 NPP product can.
#
# SIGN CONVENTION: CarbonTracker fluxes are POSITIVE INTO THE ATMOSPHERE. This
# file stores them in that convention and says so; flipping it silently is how a
# phase ends up 6 months out.
#
# Usage:  python data-raw/build_carbontracker_land_shape.py
# =====================================================================
import json
import numpy as np, xarray as xr

IN   = "data-raw/downloads/CT2022.flux1x1-monthly.nc"
OUT  = "data-raw/downloads/ct2022_land_shape.npz"
YR0, YR1 = 2000, 2020

ds = xr.open_dataset(IN)
lat = ds["latitude"].values; lon = ds["longitude"].values
R = 6371000.0
edges = np.concatenate(([lat[0]-(lat[1]-lat[0])/2], (lat[:-1]+lat[1:])/2,
                        [lat[-1]+(lat[-1]-lat[-2])/2]))
edges = np.clip(edges, -90, 90)
band  = 2*np.pi*R**2*np.abs(np.sin(np.radians(edges[1:]))-np.sin(np.radians(edges[:-1])))
dlon  = np.abs(np.gradient(lon))*np.pi/180.0
A     = band[:, None]/(2*np.pi)*dlon[None, :]          # m2, exact for a regular grid
# GATE: the cell-area field must integrate to the sphere.
assert abs(A.sum()/(4*np.pi*R**2) - 1) < 1e-6, A.sum()/(4*np.pi*R**2)

bio = ds["bio_flux_opt"].sel(time=slice(f"{YR0}-01-01", f"{YR1}-12-31"))
fire = ds["fire_flux_imp"].sel(time=slice(f"{YR0}-01-01", f"{YR1}-12-31"))
mon = bio["time.month"].values
KG_PER_MOL_C = 12.011e-3
S_PER_YR = 86400*365.25

out, meta = {}, {}
for name, da in (("bio", bio), ("bio_plus_fire", bio + fire)):
    v = np.nan_to_num(da.values)
    for h, sel in (("NH", lat > 0), ("SH", lat < 0)):
        tot = np.einsum("tij,ij->t", v[:, sel, :], A[sel, :])       # mol/s
        tot = tot * KG_PER_MOL_C * 1e-12 * S_PER_YR                 # PgC/yr, +ve to atm
        clim = np.array([tot[mon == k].mean() for k in range(1, 13)])
        # interannual spread of the climatology, for an honest error bar
        per_yr = np.array([[tot[(mon == k)][i] for k in range(1, 13)]
                           for i in range(tot[mon == 1].size)])
        out[f"{name}|{h}|clim"] = clim
        out[f"{name}|{h}|per_year"] = per_yr
        meta[f"{name}|{h}"] = dict(annual_mean_PgC=float(tot.mean()),
                                   p2p_PgC=float(clim.max()-clim.min()),
                                   ratio_mean_to_p2p=float(abs(tot.mean())/(clim.max()-clim.min())))
        print(f"{name:14s} {h}  annual mean {tot.mean():+7.2f} PgC/yr   "
              f"seasonal p2p {clim.max()-clim.min():6.2f}   |mean|/p2p {abs(tot.mean())/(clim.max()-clim.min()):.3f}")

np.savez(OUT, meta=json.dumps(meta), years=np.arange(YR0, YR1+1), **out)
print(f"\nwrote {OUT}")
print("SIGN: POSITIVE = FLUX INTO THE ATMOSPHERE (CarbonTracker convention).")
print("⚠ |mean|/p2p above is why unit-mean normalisation is banned for this product.")
