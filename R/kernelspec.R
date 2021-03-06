# Copyright (C) 2017  Spencer Aiello
#
# This file is part of JuniperKernel.
#
# JuniperKernel is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# JuniperKernel is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with JuniperKernel.  If not, see <http://www.gnu.org/licenses/>.

## Juniper Kernel Installation
##
## Requires jupyter and installs the kernel via
## `jupyter kernelspec install`.


# INSTALL HELPERS

.argv <- function() {
  exec <- file.path(R.home('bin'), 'R')
  c(exec, '--slave', '-e', 'JuniperKernel::bootKernel()', '--args', '{connection_file}')
}

.stopIfJupyterMissing <- function() {
  rc <- system2("jupyter", c("kernelspec", "--version"), FALSE, FALSE)
  if( rc ) {
    stop("jupyter not found; ensure jupyter is installed.")
  }
}

.writeSpec <- function(displayName) {
  tmpPath <- tempfile()
  kernelspec <- file.path(tmpPath, 'kernelspec')
  dir.create(kernelspec, recursive=TRUE)
  specPath <- file.path(kernelspec, "kernel.json")
  spec <- list( argv = .argv()
              , display_name = displayName
              , language = 'R'
              )
  fc <- file(specPath)
  writeLines(jsonlite::toJSON(spec, pretty=TRUE, auto_unbox=TRUE), specPath)
  close(fc)
  file.copy(system.file("extdata", "logo-64x64.png", package="JuniperKernel"), file.path(tmpPath, 'kernelspec'))
  tmpPath
}

.installSpec <- function(useJupyterDefault, prefix, kernelName, tmpPath) {
  kernelspec <- file.path(tmpPath, 'kernelspec')
  args <- c( "kernelspec"
           , "install"
           , "--replace"
           , "--name"
           , kernelName
           # --user flag
           , ifelse(useJupyterDefault, '--user', '')
           # --prefix prefix
           , ifelse(nzchar(prefix), '--prefix', '')
           , ifelse(nzchar(prefix), prefix, '')
           # path to kernelspec
           , kernelspec
           )
  rc <- system2("jupyter", args)
  unlink(tmpPath, recursive = TRUE)
  rc
}

#' List Kernels
#'
#' @title List Installed Jupyter Kernels
#' @details
#' Prints the currently installed kernels and their install locations.
#'
#' @examples
#' \dontrun{
#'   listKernels()
#' }
#'
#' @export
listKernels <- function() {
  .stopIfJupyterMissing()
  invisible(system2('jupyter', c('kernelspec', 'list')))
}

#' Create Kernel Name
#'
#' @title Create the Default Kernel Name
#' @seealso \code{\link{installJuniper}}.
#'
#' @examples
#' \dontrun{
#'   defaultKernelName()
#' }
#'
#' @export
defaultKernelName <- function() {
  s <- utils::sessionInfo()
  paste0('juniper_r', s$R.version$major, '.', s$R.version$minor)
}

#' Create Kernel Display Name
#'
#' @title Create the Default Kernel Display Name
#' @seealso \code{\link{installJuniper}}.
#'
#' @examples
#' \dontrun{
#'   defaultDisplayName()
#' }
#'
#' @export
defaultDisplayName <- function() {
  s <- utils::sessionInfo()
  paste0('R ', s$R.version$major, '.', s$R.version$minor, ' (Juniper)')
}

#' Install Juniper Kernel
#'
#' @title Install the Juniper Kernel for Jupyter
#'
#' @details
#' Use this method to install the Juniper Kernel. After a successful invocation
#' of this method, Juniper will be an available kernel for all Jupyter front-end
#' clients (e.g., the dropdown selector in the Notebook interface). This method
#' is essentially a wrapper on the function call \code{jupyter kernelspec install}
#' with some extra configuration options. These options are detailed as the parameters
#' below. One important note to make is that the kernel will depend the \code{R} environment
#' that doing the invoking. In this way a user may install kernels for different versions
#' of R by invoking this \code{installJuniper} method from each respective R. The defaults
#' for \code{kernelName} and \code{displayName} are good for avoiding namespacing issues
#' between versions of R, but installs having the same kernel name replace an existing
#' kernel.
#'
#' @param useJupyterDefault
#' If \code{TRUE}, install the kernel in a default Jupyter kernel location fashion. For macOS,
#' the default Jupyter kernel location is \code{~/Library/Jupyter/kernels}. For Windows, the
#' default Jupyter kernel location is \code{\%APPDATA\%\\jupyter\\kernels}. For Linux this directory is
#' \code{~/.local/share/jupyter/kernels}.
#' If \code{FALSE}, the kernel is installed system-wide. For unix-based machines,
#' the system-level directory is \code{/usr/share/jupyter/kernels} or
#' \code{/usr/local/share/jupyter/kernels}. For Windows, the location is
#' \code{\%PROGRAMDATA\%\\jupyter\\kernels}.
#' If the \code{prefix} argument is specified, then the \code{useJupyterDefault} parameter is ignored.
#'
#' @param kernelName
#' A character string representing the location of the kernel. This is required
#' to be made up of alphanumeric and \code{.}, \code{_}, \code{-} characters only.
#' This is enforced with a check against this \code{^[a-zA-Z_][a-zA-Z0-9_.-]*$} regex.
#' The case of this argument is always ignored and is \code{tolower}ed; so while it's
#' allowed to have mixed-case characters, the resulting location will not be. A warning
#' will be issued if there is mixed-case characters. The default for this
#' \code{juniper_r} concatenated with the \code{major.minor} version of R. For example,
#' for R 3.4.0, the default would be \code{juniper_r3.4.0}.
#'
#' @param displayName
#' A character string representing the name of the kernel in a client. There are no
#' restrictions on the display name. The default for R 3.4.0 is \code{R 3.4.0 (Juniper)}.
#'
#' @param prefix
#' A character string specifying the \code{virtual env} that this kernel should be installed
#' to. The install location will be \code{prefix/share/jupyter/kernels}.
#'
#' @examples
#' \dontrun{
#'   installJuniper(useJupyterDefault = TRUE)  # install into default Jupyter kernel location
#' }
#' @export
installJuniper <- function(useJupyterDefault = FALSE, kernelName = defaultKernelName(), displayName = defaultDisplayName(), prefix='') {
  .stopIfJupyterMissing()

  if( regexpr("^[a-zA-Z_][a-zA-Z0-9_.-]*$", kernelName)[1L] == -1L )
    stop("`kernelName` must match the regex ^[a-zA-Z_][a-zA-Z0-9_.-]*$")

  name <- tolower(kernelName)
  if( name!=kernelName )
    warning("Mixed case characters are ignored: ", kernelName, " -> ", name)

  if( !nzchar(prefix) && !useJupyterDefault )
    stop("Must specify `useJupyterDefault` as TRUE or `prefix` must be a path.")

  # write the kernels.json file
  tmpPath <- .writeSpec(displayName)

  if( useJupyterDefault && nzchar(prefix) ) {
    warning("`useJupyterDefault` and `prefix` specifed. `useJupyterDefault` is ignored.")
    useJupyterDefault <- FALSE
  }

  # install the kernel for jupyter to see
  invisible(.installSpec(useJupyterDefault, prefix, name, tmpPath))
}