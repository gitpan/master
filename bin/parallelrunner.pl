#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  parallelrunner.pl
#
#        USAGE:  ./parallelrunner.pl  
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
#      CREATED:  06/17/2014 09:50:13 AM
#     REVISION:  ---
#===============================================================================

package Main;

use lib "/home/guests/jir2004/perlmodule/Runner-Init/lib";

use Moose;
use Carp::Always;
use Data::Dumper;

extends 'Runner::Threads';

Runner::Threads->new_with_options(infile => "/home/guests/jir2004/perlmodule/Slurm-Submitter/bin/example/testcommand.in")->go;

1;
