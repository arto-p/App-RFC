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

SPEC    = perl-$(DISTNAME).spec
BASE    = $(shell rpmspec -q --builtrpms --define="_VERSION $(VERSION)" $(SPEC))

RPMBUILD = rpmbuild -ba --rmsource --clean --quiet --define="_VERSION $(VERSION)"

NAME.srpm = $(BASE:.noarch=.src.rpm)
NAME.rpm = $(BASE:.noarch=.noarch.rpm)
NAME.tar = $(DISTNAME)-$(VERSION).tar.gz

RPMDIR.noarch = $(HOME)/rpmbuild/RPMS/noarch
RPMDIR.src = $(HOME)/rpmbuild/SOURCES
RPMDIR.srpms = $(HOME)/rpmbuild/SRPMS

DIST    = $(shell rpm --eval --define="_VERSION $(VERSION)" "%dist")
RPMS    = $(HOME)/rpmbuild/RPMS/noarch/perl-$(DISTVNAME)-1$(DIST).noarch.rpm
SOURCE  = $(HOME)/rpmbuild/SOURCES/perl-$(DISTVNAME).tar.gz

rpm: $(RPMDIR.noarch)/$(NAME.rpm) $(RPMDIR.srpms)/$(NAME.srpm)

sign: $(RPMDIR.noarch)/$(NAME.rpm) $(RPMDIR.srpms)/$(NAME.srpm)
	rpmsign --addsign $^
	$(NOECHO)echo -e "RPMs signed:\\n\\t$(RPMDIR.noarch)/$(NAME.rpm)\\n\\t$(RPMDIR.srpms)/$(NAME.srpm)"

$(RPMDIR.noarch)/$(NAME.rpm): $(SPEC) $(RPMDIR.src)/$(NAME.tar)
	$(RPMBUILD) $<
	$(NOECHO)echo "RPM built: $@"

$(RPMDIR.src)/$(NAME.tar): .git
	git archive --format=tar.gz --prefix=$(NAME.tar:.tar.gz=)/ \
		-o $@ master

POST
}

### That's all, folks!
