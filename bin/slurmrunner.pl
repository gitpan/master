#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  slurmrunner.pl
#
#        USAGE:  ./slurmrunner.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06/24/2014 10:37:20 AM
#     REVISION:  ---
#===============================================================================

package Main;

use lib "/home/guests/jir2004/perlmodule/Runner-Init/lib";

use Moose;
use Carp::Always;
use Data::Dumper;

extends 'Runner::Slurm';

Runner::Slurm->new_with_options(infile => "/home/guests/jir2004/perlmodule/Slurm-Submitter/bin/example/testcommand.in")->run;

1;
