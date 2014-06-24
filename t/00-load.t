#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Runner::Init' ) || print "Bail out!\n";
    use_ok( 'Runner::MCE' ) || print "Bail out!\n";
    use_ok( 'Runner::Threads' ) || print "Bail out!\n";
    use_ok( 'Runner::Slurm' ) || print "Bail out!\n";
}

diag( "Testing Runner::Init $Runner::Init::VERSION, Perl $], $^X" );
