#! perl

use strict;
use warnings;

use Test::More tests => 14;
use File::Copy;

my $outdir = "/tmp/rfcs";
my $prog = -f "blib/script/RFC.pl" ? "blib/script/RFC.pl" : "../blib/script/RFC.pl";
my $conf = -f "t/rfc-config" ? "t/rfc-config" : "rfc-config";

my $index_old = -f "t/rfc-index.txt" ?
    "t/rfc-index.txt" : "rfc-index.txt";
my $index_new = -f "t/rfc-index.txt.new" ?
    "t/rfc-index.txt.new" : "rfc-index.txt.new";
my $rfc2616 = -f "t/rfc2616.txt" ? "t/rfc2616.txt" : "rfc2616.txt";

my @exe = ( $^X, $prog, "-c$conf" );

diag("EXE: @exe");

if (-d $outdir) {
    unlink <$outdir/*>;
    rmdir $outdir;
}

copy $index_old, "/tmp/rfc-index.txt";
copy $rfc2616, "/tmp/rfc2616.txt";

## Index file
my $ret = system @exe, "index";
ok($ret == 0, "execute @exe index");
ok(-f "$outdir/rfc-index.txt", "rfc-index.txt");

## Search
$ret = system "@exe -s 'Hypertext.*Protocol' > $outdir/hypertext-protocol1.txt";
ok($ret == 0, "execute grep 'Hypertext.*Protocol'");
my @out1 = do { open F, "$outdir/hypertext-protocol1.txt" and <F> }; chomp @out1;
ok($#out1 > 1 && $out1[0] == 1945 && $out1[1] == 2068, "result ok");

$ret = system "@exe -s 'hypertext.*protocol' > $outdir/hypertext-protocol2.txt";
ok($ret == 0, "execute grep 'hypertext.*protocol'");
my @out2 = do { open F, "$outdir/hypertext-protocol2.txt" and <F> }; chomp @out2;
ok($#out2 == -1, "result ok");

$ret = system "@exe -si 'hypertext.*protocol' > $outdir/hypertext-protocol3.txt";
ok($ret == 0, "execute grep 'hypertext.*protocol'");
my @out3 = do { open F, "$outdir/hypertext-protocol3.txt" and <F> }; chomp @out3;
ok($#out3 > 1 && $out3[0] == 1945 && $out3[1] == 2068, "result ok");

# Retrieve rfc
$ret = system "@exe 2616 > $outdir/2616.out";
ok($ret == 0, "get rfc 2616");
my $body = do { local $/; open F, "$outdir/2616.out" and <F> };
ok(length $body > 1024, "rfc 2616 body");
like($body, qr/Request for Comments: 2616/, "rfc 2616 body");

# Update index
copy $index_new, "/tmp/rfc-index.txt";
$ret = system "@exe -Df -e index > $outdir/index-diff";
ok($ret == 0, "index + diff");
my $diff = do { local $/; open F, "$outdir/index-diff" and <F> };
like($diff, qr/(?sm)New rfc\(s\):\s+7316.+?7318/, "new rfcs");
like($diff, qr/(?sm)Changed rfc\(s\):\s+7310/, "changed rfc");

#diag($diff);

unlink "/tmp/rfc-index.txt";

exit;


