#!/bin/csh 
#
# DART software - Copyright 2004 - 2013 UCAR. This open source software is
# provided by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# DART $Id$

#----------------------------------------------------------------------
# 'preprocess' is a program that culls the appropriate sections of the
# observation module for the observations types in 'input.nml'; the 
# resulting source file is used by all the remaining programs, 
# so this MUST be run first.
#----------------------------------------------------------------------

# 1 is true, 0 is false

if ( $#argv == 1 && "$1" == "-mpi" ) then
  set with_mpi = 1 
else if ( $#argv == 1 && "$1" == "-nompi" ) then
  set with_mpi = 0
else  # default
  set with_mpi = 1
endif

\rm -f preprocess *.o *.mod
\rm -f ../../../obs_def/obs_def_mod.f90
\rm -f ../../../obs_kind/obs_kind_mod.f90

set MODEL = "ROMS"

@ n = 1

echo
echo
echo "---------------------------------------------------------------"
echo "${MODEL} build number ${n} is preprocess"

csh  mkmf_preprocess
make || exit $n

./preprocess || exit 99

#----------------------------------------------------------------------
# Build all the single-threaded targets
#----------------------------------------------------------------------

foreach TARGET ( mkmf_* )

   set PROG = `echo $TARGET | sed -e 's#mkmf_##'`

   switch ( $TARGET )
   case mkmf_preprocess:
      breaksw
   case mkmf_filter:
   case mkmf_model_mod_check:
   case mkmf_perfect_model_obs:
      if ( $with_mpi ) then
         breaksw
      endif
   default:
      @ n = $n + 1
      echo
      echo "---------------------------------------------------"
      echo "${MODEL} build number ${n} is ${PROG}" 
      \rm -f ${PROG}
      csh $TARGET || exit $n
      make        || exit $n
      #echo 'removing all files between serial builds'
      #\rm -f *.o *.mod
      breaksw
   endsw
end

\rm -f *.o *.mod input.nml*_default

if ( $with_mpi ) then
  echo "Success: All single task DART programs compiled."  
  echo "Script now compiling MPI parallel versions of the DART programs."
else if ( ! $with_mpi ) then
  echo "Success: All single task DART programs compiled."  
  echo "Script is exiting without building the MPI version of the DART programs."
  exit 0
else
  echo ""
  echo "Success: All single task DART programs compiled."  
  echo "Script now compiling MPI parallel versions of the DART programs."
  echo "Run the quickbuild.csh script with a -nompi argument or"
  echo "edit the quickbuild.csh script and add an exit line"
  echo "to bypass compiling with MPI to run in parallel on multiple cpus."
  echo ""
endif

#----------------------------------------------------------------------
# to disable an MPI parallel version of filter for this model, 
# call this script with the -nompi argument, or if you are never going to
# build with MPI, add an exit before the entire section above.
#----------------------------------------------------------------------

#----------------------------------------------------------------------
# Build the MPI-enabled target(s) 
#----------------------------------------------------------------------

foreach TARGET ( mkmf_filter mkmf_model_mod_check mkmf_perfect_model_obs )

   set PROG = `echo $TARGET | sed -e 's#mkmf_##'`

   @ n = $n + 1
   echo
   echo "---------------------------------------------------"
   echo "${MODEL} build number ${n} is ${PROG}" 
   \rm -f ${PROG}
   csh $TARGET -mpi || exit $n
   make             || exit $n
   #echo 'removing all files between parallel builds'
   #\rm -f *.o *.mod

end

\rm -f *.o *.mod input.nml*_default

exit 0

# <next few lines under version control, do not edit>
# $URL$
# $Revision$
# $Date$
