suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
sp <- dg_spinup(v)
y <- sp$y
forc <- list(e_foss = list(NH=0,SH=0), e_luc=list(NH=0,SH=0), cum_luc=list(NH=0,SH=0), gmst=0, enso=0, land_enso=0, d13c_foss=0,
             c14_bomb=0, c14_nuclear=0, c14_cosmo=sp$prod_c14, mix_g = 1)
acc <- 0
for (m in 1:12) { dy <- ccx_deriv(y, 1750 + (m-0.5)/12, sp$params, forc, sp$grid, sp$aux, record = TRUE); acc <- acc + attr(dy,"fluxes")$channels/12 }
print(round(acc, 2))
