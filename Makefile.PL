use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Runner::Init',
    AUTHOR           => q{Jillian Rowe <jillian.e.rowe@gmail.com>},
    VERSION_FROM     => 'lib/Runner/Init.pm',
    ABSTRACT_FROM    => 'lib/Runner/Init.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    "EXE_FILES" => [
        "bin/mcerunner.pl", "bin/parallelrunner.pl", "bin/slurmrunner.pl",
    ],
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'Carp' => 0,
        'File::Path' => 0,
        'File::Temp' => 0,
        'IO::File' => 0,
        'IO::Select' => 0,
        'Cwd' => 0,
        'IPC::Open3' => 0,
        'Symbol' => 0,
        'Template' => 0,
        'Log::Log4perl' => 0,
        'DateTime' => 0,
        'DateTime::Format::Duration' => 0,
        'Data::Dumper' => 0,
        'Moose' => 0,
        'MooseX::SimpleConfig' => 0,
        'Moose::Util::TypeConstraints' => 0,
        'MooseX::Getopt' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Runner-Init-*' },
);
