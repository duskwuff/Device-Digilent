use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Device::Digilent',
    VERSION_FROM => 'lib/Device/Digilent.pm',
    AUTHOR       => 'Dusk (dusk@woofle.net)',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
        'Test::Simple' => 0.44,
    },
);
