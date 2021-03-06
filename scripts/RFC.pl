#! /usr/bin/perl

use strict;

use Getopt::Long;
use LWP::UserAgent;
use HTTP::Date;
use HTTP::Headers;
use POSIX qw( strftime );
use App::RFC;

sub vprint ($;@);
sub run_pager ($;$);
sub match ($@);
sub get_index ($);

our $VERSION = qw$Revision: $[1] || "0.05";
my $prg = ( split "[\\\\/]+",$0 )[-1];

my ( $help, $verbose, $config, $enhanced, $force, $search, $ignore,
     $diff, $display_url, $output, $status ) =
    ( 0, 0, "/etc/rfc.conf", 1, 0, 0, 0, 0, 0 );

my %status = ( 'best' => qr#BEST\s+CURRENT\s+PRACTICE#,
               'draft' => qr#DRAFT\s+STANDARD#,
               'experimental' => qr#EXPERIMENTAL#,
               'historic' => qr#HISTORIC#,
               'informational' => qr#INFORMATIONAL#,
               'internet-standard' => qr#INTERNET\s+STANDARD#,
               'proposed-standard' => qr#PROPOSED\s+STANDARD#,
               'unknown' => qr#UNKNOWN# );

Getopt::Long::Configure("bundling");
GetOptions('help|h'	=> \$help,
           'verbose|v+'	=> \$verbose,
           'conf|c=s'	=> \$config,
           'enhanced|e'	=> \$enhanced,
           'force|f'	=> \$force,
           'search|s'	=> \$search,
           'diff|D'	=> \$diff,
           'url|u'	=> \$display_url,
           'status|S=s'	=> \$status,
           'out|o=s'	=> \$output,
           'ignore|i!'	=> \$ignore) or
    die sprintf "%s fail: error in command line arguments\n", $prg;

if ($help or not @ARGV) {
    print STDERR "usage: $prg {options} #rfc\n",
        "\t--help\t\t- short help message\n" ,
        "\t--verbose\t- be more verbose\n",
        "\t--conf file\t- config file [$config]\n",
        "\t--enhanced\t- print enhanced info\n",
        "\t--force\t\t- force operation\n",
        "\t--diff\t\t- when update index print difference\n",
        "\t--search\t- search operation\n",
        "\t--out file\t- output direct to file (- == stdout)\n",
        "\t--url\t- display url before download\n",
        "\t--ignore\t- ignore case in search\n",
        "\t--status status - rfc's status\n";
    print STDERR "\t  Status: @{[join', ', keys %status]}\n";
    exit;
}

my $conf = App::RFC::get_config($config) or die sprintf "%s fail: no config\n", $prg;

unless (-d $conf->{'cache'}->{'dir'}) {
    mkdir $conf->{'cache'}->{'dir'}, 01777 or
        die sprintf "%s fail: failed create cache dir '%s': %s\n",
            $prg, $conf->{'cache'}->{'dir'}, $!;
}

my $headers = new HTTP::Headers('host' => ( split "/", $conf->{'src'}->{'index'} )[2],
				%{ $conf->{ 'headers' } });

my $ua = new LWP::UserAgent('default_headers' => $headers);

$ua->timeout($conf->{'const'}->{'timeout'} || 10);
$ua->env_proxy;

if (exists $conf->{'const'}->{'user-agent'}) {
    $ua->agent($conf->{'const'}->{'user-agent'});
}

if ($ARGV[0] eq "index") {

    my $temp_index = sprintf "%s.%d", $conf->{'cache'}->{'index'}, $$;
    my $local_time = time2str(( stat $conf->{'cache'}->{'index'} )[10] || 0);

    vprint "%s -> %s [%s]", $conf->{'src'}->{'index'},
	$conf->{'cache'}->{'index'}, $local_time;

    unless ($force) {
	$ua->default_header('if_modified_since' => $local_time);
    }

    my $response = $ua->get($conf->{'src'}->{'index'},
		            ':content_file' => $temp_index);
    unless ($response->is_success) {
        unlink $temp_index;
	if ($response->code == 304) {
	    exit;
	}
        die sprintf "%s fail: failure retrieve %s: %s\n",
            $prg, $conf->{'src'}->{'index'}, $response->status_line;
    }

    if ($diff) {
        my $old = App::RFC::get_rfc_index($conf->{'cache'}->{'index'});
        my $new = App::RFC::get_rfc_index($temp_index);

	my @new = App::RFC::rfc_index_new($new, $old);
	my @diff = App::RFC::rfc_index_diff($new, $old);

        if (@new) {
            print "New rfc(s):\n\n";
            foreach my $num (@new) {
                if ($enhanced) {
                    printf "%04d %s\n\n", $num, $new->{ $num };
                }
                else {
                    print $num, "\n";
                }
            }
        }

        if (@diff) {
            print "Changed rfc(s):\n\n";
            foreach my $num (@diff) {
                if ($enhanced) {
                    printf "%04d %s\n     -->\n     %s\n\n", $num,
                        $old->{ $num }, $new->{ $num };
                }
                else {
                    print $num, "\n";
                }
            }
        }
    }

    rename $temp_index, $conf->{'cache'}->{'index'} or
        die sprintf "%s fail: error rename index file: %s\n", $prg, $!;
    exit;
}

if ($search) {
    my $ind = get_index($conf->{'cache'}->{'index'});

    my @re = ( qr#@{[sprintf "%s(?:%s)", $ignore ? "(?i)" : "", join "|", @ARGV]}#o );
    if (defined $status) {
        unshift @re, qr#\(Status:\s+$status{ $status }\)#o;
    }

    my @ary;
    while (my ($rfc, $text) = each %$ind) {
	push @ary, match($text, @re) ? $rfc : ();
    }

    exit unless @ary;

    if ($enhanced) {
        print join "\n\n", map { sprintf "%04d %s", $_, $ind->{ $_ } }
            sort { $a <=> $b } @ary; print "\n";
    }
    else {
        print join "\n", sort { $a <=> $b } @ary; print "\n";
    }
    exit;
}

$ARGV[0] =~ s#^rfc##i;

my $url = sprintf $conf->{'src'}->{'txt'}, $ARGV[0];
my $out = sprintf $conf->{'cache'}->{'out'}, $ARGV[0];

if ($display_url == 1) {
    print $url, "\n";
    exit;
}

if (-f $out) {
    run_pager($out, $output);
}

my $pid = fork();

defined($pid) or die sprintf "%s fail: failed fork: %s\n", $prg, $!;

unless ($pid) {
    my $resp = $ua->get($url, ':content_file' => $out);
    exit !$resp->is_success;
}

run_pager($out, $output);

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

sub vprint ($;@) {
    my $fmt = shift;
    return unless ($verbose);
    my $time = strftime "%d-%b-%Y %H:%M:%S", localtime;
    printf STDERR "[%s] $fmt\n", $time, @_;
}

sub run_pager ($;$) {
    foreach (1..3) {
        last if (-f $_[0]);
        sleep 1
    }
    return unless (-f $_[0]);
    unless (-t 1) {
        exec "cat", $_[0];
    }
    if (defined $_[1]) {
        unless ($_[1] eq "-") {
	    open STDOUT, "> $_[1]" or die sprintf "%s fail: can't open to out '%s': %s\n", $prg, $_[1], $!;
        }
	exec "cat", $_[0];
    }
    my @pager = split "\\s+", $conf->{'const'}->{'pager'} || $ENV{'PAGER'} || "more";
    exec @pager, $_[0];
}

sub match ($@) {
    my $txt = shift;

    foreach my $re ( @_ ) {
        $txt =~ m#$re#sm or return 0;
    }
    return 1;
}

__END__

=head1 NAME

RFC.pl -- Perl script for get and display rfc by number.

=head1 SYNOPSIS

  RFC.pl {options} [arguments]

=head1 DESCRIPTION

This script can retrieve and display rfc by number and search locally
through rfc-index.txt and display result.

=head2 OPTIONS

=over 2

=item I<--help|h>

Short help message.

=item I<--conf|c=file>

Path to config file (default is C</etc/rfc.conf>). Format of config file see
in L<CONFIG FILE FORMAT>.

=item I<--search|s>

Search through local rfc-index.txt file and display result. Argument is
perl regular expression for searching.

=item I<--status=$status>

Additional filter for rfc' B<"Status"> (see RFC 2026 and RFC 6410)
keywords. Possibly values:

=over 4

=item I<best> -- C<BEST CURRENT PRACTICE>

=item I<draft> -- C<DRAFT STANDARD>

=item I<experimental> -- C<EXPERIMENTAL>

=item I<historic> -- C<HISTORIC>

=item I<informational> -- C<INFORMATIONAL>

=item I<internet-standard> -- C<INTERNET STANDARD>

=item I<proposed-standard> -- C<PROPOSED STANDARD>

=item I<inknown> -- C<UNKNOWN>

=back

=item I<--ignore|i>

Do case-insensitive searching.

=item I<--enhanced|e>

For "search" operation, print out "extended" result, full header
for rfc, rather only rfc number.

=item I<--verbose|v>

Be a more verbose.

=item I<--diff|D>

When download new C<rfc-index.txt> generate list of new and different
rfcs.

=item I<--out|o>

Print out rfc to file (or strdout in case of C<->).

=back

=head1 CONFIG FILE FORMAT

Config file has INI format. First, unnamed section contains
common variables which may substitute variables in next sections.
Also here may be defined C<pager> option, contains "pager" program
for display rfc (e.g. I<less>).

B<src> section contains C<index> option -- url for rfc-index.txt file.
Also there must be C<txt> option -- url for rfc by number in C<sprintf>
format (e.g. C<url-to-rfc%04d.txt>).

And B<cache> section contains options related to I<caching> results:
C<rfc-index.txt> and rfcs itself: C<dir> -- directory for cache,
C<out> -- name for rfc cache result and C<index> -- file for rfc-index.txt.

=head1 SEE ALSO

L<http://tools.ietf.org>

=head1 AUTHOR

Artur Penttinen E<lt>arto+app-rfc@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Artur Penttinen

=cut

### That's all, folks!
