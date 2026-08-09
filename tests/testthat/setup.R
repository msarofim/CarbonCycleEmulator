# Sourced by testthat before every test file. Loads the model source from
# the repo root so tests work regardless of the working directory.

.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:10) {
    if (file.exists(file.path(d, "DESIGN.md"))) break
    d <- dirname(d)
  }
  d
})

for (f in list.files(file.path(.root, "R"), pattern = "\\.R$", full.names = TRUE)) {
  source(f)
}
