suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
cc <- carb_coefs(); cat("t_range:", cc$t_range, " salinity:", cc$salinity, " boron_total:", cc$boron_total, " names:", paste(names(cc), collapse=","), "\n")
print(attr(cc, "provenance")); print(cc$provenance); print(cc$source)
g <- expand.grid(dic = seq(1.85e-3, 2.40e-3, length.out = 12), alk = c(2.25e-3, 2.30e-3, 2.40e-3), T = seq(-2, 32, by = 2))
g <- g[g$T >= cc$t_range[1] & g$T <= cc$t_range[2], ]
h6  <- h_from_dic_alk(g$dic, g$alk, g$T, iter = 6L)
h30 <- h_from_dic_alk(g$dic, g$alk, g$T, iter = 30L)
cat("max rel |h6 - h30|/h30:", max(abs(h6 - h30) / h30), "\n")
p6 <- pco2_from_dic(g$dic, g$alk, g$T, iter = 6L); p30 <- pco2_from_dic(g$dic, g$alk, g$T, iter = 30L)
cat("max |pCO2_6 - pCO2_30| uatm:", max(abs(p6 - p30)), " pCO2 range:", range(p6), "\n")
# extreme DIC near ALK
g2 <- data.frame(dic = 2.35e-3, alk = 2.30e-3, T = 25)
cat("DIC>ALK case: h6", h_from_dic_alk(g2$dic, g2$alk, g2$T, 6L), " h30", h_from_dic_alk(g2$dic, g2$alk, g2$T, 30L), "\n")
cat("Revelle at DIC 2.0e-3 ALK 2.3e-3 T 15:", revelle_factor(2.0e-3, 2.3e-3, 15), "\n")
