use strict; use warnings;
# mksvg.pl : read path-fragment files, emit a tightly-cropped standalone SVG.
# usage: perl mksvg.pl OUT.svg  "GROUP1:file1[:matrix a,b,c,d,e,f]"  "GROUP2:..." ...
my $out = shift;
my @groups;
for my $spec (@ARGV) {
  my ($label, $file, $mx) = split /:/, $spec, 3;
  local $/; open(my $fh,'<',$file) or die "$file: $!";
  my $txt = <$fh>; close $fh;
  my @m = $mx ? (split /,/, $mx) : ();
  push @groups, { label=>$label, txt=>$txt, m=>\@m };
}
# bbox using only d="..." payloads
my ($minx,$miny,$maxx,$maxy);
sub acc { my($x,$y)=@_;
  $minx=$x if !defined $minx||$x<$minx; $maxx=$x if !defined $maxx||$x>$maxx;
  $miny=$y if !defined $miny||$y<$miny; $maxy=$y if !defined $maxy||$y>$maxy; }
for my $g (@groups) {
  my @m = @{$g->{m}};
  while ($g->{txt} =~ /\bd="([^"]*)"/g) {
    my $d = $1;
    my @n = $d =~ /(-?\d+(?:\.\d+)?)/g;
    for (my $i=0; $i+1<=$#n; $i+=2) {
      my ($x,$y) = ($n[$i], $n[$i+1]);
      if (@m) { my($a,$b,$c,$dd,$e,$f)=@m; ($x,$y)=($a*$x+$c*$y+$e, $b*$x+$dd*$y+$f); }
      acc($x,$y);
    }
  }
}
my $pad = 0.02 * (($maxx-$minx) > ($maxy-$miny) ? ($maxx-$minx) : ($maxy-$miny));
$minx-=$pad; $miny-=$pad; $maxx+=$pad; $maxy+=$pad;
my $w = $maxx-$minx; my $h = $maxy-$miny;
open(my $o,'>',$out) or die $!;
printf $o qq{<svg xmlns="http://www.w3.org/2000/svg" viewBox="%.2f %.2f %.2f %.2f">\n}, $minx,$miny,$w,$h;
for my $g (@groups) {
  my @m = @{$g->{m}};
  if (@m) { printf $o qq{<g transform="matrix(%s)">\n}, join(' ',@m); }
  print $o $g->{txt};
  print $o "\n</g>\n" if @m;
}
print $o "</svg>\n";
close $o;
print "wrote $out  viewBox=$minx $miny $w $h\n";
