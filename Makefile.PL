use 5.018;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> "App::RFC",
    VERSION	=> "0.01",
    PREREQ_PM	=> { 'Getopt::Std' => 0 },
    EXE_FILES	=> [ qw( scripts/RFC.pl ) ],
    ABSTRACT	=> "Retrieve and display RFC by numbers",
    AUTHOR	=> "Artur Penttinen <arto+app-rfc\@cpan.org>");

exit;
