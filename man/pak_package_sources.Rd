% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/package.R
\name{pak_package_sources}
\alias{pak_package_sources}
\title{Package sources}
\description{
Package sources
}
\section{Standard packages}{


pak can install packages from various package sources. By default,
a package name without the specification of its source, refers to a
CRAN or Bioconductor package. pak calls these \emph{standard} packages.
For example:\if{html}{\out{<div class="r">}}\preformatted{## CRAN package
pkg_install("glue")
## BioC package
pkg_install("limma")
}\if{html}{\out{</div>}}

When considering a standard package, the calling version of R is used
to determine the available source and binary packages on CRAN and the
Bioconductor repositories.

The full specification of standard packages is simply\preformatted{[standard::]<package>
}

If you know the exact source of the package, you can also write\preformatted{cran::<package>
bioc::<package>
}
}

\section{GitHub packages}{


pak can install packages from GitHub repositories. Any package that
is specified in the \code{user/repo} notation is taken to be a GitHub package.
For example:\if{html}{\out{<div class="r">}}\preformatted{## Package from GitHub
pkg_install("r-lib/glue")
}\if{html}{\out{</div>}}

The full specification of GitHub packages is\preformatted{[<package>=][github::]<username>/<repo>[/<subdir>]
    [@<committish> | #<pull> | @[*]release]

}
\itemize{
\item \verb{<package>} is the name of the package. If this is missing, the
name of the package must match the name of the repository.
\item \verb{<username>}: GitHub user or organization name.
\item \verb{<repo>}: repository name.
\item \verb{<subdir>}: If the R package is in a subdirectory within the
repository.
\item \verb{<commitish>}: A branch name, git tag or SHA hash, to specify the
branch, tag or commit to download or install.
\item \verb{<pull>}: Pull request number, to install the branch that corresponds
to a pull request.
\item The \verb{@*release} string can be used to install the latest release.
}
}

\section{Local package trees}{


pak can install packages from package trees. You can either use the
\code{\link[=local_install]{local_install()}} function for this, or specify the \verb{local::} package
source. E.g. these are equivalent:\if{html}{\out{<div class="r">}}\preformatted{local_install("/path/to/my/package")
pkg_install("local::/path/to/my/package")
}\if{html}{\out{</div>}}

The \verb{local::} form is handy if you want to mix it with other package
specifications, e.g. to install a local package, and another standard
package:\if{html}{\out{<div class="r">}}\preformatted{pkg_install(c("local://path/to/my/package", "testthat"))
}\if{html}{\out{</div>}}
}

\section{The \code{Remotes} field}{


You can mark any regular dependency defined in the \code{Depends}, \code{Imports},
\code{Suggests} or \code{Enhances} fields as being installed from a remote
location by adding the remote location to \code{Remotes} in your
\code{DESCRIPTION} file. This will cause pak to download and install them
from the specified location, instead of CRAN.

The remote dependencies specified in \code{Remotes} is a comma separated
list of package sources:\preformatted{Remotes: <pkg-source-1>, <pkg-source-2>, [ ... ]
}

Note that you will still need add the package to one of the regular
dependency fields, i.e. \code{Imports}, \code{Suggests}, etc. Here is a concrete
example that specifies the \code{r-lib/glue} package:\preformatted{Imports: glue
Remotes: `r-lib/glue,
  r-lib/httr@v0.4,
  klutometis/roxygen#142,
  r-lib/testthat@c67018fa4970
}

The CRAN and Bioconductor repositories do not support the \code{Remotes}
field, so you need to remove this field, before submitting your package
to either of them.
}

\section{The package dependency solver}{


pak contains a package dependency solver, that makes sure that the
package source and version requirements of all packages are satisfied,
before starting an installation. For CRAN and BioC packages this is
usually automatic, because these repositories are generally in a
consistent state. If packages depend on other other package sources,
however, this is not the case.

Here is an example of a conflict detected:\preformatted{> pak::pkg_install(c("r-lib/pkgcache@conflict", "r-lib/cli@message"))
Error: Cannot install packages:
  * Cannot install `r-lib/pkgcache@conflict`.
    - Cannot install dependency r-lib/cli@master
  * Cannot install `r-lib/cli@master`.
- Conflicts r-lib/cli@message
}

\code{r-lib/pkgcache@conflict} depends on the master branch of \code{r-lib/cli},
whereas, we explicitly requested the \code{message} branch. Since it cannot
install both versions into a single library, pak quits.

When pak considers a package for installation, and the package is given
with its name only, (e.g. as a dependency of another package), then
the package may have \emph{any} package source. This is necessary, because
one R package library may contain only at most one version of a package
with a given name.

pak's behavior is best explained via an example.
Assume that you are installing a local package (see below), e.g.
\code{local::.}, and the local package depends on \code{pkgA} and \code{user/pkgB},
the latter being a package from GitHub (see below), and that \code{pkgA}
also depends on \code{pkgB}. Now pak must install \code{pkgB} \emph{and} \code{user/pkgB}.
In this case pak interprets \code{pkgB} as a package from any package source,
instead of a standard package, so installing \code{user/pkgB} satisfies both
requirements.

Note that that \code{cran::pkgB} and \code{user/pkgB} requirements result a
conflict that pak cannot resolve. This is because the first one \emph{must}
be a CRAN package, and the second one \emph{must} be a GitHub package, and
two different packages with the same cannot be installed into an R
package library.
}

\seealso{
Other package functions: 
\code{\link{lib_status}()},
\code{\link{pak}()},
\code{\link{pkg_deps}()},
\code{\link{pkg_download}()},
\code{\link{pkg_install}()},
\code{\link{pkg_remove}()},
\code{\link{pkg_status}()}
}
\concept{package functions}
