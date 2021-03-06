DEFAULT_RSPM_REPO_ID <-  "1" # cran
DEFAULT_RSPM <-  "https://packagemanager.rstudio.com"

#' Query the system requirements for a dev package (and its dependencies)
#'
#' Returns a character vector of commands to run that will install system
#' requirements for the queried operating system.
#'
#' @inheritParams local_install
#' @param os,os_release The operating system and operating system release version, see
#'   <https://github.com/rstudio/r-system-requirements#operating-systems> for the
#'   list of supported operating systems. If `NULL`, the default, these will be
#'   looked up using [distro::distro()].
#' @param execute,sudo If `execute` is `TRUE`, pak will execute the system
#'   commands (if any). If `sudo` is `TRUE`, pak will prepend the commands with
#'   [sudo](https://en.wikipedia.org/wiki/Sudo).
#' @param echo If `echo` is `TRUE` and `execute` is `TRUE`, echo the command output.
#' @return A character vector of commands needed to install the system requirements for the package (invisibly).
#' @export
local_system_requirements <- function(os = NULL, os_release = NULL, root = ".", execute = FALSE, sudo = execute, echo = FALSE) {
  res <- remote(
    function(...) asNamespace("pak")$system_requirements_internal(...),
    list(os = os, os_release = os_release, root = root, package = NULL, execute = execute, sudo = sudo, echo = echo))
  invisible(res)
}

#' @param package The package name to lookup system requirements for.
#' @rdname local_system_requirements
#' @export
pkg_system_requirements <- function(package, os = NULL, os_release = NULL, execute = FALSE, sudo = execute, echo = FALSE) {
  res <- remote(
    function(...) asNamespace("pak")$system_requirements_internal(...),
    list(os = os, os_release = os_release, root = NULL, package = package, execute = execute, sudo = sudo, echo = echo))
  invisible(res)
}

system_requirements_internal <- function(os, os_release, root, package, execute, sudo, echo) {
  if (is.null(os) || is.null(os_release)) {
    d <- distro::distro()
    os <- os %||% d$id
    os_release <- os_release %||% d$short_version
  }

  os_versions <- supported_os_versions()

  os <- match.arg(os, names(os_versions))

  os_release <- match.arg(os_release, os_versions[[os]])

  rspm <- Sys.getenv("RSPM_ROOT", DEFAULT_RSPM)
  rspm_repo_id <- Sys.getenv("RSPM_REPO_ID", DEFAULT_RSPM_REPO_ID)
  rspm_repo_url <- sprintf("%s/__api__/repos/%s", rspm, rspm_repo_id)


  if (!is.null(package)) {
    req_url <- sprintf(
      "%s/sysreqs?all=false&pkgname=%s&distribution=%s&release=%s",
      rspm_repo_url,
      package,
      os,
      os_release
    )
    res <- curl::curl_fetch_memory(req_url)
    data <- jsonlite::fromJSON(rawToChar(res$content), simplifyVector = FALSE)

    pre_install <- unique(unlist(c(data[["pre_install"]], lapply(data[["requirements"]], function(x) x[["requirements"]][["pre_install"]]))))
    install_scripts <- unique(unlist(c(data[["install_scripts"]], lapply(data[["requirements"]], function(x) x[["requirements"]][["install_scripts"]]))))
  }

  else {
    desc_file <- normalizePath(file.path(root, "DESCRIPTION"), mustWork = FALSE)
    if (!file.exists(desc_file)) {
      stop("`", root, "` must contain a package.", call. = FALSE)
    }

    req_url <- sprintf(
      "%s/sysreqs?distribution=%s&release=%s&suggests=true",
      rspm_repo_url,
      os,
      os_release
    )

    h <- curl::new_handle()

    desc_size <- file.size(desc_file)
    desc_data <- readBin(desc_file, "raw", desc_size)

    curl::handle_setheaders(h,
      customrequest = "POST",
      "content-type" = "text/plain"
    )

    curl::handle_setopt(h,
      postfieldsize = desc_size,
      postfields = desc_data
    )

    res <- curl::curl_fetch_memory(req_url, h)

    data <- jsonlite::fromJSON(rawToChar(res$content), simplifyVector = FALSE)

    pre_install <- unique(unlist(c(data[["pre_install"]], lapply(data[["dependencies"]], `[[`, "pre_install"))))
    install_scripts <- unique(unlist(c(data[["install_scripts"]], lapply(data[["dependencies"]], `[[`, "install_scripts"))))
  }

  commands <- as.character(c(pre_install, install_scripts))
  if (echo) {
    callback <- function(x, ...) cli::cli_verbatim(sub("[\r\n]+$", "", x))
  } else {
    callback <- function(x, ...) invisible()
  }

  if (execute) {
    for (cmd in commands) {
      if (sudo) {
        cmd <- paste("sudo", cmd)
      }
      cli::cli_alert_info("Executing {.code {cmd}}")

      processx::run("sh", c("-c", cmd), stdout_callback = callback, stderr_to_stdout = TRUE)
    }
  }

  commands
}

# Adapted from https://github.com/rstudio/r-system-requirements/blob/master/systems.json
# OSs commented out are not currently supported by the API
supported_os_versions <- function() {
  list(
    #"debian" = c("8", "9"),
    "ubuntu" = c("14.04", "16.04", "18.04", "20.04"),
    "centos" = c("6", "7", "8"),
    "redhat" = c("6", "7", "8"),
    "opensuse" = c("42.3", "15.0"),
    "sle" = c("12.3", "15.0")
    #"windows" = c("")
  )
}
