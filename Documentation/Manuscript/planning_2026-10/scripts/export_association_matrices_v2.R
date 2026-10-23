# export_association_matrices_v2.R
# Read-only. Part A diagnoses the reader on ONE object and PRINTS the errors.
# Part B does the full export using whichever reader worked.
#
# Still never calls tar_make, never writes into Data/targets, and touches only
# the cold paleo_temporal_* stores.

repo <- "D:/GITHUB/BIODYNAMICS_vegetation_cooccurrence"
out  <- file.path(repo, "Data", "Temp", "assoc_export")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

stores <- list(
  paleo_temporal_europe  = "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal",
  paleo_temporal_america = "Data/targets/paleo_temporal_america/pipeline_paleo_temporal",
  paleo_temporal_asia    = "Data/targets/paleo_temporal_asia/pipeline_paleo_temporal"
)

probe_store  <- file.path(repo, stores[["paleo_temporal_europe"]])
probe_target <- "model_jsdm_selected_timeslice_6000"
probe_file   <- file.path(probe_store, "objects", probe_target)

# ---------------------------------------------------------------- Part A ----
cat("=== ENVIRONMENT ===\n")
cat(R.version.string, "\n")
cat("libPaths:\n"); cat(paste0("  ", .libPaths()), sep = "\n")
for (p in c("qs2", "qs", "targets", "sjSDM")) {
  v <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) "NOT INSTALLED")
  cat(sprintf("  %-8s %s\n", p, v))
}
cat("\nprobe file exists:", file.exists(probe_file),
    " size:", file.info(probe_file)$size, "bytes\n")
cat("magic:", paste(readBin(probe_file, "raw", 8), collapse = " "), "\n\n")

cat("=== READER TRIALS (error message is the point) ===\n")
readers <- list(
  `qs2::qs_read`            = function() qs2::qs_read(probe_file),
  `qs2::qd_read`            = function() qs2::qd_read(probe_file),
  `qs::qread`               = function() qs::qread(probe_file),
  `targets::tar_read_raw`   = function() targets::tar_read_raw(probe_target, store = probe_store),
  `readRDS`                 = function() readRDS(probe_file)
)
winner <- NULL
for (nm in names(readers)) {
  res <- tryCatch(readers[[nm]](), error = function(e) structure(conditionMessage(e), class = "rfail"))
  if (inherits(res, "rfail")) {
    cat(sprintf("  %-24s FAIL  %s\n", nm, substr(as.character(res), 1, 160)))
  } else {
    cat(sprintf("  %-24s OK    class=%s\n", nm, paste(class(res), collapse = "/")))
    if (is.null(winner)) { winner <- nm; probe_obj <- res }
  }
}

if (is.null(winner)) {
  cat("\nNo reader worked. Stop here and send me this output.\n")
  quit(save = "no")
}

cat("\n=== OBJECT SHAPE (via", winner, ") ===\n")
cat("names:", paste(names(probe_obj), collapse = " | "), "\n")
cat("has sigma:", "sigma" %in% names(probe_obj), "\n")
if (!is.null(probe_obj$sigma)) cat("dim(sigma):", paste(dim(probe_obj$sigma), collapse = " x "), "\n")
cat("n species:", length(probe_obj$species), "\n")
cat("species head:", paste(utils::head(probe_obj$species, 8), collapse = ", "), "\n\n")

# ---------------------------------------------------------------- Part B ----
read_one <- switch(winner,
  "qs2::qs_read"          = function(file, target, store) qs2::qs_read(file),
  "qs2::qd_read"          = function(file, target, store) qs2::qd_read(file),
  "qs::qread"             = function(file, target, store) qs::qread(file),
  "targets::tar_read_raw" = function(file, target, store) targets::tar_read_raw(target, store = store),
  "readRDS"               = function(file, target, store) readRDS(file)
)

get_cor_safe <- function(m) {
  r <- try(sjSDM::getCor(m), silent = TRUE)
  if (!inherits(r, "try-error") && is.matrix(r)) return(list(cor = r, method = "sjSDM::getCor"))
  if (!is.null(m$sigma)) return(list(cor = stats::cov2cor(m$sigma %*% t(m$sigma)),
                                     method = "cov2cor(sigma t(sigma))"))
  NULL
}

index <- list()
for (sname in names(stores)) {
  store  <- file.path(repo, stores[[sname]])
  objdir <- file.path(store, "objects")
  if (!dir.exists(objdir)) next
  targets_here <- list.files(objdir, pattern = "^model_jsdm_selected")
  cat(sname, ":", length(targets_here), "objects\n")

  for (tn in targets_here) {
    f   <- file.path(objdir, tn)
    age <- suppressWarnings(as.integer(sub(".*_(\\d+)$", "\\1", tn)))
    row <- list(store = sname, object = tn, age = age, n_taxa = NA_integer_,
                n_sites = NA_integer_, status = "ok", method = NA_character_,
                error = "")

    m <- tryCatch(read_one(f, tn, store),
                  error = function(e) structure(conditionMessage(e), class = "rfail"))
    if (inherits(m, "rfail")) {
      row$status <- "read_error"; row$error <- substr(as.character(m), 1, 200)
    } else if (is.null(m)) {
      row$status <- "null_object"
    } else {
      res <- get_cor_safe(m)
      if (is.null(res)) {
        row$status <- "no_sigma"
      } else {
        cm <- res$cor
        sp <- m$species
        if (!is.null(sp) && length(sp) == nrow(cm)) { rownames(cm) <- sp; colnames(cm) <- sp }
        utils::write.csv(cm, file.path(out, paste0(sname, "__", tn, "__cor.csv")))
        row$n_taxa  <- nrow(cm)
        row$n_sites <- tryCatch(nrow(m$data$Y), error = function(e) NA_integer_)
        row$method  <- res$method
      }
      rm(m)
    }
    index[[length(index) + 1]] <- as.data.frame(row, stringsAsFactors = FALSE)
    invisible(gc(verbose = FALSE))
  }
}

idx <- do.call(rbind, index)
utils::write.csv(idx, file.path(out, "_index.csv"), row.names = FALSE)
cat("\nwrote", sum(idx$status == "ok"), "matrices to", out, "\n")
print(table(idx$store, idx$status))
if (any(idx$status != "ok")) {
  cat("\nfirst distinct errors:\n")
  print(utils::head(unique(idx$error[idx$error != ""]), 3))
}
