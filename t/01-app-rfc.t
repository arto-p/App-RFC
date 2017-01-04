#! perl

use strict;
use warnings;

use Test::More tests => 18;
use File::Copy;

my $outdir = "/tmp/rfcs";
my $prog = -f "blib/script/RFC.pl" ? "blib/script/RFC.pl" : "../blib/script/RFC.pl";
my $conf = -f "t/rfc-config" ? "t/rfc-config" : "rfc-config";

my $index_old = -f "t/rfc-index.txt" ?
    "t/rfc-index.txt" : "rfc-index.txt";
my $index_new = -f "t/rfc-index.txt.new" ?
    "t/rfc-index.txt.new" : "rfc-index.txt.new";
my $rfc2616 = -f "t/rfc2616.txt" ? "t/rfc2616.txt" : "rfc2616.txt";

my @exe = ( $^X, "-Mblib", $prog, "-c$conf" );

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
my @out1 = do { local $/=""; open F, "$outdir/hypertext-protocol1.txt"; <F> };
ok($#out1 > 1, "Hypertext Protocol result $#out1");
like($out1[0], qr#^1945 #, "Hypertext Transfer Protocol -- HTTP/1.0");
like($out1[1], qr#^2068 #, "Hypertext Transfer Protocol -- HTTP/1.1");

$ret = system "@exe -s 'hypertext.*protocol' > $outdir/hypertext-protocol2.txt";
ok($ret == 0, "execute grep 'hypertext.*protocol'");
my @out2 = do { local $/=""; open F, "$outdir/hypertext-protocol2.txt" and <F> };
ok($#out2 == -1, "result ok");

$ret = system "@exe -si 'hypertext.*protocol' > $outdir/hypertext-protocol3.txt";
ok($ret == 0, "execute grep 'hypertext.*protocol'");
my @out3 = do { local $/=""; open F, "$outdir/hypertext-protocol3.txt" and <F> };
ok($#out3 > 1, "result ok");
like($out3[0], qr#^1945 #, "Hypertext Transfer Protocol -- HTTP/1.0");
like($out3[1], qr#^2068 #, "Hypertext Transfer Protocol -- HTTP/1.1");

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


