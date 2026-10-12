x <- readRDS(file.path(Sys.getenv("DD"), "rc.rds")); cl <- x$rc$climate; k <- cl$year %in% 2019:2030
print(data.frame(year = cl$year[k], gmst = round(cl$gmst[k], 3)))
