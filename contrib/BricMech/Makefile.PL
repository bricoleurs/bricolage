use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Bric::Mech',
    VERSION_FROM      => 'lib/Bric/Mech.pm',
    PREREQ_PM         => {
        WWW::Mechanize => '1.10',
        HTML::TokeParser::Simple => '0',  # XXX: not sure
    },
    ABSTRACT_FROM  => 'lib/Bric/Mech.pm',
    AUTHOR         => 'Scott Lanning <lannings@who.int>',
);
