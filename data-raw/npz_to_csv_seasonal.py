# npz_to_csv_seasonal.py -- flatten the CMIP6 / CT npz climatologies to CSV so the
# R diagnostics can read them without an R-side npz reader. Pure format change.
import json, sys
import numpy as np
for src, out in (("data-raw/downloads/cmip6_npp_seasonal_shape.npz", "data-raw/downloads/cmip6_npp_seasonal_shape.csv"),
                 ("data-raw/downloads/ct2022_land_shape.npz",        "data-raw/downloads/ct2022_land_shape.csv")):
    try:
        z = np.load(src, allow_pickle=True)
    except FileNotFoundError:
        print(f"skip (absent): {src}"); continue
    rows = ["series,month,value"]
    for k in z.files:
        if k in ("meta", "years"): continue
        v = np.asarray(z[k])
        if v.ndim == 1 and v.size == 12:
            rows += [f"{k},{i+1},{v[i]:.10g}" for i in range(12)]
    open(out, "w").write("\n".join(rows) + "\n")
    print(f"wrote {out}: {len(rows)-1} rows")
    if "meta" in z.files:
        open(out.replace(".csv", "_meta.json"), "w").write(str(z["meta"]))
