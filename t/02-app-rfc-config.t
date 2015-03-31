#! perl

use strict;
use warnings;

use Test::More tests => 11;
BEGIN{ use_ok("App::RFC"); };

my $file = -f "rfc.conf" ? "rfc.conf" : "../rfc.conf";

my $conf = App::RFC::get_config($file, "main");

ok(defined $conf, "config read");

ok(exists $conf->{'main'}, "main section");
ok(exists $conf->{'src'}, "src section");
ok(exists $conf->{'cache'}, "cache section");

ok(exists $conf->{'main'}->{'base'}, "main->base option");
ok(exists $conf->{'main'}->{'baseurl'}, "main->baseurl option");

ok(exists $conf->{'src'}->{'index'}, "src->index option");
ok(exists $conf->{'src'}->{'txt'}, "src->txt option");

ok(exists $conf->{'cache'}->{'dir'}, "cache->dir option");
ok(exists $conf->{'cache'}->{'index'}, "cache->index option");

exit;


