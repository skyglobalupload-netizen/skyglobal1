#!/usr/bin/perl
# Inlines theme.css + app.js into a single self-contained file for Artifact hosting.
# Usage: perl build-artifact.pl <src.html> <out.html> <skin> <title-en> <title-ar>
use strict; use warnings;
local $/;

my ($src, $out, $skin, $ten, $tar) = @ARGV;
open(my $c,'<:raw','assets/theme.css') or die "theme.css: $!"; my $css = <$c>; close $c;
# lift the Google Fonts @import out to a <link> (more robust under Artifact CSP)
my $fontlink = '';
if ($css =~ s/\@import url\((['"]?)(https:\/\/fonts\.googleapis\.com[^'")]+)\1\);?\s*//) {
  $fontlink = qq{<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link rel="stylesheet" href="$2">\n};
}
open(my $j,'<:raw','assets/app.js') or die "app.js: $!"; my $js = <$j>; close $j;
sub slurp { open(my $f,'<:raw',$_[0]) or die "$_[0]: $!"; local $/; my $x=<$f>; close $f; $x }
open(my $h,'<:raw',$src) or die "$src: $!"; my $html = <$h>; close $h;
# only bundle the GSAP vendor when the source page actually loads it
my $vendor = ($html =~ /gsap\.min\.js/)
  ? slurp('assets/gsap.min.js') . "\n" . slurp('assets/scrolltrigger.min.js')
  : '';

# page-specific <style> from head (the one that is NOT the theme import)
my $pagecss = '';
while ($html =~ /<style>(.*?)<\/style>/sg) { $pagecss .= $1 . "\n"; }

# body inner content
my ($body) = $html =~ /<body[^>]*>(.*)<\/body>/s;
die "no body in $src" unless $body;

# inline referenced local images as data URIs
use MIME::Base64;
$body =~ s{(src|href|poster)="((?:\.\.\/)?assets\/img\/([^"]+))"}{
  my ($attr,$rel,$fn)=($1,$2,$3);
  my $p = "assets/img/$fn";
  if (open(my $img,'<:raw',$p)) { local $/; my $d=<$img>; close $img;
    my ($ext)=$fn=~/\.(\w+)$/; my %m=(jpg=>'jpeg',jpeg=>'jpeg',png=>'png',webp=>'webp',svg=>'svg+xml',gif=>'gif');
    my $mime='image/'.($m{lc $ext}||'jpeg');
    qq{$attr="data:$mime;base64,}.encode_base64($d,'').qq{"};
  } else { qq{$attr="$rel"} }
}ge;
# inline referenced local video as data URIs; drop <source> entries whose file is missing
$body =~ s{<source\s+src="((?:\.\.\/)?assets\/video\/([^"]+))"[^>]*>}{
  my ($rel,$fn)=($1,$2);
  my $p = "assets/video/$fn";
  if (open(my $v,'<:raw',$p)) { local $/; my $d=<$v>; close $v;
    my ($ext)=$fn=~/\.(\w+)$/;
    my $mime = lc($ext||'') eq 'webm' ? 'video/webm' : 'video/mp4';
    qq{<source src="data:$mime;base64,}.encode_base64($d,'').qq{" type="$mime">};
  } else { '' }
}ge;
# strip local script/style/link references we are inlining
$body =~ s/<script src="[^"]*(?:app\.js|gsap\.min\.js|scrolltrigger\.min\.js)"><\/script>//g;
$body =~ s/<link rel="stylesheet"[^>]*>//g;
$body =~ s/<style>.*?<\/style>//sg;

my $skinjs = $skin ? qq{document.body.className=@{[qq{"$skin"}]};} : '';
$ten =~ s/"/\\"/g; $tar =~ s/"/\\"/g;

open(my $o,'>:raw',$out) or die "$out: $!";
print $o qq{<title>$ten</title>\n};
print $o $fontlink;
print $o qq{<script>document.body.id="top";$skinjs window.SG_TITLES={en:"$ten",ar:"$tar"};</script>\n};
print $o qq{<style>\n$css\n</style>\n};
print $o qq{<style>\n$pagecss\n</style>\n};
print $o $body;
print $o qq{\n<script>\n$vendor\n</script>\n} if length $vendor;
print $o qq{<script>\n$js\n</script>\n};
close $o;
print "wrote $out (", -s $out, " bytes)\n";
