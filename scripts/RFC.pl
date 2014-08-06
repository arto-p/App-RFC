#! /usr/bin/perl

use strict;

use Getopt::Std;
use LWP::UserAgent;
use POSIX qw( strftime );

sub get_index ($);
sub get_config ($);
sub vprint ($;@);
sub run_pager ($);

our $VERSION = qw$Revision: $[1];
my $prg = ( split "[\\\\/]+",$0 )[-1];
my %opt = ( 't' => "txt", 'c' => "/etc/rfc.conf", 'v' => 0 );

getopts ("hiTsevt:c:",\%opt);

if (exists$opt{'h'} or not @ARGV) {
    print STDERR "usage: $prg {options} #rfc\n";
    exit;
}

my $conf = get_config($opt{'c'}) or die sprintf "%s fail: no config\n", $prg;

unless (-d $conf->{'cache'}->{'dir'}) {
    mkdir $conf->{'cache'}->{'dir'}, 01777 or
        die sprintf "%s fail: failed create cache dir '%s': %s\n",
            $prg, $conf->{'cache'}->{'dir'}, $!;
}

if ($ARGV[0] eq "index") {
    my $ua = new LWP::UserAgent;
    $ua->timeout(10);
    $ua->env_proxy;

    vprint "%s -> %s", $conf->{'src'}->{'index'}, $conf->{'cache'}->{'index'};
    my $resp = $ua->get($conf->{'src'}->{'index'},
                        ':content_file' => $conf->{'cache'}->{'index'});
    exit !$resp->is_success;
}

if (exists $opt{'T'}) {
    my $ind = get_index($conf->{'cache'}->{'index'});

    foreach my $rfc (@ARGV) {
	if (exists $ind->{int$ARGV[0]}) {
	    printf "%04d %s\n", $rfc, $ind->{ int $rfc };
	}
    }
    exit;
}

if (exists $opt{'s'}) {
    my $ind = get_index($conf->{'cache'}->{'index'});
    my $re = sprintf "(?%s)(?:%s)", exists $opt{'i'} ? "smi" : "sm", join "|", @ARGV;
    my @ary;

    while (my ($rfc, $text) = each %$ind) {
	push @ary, $text =~ m#$re# ? $rfc : ();
    }

    if (exists $opt{'e'}) {
        print join "\n\n", map { sprintf "%04d %s", $_, $ind->{ $_ } }
            sort { $a <=> $b } @ary; print "\n";
    }
    else {
        print join "\n", sort { $a <=> $b } @ary; print "\n";
    }
    exit;
}

my $url = sprintf $conf->{'src'}->{ $opt{'t'} }, $ARGV[0];
my $out = sprintf $conf->{'cache'}->{'out'}, $ARGV[0];

if (-f $out) {
    run_pager($out);
}

my $pid = fork();

defined($pid) or die sprintf "%s fail: failed fork: %s\n", $prg, $!;

unless ($pid) {
    my $ua = new LWP::UserAgent;
    $ua->timeout(10);
    $ua->env_proxy;
    my $resp = $ua->get($url, ':content_file' => $out);
    exit !$resp->is_success;
}

run_pager($out);

exit 1;

sub get_index ($) {
    my %hash;
    open F, $_[0] or return;
    local $/ = "";
    while (<F>) {
	chomp;
	if (m#^(\d+)\s+(.+)#sm) {
	    $hash{int$1} = $2;# =~ s#\n\s+#\n#gsmr;
	}
    }
    close F;
    return \%hash;
}

sub get_config ($) {
    open F, $_[0] or return;
    my $body = do { local $/; <F> };
    close F;

    $body =~ s#\#.*$##gm;
    $body =~ s#\\\n\s+# #gsm;

    my ( $common, %rest ) = split "\\[(.+?)\\]\\s*", $body;
    my %hash = ( 'const' => { map { split "\\s*=\\s*" }
                                  split "\\n+\\s*", $common } );

    while (my ($a, $b) = each %rest) {
        $b =~ s#\$(\w+)#$hash{'const'}->{ $1 }#gsme;
        $hash{ $a } = { map { split "\\s*=\\s*" } split "\\n+\\s*", $b };
    }

    return \%hash;
}

sub vprint ($;@) {
    my $fmt = shift;
    return unless ($opt{'v'});
    my $time = strftime "%d-%b-%Y %H:%M:%S", localtime;
    printf STDERR "[%s] $fmt\n", $time, @_;
}

sub run_pager ($) {
    foreach (1..3) {
        last if (-f $_[0]);
        sleep 1
    }
    return unless (-f $_[0]);
    unless (-t 1) {
        exec "cat", $_[0];
    }
    my @pager = split "\\s+", $conf->{'const'}->{'pager'} || $ENV{'PAGER'} || "more";
    exec @pager, $_[0];
}

__END__

=head1 NAME

RFC.pl -- Perl script for blah blah blah

=head1 SYNOPSIS

  RFC.pl {options} [arguments];

=head1 DESCRIPTION

Stub documentation for RFC.pl, created by Emacs.

=head2 OPTIONS

None by default.

=head1 SEE ALSO

Mention other useful documentation ...

=head1 AUTHOR

Artur Penttinen E<lt>artur.penttinen@stonesoft.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Artur Penttinen

=cut

### That's all, folks!
