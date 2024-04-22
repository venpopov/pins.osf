## TODO: record version control information such as git commit and SHA as pin metadata


# osf_ls_files can be used to list all files and folders within an osf component
# osf_ls_files can be applied on each row of the returned data frame to list all files and folders within those
# write a function which recursively applies osf_ls_files to all rows of the data frame and repeats until all rows are files

is_file <- function(x) {
  sapply(x$meta, function(x) isTRUE(x$attributes$kind == "file"))
}

# TODO: needs better description
#' Recursively list files in a directory in an osf_tbl object
#'
#' This function recursively lists all the files in a directory and its subdirectories.
#'
#' @param df A data frame representing the directory structure.
#' @return A data frame containing the list of files.
#' @export
recurse_ls_files <- function(df) {
  is_file <- is_file(df)
  files <- df[is_file, ]
  df <- df[!is_file, ]
  n <- nrow(df)
  for (i in seq_len(n)) {
    files <- rbind(files, recurse_ls_files(osf_ls_files(df[i, ])))
  }
  files
}

append_correct_path <- function(df) {
  df$path <- sapply(df$meta, \(x) x$attributes$materialized_path)
  df
}

# TODO: can make this easier by just reading the _pins.yaml file
osf_download_recursive <- function(df, basepath = "local") {
  download1 <- function(x) {
    path <- file.path(basepath, dirname(x$path))
    path <- gsub("//", "/", path)
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    osfr::osf_download(x, path,
      conflicts = "skip", verbose = TRUE
    )
  }
  df <- df |>
    recurse_ls_files() |>
    append_correct_path()
  split(df, 1:nrow(df)) |>
    lapply(download1) |>
    unsplit(1:nrow(df))
}
