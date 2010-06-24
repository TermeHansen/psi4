dnl
dnl  Local macros.  This are based on files provided with autoconf
dnl so the GNU GPL applies to them.
dnl
dnl
dnl See if the given C program is processed by the C compiler OK.  Does
dnl not necessarily compile.  If you want to compile give a -c to the compiler
dnl arguments.  To compile and link give a -o conftest.
dnl arg1: echo text
dnl arg2: optional code (main is already provided)
dnl arg3: additional compiler arguments
dnl arg4: success action
dnl arg5: fail action
dnl
define(AC_CC_PROCESS_CHECK,
[AC_PROVIDE([$0])dnl
ifelse([$1], , , [AC_MSG_CHECKING([for $1])]
)dnl
cat > conftest.c <<EOF
[$2]
main() {}
EOF
dnl Don't try to run the program, which would prevent cross-configuring.
if eval $CC [$3] conftest.c >/dev/null 2>&1; then
  ifelse([$4], , :, [rm -rf conftest*
  $4
])
ifelse([$5], , , [else
  rm -rf conftest*
  $5
])dnl
fi
rm -f conftest*
AC_MSG_RESULT(OK)]
)dnl
dnl
dnl
dnl See if the given C++ program is processed by the C++ compiler OK.  Does
dnl not necessarily compile.  If you want to compile give a -c to the compiler
dnl arguments.  To compile and link give a -o conftest.
dnl arg1: echo text
dnl arg2: optional code (main is already provided)
dnl arg3: additional compiler arguments
dnl arg4: success action
dnl arg5: fail action
dnl
define(AC_CXX_PROCESS_CHECK,
[AC_PROVIDE([$0])dnl
ifelse([$1], , , [AC_MSG_CHECKING([for $1])]
)dnl
cat > conftest.cc <<EOF
[$2]
int main(int argc, char** argv) {}
EOF
dnl Don't try to run the program, which would prevent cross-configuring.
if eval $CXX $CPPFLAGS [$3] conftest.cc >/dev/null 2>&1; then
  ifelse([$4], , :, [rm -rf conftest*
  $4
  AC_MSG_RESULT(yes)
])
ifelse([$5], , , [else
  rm -rf conftest*
  $5
  AC_MSG_RESULT(no)
])dnl
fi
rm -f conftest*]
)dnl
dnl
dnl
dnl Check for LaTeX
dnl
define(AC_PROG_LATEX,
[AC_PROVIDE([$0])
AC_CHECK_PROG(LATEX, latex, latex)]
)dnl

dnl
dnl Check for dvips
dnl
define(AC_PROG_DVIPS,
[AC_PROVIDE([$0])
AC_CHECK_PROG(DVIPS, dvips, dvips)]
)dnl


dnl
dnl Check for LaTeX2HTML
dnl
define(AC_PROG_LATEX2HTML,
[AC_PROVIDE([$0])
AC_CHECK_PROG(LATEX2HTML, latex2html, latex2html)]
)dnl

define(AC_PROG_BIBTEX,
[AC_PROVIDE([$0])
AC_CHECK_PROG(BIBTEX, bibtex, bibtex)]
)dnl

# Function to look for Apple vecLib on OS X systems
define(AC_CHECK_VECLIB,
[AC_PROVIDE([$0])
  echo "Entering ac_check_veclib"
  SAVE_LIBS=$LIBS
  echo "$target_vendor"
  if eval $CC 
  LIBS=$SAVE_LIBS
  echo "Finished with ac_check_veclib"
]
)

# AM_RUN_LOG(COMMAND)
# -------------------
# Run COMMAND, save the exit status in ac_status, and log it.
# (This has been adapted from Autoconf's _AC_RUN_LOG macro.)
AC_DEFUN([AM_RUN_LOG],
[{ echo "$as_me:$LINENO: $1" >&AS_MESSAGE_LOG_FD
   ($1) >&AS_MESSAGE_LOG_FD 2>&AS_MESSAGE_LOG_FD
   ac_status=$?
   echo "$as_me:$LINENO: \$? = $ac_status" >&AS_MESSAGE_LOG_FD
   (exit $ac_status); }])

# AM_PYTHON_CHECK_VERSION(PROG, VERSION, [ACTION-IF-TRUE], [ACTION-IF-FALSE])
# ---------------------------------------------------------------------------
# Run ACTION-IF-TRUE if the Python interpreter PROG has version >= VERSION.
# Run ACTION-IF-FALSE otherwise.
# This test uses sys.hexversion instead of the string equivalent (first
# word of sys.version), in order to cope with versions such as 2.2c1.
# This supports Python 2.0 or higher. (2.0 was released on October 16, 2000).
AC_DEFUN([AM_PYTHON_CHECK_VERSION],
 [prog="import sys
# split strings by '.' and convert to numeric. Append some zeros
# because we need at least 4 digits for the hex conversion.
# map returns an iterator in Python 3.0 and a list in 2.x
minver = list(map(int, '$2'.split('.'))) + [[0, 0, 0]]
minverhex = 0
# xrange is not present in Python 3.0 and range returns an iterator
for i in list(range(0, 4)): minverhex = (minverhex << 8) + minver[[i]]
sys.exit(sys.hexversion < minverhex)"
  AS_IF([AM_RUN_LOG([$1 -c "$prog"])], [$3], [$4]) ])

# AC_PYTHON([MINIMUM-VERSION],[ACTION-IF-FOUND],[ACTION-IF-NOTFOUND])
# -------------------------------------------------------------------
# Run ACTION-IF-FOUND if a Python interpreter meeting the
# MINIMUM-VERSION requirement is found. Else Run ACTION-IF-NOTFOUND
# if no valid Python interpreter is found. Can be overriden if the
# user sets the PYTHON environmental variable.
AC_DEFUN([AC_PYTHON],
[
  AC_ARG_VAR(PYTHON,
[The `Python' interpreter to use. Defaults to the first program found
out of: `python', `python2', `python2.6', `python2.5', `python2.4'.
Make sure you have installed the developer libraries, too.])
  dnl Find a Python interpreter and its matching config program.
  m4_define_default([_AM_PYTHON_INTERPRETER_LIST],
                    [python python2 python2.6 dnl
python2.5 python2.4])

  # turn back to default flags
  ac_save_CPPFLAGS="$CPPFLAGS"
  ac_save_LIBS="$LIBS"
  
  m4_if([$1],[],[
    dnl No version check is needed
    if test -z "$PYTHON"; then
      AC_PATH_PROGS([PYTHON], _AM_PYTHON_INTERPRETER_LIST, :)
    fi
    am_display_PYTHON=python
  ],[
    dnl A Version check is needed.
    if test -n "$PYTHON"; then
      # If the user set $PYTHON, use it and don't search something else.
      AC_MSG_CHECKING([whether $PYTHON version >= $1])
      AM_PYTHON_CHECK_VERSION([$PYTHON], [$1],
                              [AC_MSG_RESULT(yes)],
                              [AC_MSG_ERROR(too old)])
      am_display_PYTHON=$PYTHON
    else
      # Otherwise, try each interpreter until we find one that satisfies VERSION
      AC_CACHE_CHECK([for a Python interpreter with version >= $1],
        [am_cv_pathless_PYTHON],[
        for am_cv_pathless_PYTHON in _AM_PYTHON_INTERPRETER_LIST none; do
          test "$am_cv_pathless_PYTHON" = none && break
          AM_PYTHON_CHECK_VERSION([$am_cv_pathless_PYTHON], [$1], [break])
        done])
      # Set $PYTHON to the absolute pather of $am_cv_pathless_PYTHON
      if test "$am_cv_pathless_PYTHON" = none; then
        PYTHON=:
      else
        AC_PATH_PROG([PYTHON], [$am_cv_pathless_PYTHON])
      fi
      am_display_PYTHON=$am_cv_pathless_PYTHON
    fi
  ])
 
  if test "$PYTHON" = :; then
    dnl Run any user-specific action, or abort.
    m4_default([$3], [AC_MSG_ERROR([no suitable Python interpreter found])])
  else      
    dnl Query Python for its version number.
    AC_CACHE_CHECK([for $am_display_PYTHON version], [am_cv_python_version],
      [am_cv_python_version=`$PYTHON -c "import sys; sys.stdout.write(sys.version[[:3]])"`])
    AC_SUBST([PYTHON_VERSION], [$am_cv_python_version])

    dnl Okay, if we know the name of the Python interpreter then we know the
    dnl name of the python config program
    AC_CACHE_CHECK([for $am_display_PYTHON include statements], [am_cv_python_include],
      [am_cv_python_include=`${PYTHON}-config --includes`])
    AC_SUBST([PYTHON_INCLUDE], [$am_cv_python_include])

    AC_CACHE_CHECK([for $am_display_PYTHON linker flags], [am_cv_python_ldflags],
      [am_cv_python_ldflags=`${PYTHON}-config --ldflags`])
    AC_SUBST([PYTHON_LDFLAGS], [$am_cv_python_ldflags])

    #
    # final check to see if everything compiles alright
    #
    AC_MSG_CHECKING([consistency of all components of python development environment])
    AC_LANG_PUSH([C])
    # save current global flags
    LIBS="$ac_save_LIBS $PYTHON_LDFLAGS"
    CPPFLAGS="$ac_save_CPPFLAGS $PYTHON_INCLUDE"
    AC_TRY_LINK([
        #include <Python.h>
    ],[
        Py_Initialize();
    ],[pythonexists=yes],[pythonexists=no])

    AC_MSG_RESULT([$pythonexists])

        if test ! "$pythonexists" = "yes"; then
       AC_MSG_ERROR([
  Could not link test program to Python. Maybe the main Python library has been
  installed in some non-standard library path. If so, pass it to configure,
  via the LDFLAGS environment variable.
  Example: ./configure LDFLAGS="-L/usr/non-standard-path/python/lib"
  ============================================================================
   ERROR!
   You probably have to install the development version of the Python package
   for your distribution.  The exact name of this package varies among them.
  ============================================================================
       ])
      PYTHON_VERSION=""
    fi
    AC_LANG_POP
    # turn back to default flags
    CPPFLAGS="$ac_save_CPPFLAGS"
    LIBS="$ac_save_LIBS"

    dnl This is the end of all things
    $2
  fi
])
# ===========================================================================
#            http://www.nongnu.org/autoconf-archive/ax_openmp.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_OPENMP([ACTION-IF-FOUND[, ACTION-IF-NOT-FOUND]])
#
# DESCRIPTION
#
#   This macro tries to find out how to compile programs that use OpenMP a
#   standard API and set of compiler directives for parallel programming
#   (see http://www-unix.mcs/)
#
#   On success, it sets the OPENMP_CFLAGS/OPENMP_CXXFLAGS/OPENMP_F77FLAGS
#   output variable to the flag (e.g. -omp) used both to compile *and* link
#   OpenMP programs in the current language.
#
#   NOTE: You are assumed to not only compile your program with these flags,
#   but also link it with them as well.
#
#   If you want to compile everything with OpenMP, you should set:
#
#       CFLAGS="$CFLAGS $OPENMP_CFLAGS"
#       #OR#  CXXFLAGS="$CXXFLAGS $OPENMP_CXXFLAGS"
#       #OR#  FFLAGS="$FFLAGS $OPENMP_FFLAGS"
#
#   (depending on the selected language).
#
#   The user can override the default choice by setting the corresponding
#   environment variable (e.g. OPENMP_CFLAGS).
#
#   ACTION-IF-FOUND is a list of shell commands to run if an OpenMP flag is
#   found, and ACTION-IF-NOT-FOUND is a list of commands to run it if it is
#   not found. If ACTION-IF-FOUND is not specified, the default action will
#   define HAVE_OPENMP.
#
# LICENSE
#
#   Copyright (c) 2008 Steven G. Johnson <stevenj@alum.mit.edu>
#
#   This program is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation, either version 3 of the License, or (at your
#   option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
#   Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program. If not, see <http://www.gnu.org/licenses/>.
#
#   As a special exception, the respective Autoconf Macro's copyright owner
#   gives unlimited permission to copy, distribute and modify the configure
#   scripts that are the output of Autoconf when processing the Macro. You
#   need not follow the terms of the GNU General Public License when using
#   or distributing such scripts, even though portions of the text of the
#   Macro appear in them. The GNU General Public License (GPL) does govern
#   all other use of the material that constitutes the Autoconf Macro.
#
#   This special exception to the GPL applies to versions of the Autoconf
#   Macro released by the Autoconf Archive. When you make and distribute a
#   modified version of the Autoconf Macro, you may extend this special
#   exception to the GPL to apply to your modified version as well.

AC_DEFUN([AX_OPENMP], [
AC_PREREQ(2.59) dnl for _AC_LANG_PREFIX

AC_CACHE_CHECK([for OpenMP flag of _AC_LANG compiler], ax_cv_[]_AC_LANG_ABBREV[]_openmp, [save[]_AC_LANG_PREFIX[]FLAGS=$[]_AC_LANG_PREFIX[]FLAGS
ax_cv_[]_AC_LANG_ABBREV[]_openmp=unknown
# Flags to try:  -fopenmp (gcc), -openmp (icc), -mp (SGI & PGI),
#                -xopenmp (Sun), -omp (Tru64), -qsmp=omp (AIX), none
ax_openmp_flags="-fopenmp -openmp -mp -xopenmp -omp -qsmp=omp none"
if test "x$OPENMP_[]_AC_LANG_PREFIX[]FLAGS" != x; then
  ax_openmp_flags="$OPENMP_[]_AC_LANG_PREFIX[]FLAGS $ax_openmp_flags"
fi
for ax_openmp_flag in $ax_openmp_flags; do
  case $ax_openmp_flag in
    none) []_AC_LANG_PREFIX[]FLAGS=$save[]_AC_LANG_PREFIX[] ;;
    *) []_AC_LANG_PREFIX[]FLAGS="$save[]_AC_LANG_PREFIX[]FLAGS $ax_openmp_flag" ;;
  esac
#  AC_TRY_LINK_FUNC(omp_set_num_threads,
#	[ax_cv_[]_AC_LANG_ABBREV[]_openmp=$ax_openmp_flag; break])
  AC_TRY_LINK([#include <omp.h>], [ omp_get_num_threads(); return 0; ],
	[ax_cv_[]_AC_LANG_ABBREV[]_openmp=$ax_openmp_flag; break])
done
[]_AC_LANG_PREFIX[]FLAGS=$save[]_AC_LANG_PREFIX[]FLAGS
])
if test "x$ax_cv_[]_AC_LANG_ABBREV[]_openmp" = "xunknown"; then
  m4_default([$2],:)
else
  if test "x$ax_cv_[]_AC_LANG_ABBREV[]_openmp" != "xnone"; then
    OPENMP_[]_AC_LANG_PREFIX[]FLAGS=$ax_cv_[]_AC_LANG_ABBREV[]_openmp
  fi
  m4_default([$1], [AC_DEFINE(HAVE_OPENMP,1,[Define if OpenMP is enabled])])
fi
])dnl AX_OPENMP
