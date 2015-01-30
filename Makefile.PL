#! perl

use 5.018;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> "App::RFC",
    VERSION	=> "0.06",
    PREREQ_PM	=> { 'Getopt::Long' => 0,
		     'LWP::UserAgent' => 0,
		     'HTTP::Date' => 0,
		     'HTTP::Headers' => 0,
	     	     'Test::More' => 0 },
    EXE_FILES	=> [ qw( scripts/RFC.pl ) ],
    ABSTRACT	=> "Retrieve and display RFC by numbers",
    AUTHOR	=> "Artur Penttinen <arto+app-rfc\@cpan.org>");

exit;

package MY;

sub postamble {
	return << 'POST'
install :: /etc/rfc.conf

/etc/rfc.conf: rfc.conf
ifeq (,$(wildcard /etc/rfc.conf))
	$(NOECHO) $(ECHO) Install $< to $@
	install -b -m644 -oroot -groot $< $@
else
	$(NOECHO) $(ECHO) Install $< to $@.new
	install -b -m644 -oroot -groot $< $@.new
endif

POST
}

### That's all, folks!
