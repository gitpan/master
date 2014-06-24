#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  mcerunner.pl
#
#        USAGE:  ./mcerunner.pl  
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
#      CREATED:  06/15/2014 01:05:23 PM
#     REVISION:  ---
#===============================================================================

package Main;

use strict;
use warnings;

use lib "/home/guests/jir2004/perlmodule/Runner-Init/lib";

use Moose;
use Carp::Always;
use Data::Dumper;

#use Runner::MCE;
extends 'Runner::MCE';

Runner::MCE->new_with_options(infile => "/home/guests/jir2004/perlmodule/Slurm-Submitter/bin/example/testcommand.in")->go;

1;
