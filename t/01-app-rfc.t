#! perl

use strict;
use warnings;

use Test::More tests => 11;

my $outdir = "/tmp/rfcs";
my $prog = -f "blib/script/RFC.pl" ? "blib/script/RFC.pl" : "../blib/script/RFC.pl";
my $conf = -f "t/rfc-config" ? "t/rfc-config" : "rfc-config";

my @exe = ( $^X, $prog, "-c$conf" );

diag("EXE: @exe");

if (-d $outdir) {
    unlink <$outdir/*>;
    rmdir $outdir;
}

## Index file
my $ret = system @exe, "index";
ok($ret == 0, "execute @exe index");
ok(-f "$outdir/rfc-index.txt", "rfc-index.txt");

$ret = system "@exe -s 'Hypertext.*Protocol' > $outdir/hypertext-protocol1.txt";
ok($ret == 0, "execute grep");
my @out1 = do { open F, "$outdir/hypertext-protocol1.txt" and <F> }; chomp @out1;
ok($out1[0] == 1945 && $out1[1] == 2068, "result ok");

$ret = system "@exe -s 'hypertext.*protocol' > $outdir/hypertext-protocol2.txt";
ok($ret == 0, "execute grep");
my @out2 = do { open F, "$outdir/hypertext-protocol2.txt" and <F> }; chomp @out2;
ok($#out2 == 0, "result ok");

$ret = system "@exe -si 'hypertext.*protocol' > $outdir/hypertext-protocol3.txt";
ok($ret == 0, "execute grep");
my @out3 = do { open F, "$outdir/hypertext-protocol3.txt" and <F> }; chomp @out3;
ok($out3[0] == 1945 && $out3[1] == 2068, "result ok");

$ret = system "@exe 2616 > $outdir/2616.out";
ok($ret == 0, "get rfc 2616");
my $body = do { local $/; open F, "$outdir/2616.out" and <F> };
ok(length $body > 1024, "rfc 2616 body");
like($body, qr/Request for Comments: 2616/, "rfc 2616 body");

exit;


