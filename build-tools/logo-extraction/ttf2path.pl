use strict; use warnings;
# ttf2path.pl font.ttf STRING > one <path d="..."> per glyph, laid out on the
# baseline using advance widths from hmtx. Units = font units, y-up flipped so
# the path is drawn in a y-down coordinate box of height unitsPerEm, with x
# advancing left-to-right. Caller scales.
my ($fn,$str) = @ARGV;
open(my $fh,'<:raw',$fn) or die $!; local $/; my $f = <$fh>; close $fh;

sub u8  { unpack('C',  substr($f,$_[0],1)) }
sub u16 { unpack('n',  substr($f,$_[0],2)) }
sub s16 { unpack('s>', substr($f,$_[0],2)) }
sub u32 { unpack('N',  substr($f,$_[0],4)) }

my $numTables = u16(4);
my %tab;
for my $i (0..$numTables-1) {
  my $o = 12 + 16*$i;
  my $tag = substr($f,$o,4);
  $tab{$tag} = { off => u32($o+8), len => u32($o+12) };
}
die "no glyf\n" unless $tab{glyf} && $tab{loca} && $tab{head} && $tab{maxp};

my $head = $tab{head}{off};
my $unitsPerEm = u16($head+18);
my $indexToLocFormat = s16($head+50);
my $numGlyphs = u16($tab{maxp}{off}+4);

# hmtx / hhea
my $numHM = u16($tab{hhea}{off}+34);
sub advance {
  my $g = shift;
  my $o = $tab{hmtx}{off};
  return u16($o + 4*($g < $numHM ? $g : $numHM-1));
}

# loca
my @loca;
my $lo = $tab{loca}{off};
if ($indexToLocFormat == 0) { for my $i (0..$numGlyphs) { push @loca, u16($lo+2*$i)*2 } }
else                        { for my $i (0..$numGlyphs) { push @loca, u32($lo+4*$i) } }

# cmap: prefer (3,1) then (3,0) then (0,*) then (1,0)
my $cmapOff = $tab{cmap}{off};
my $nsub = u16($cmapOff+2);
my %subs; my $best;
for my $i (0..$nsub-1) {
  my $o = $cmapOff+4+8*$i;
  my $pid = u16($o); my $eid = u16($o+2); my $so = u32($o+4);
  $subs{"$pid.$eid"} = $cmapOff + $so;
}
for my $k (qw(3.1 3.10 0.3 0.4 3.0 0.0 0.1 0.2 1.0)) { if ($subs{$k}) { $best = $subs{$k}; last } }
$best //= (values %subs)[0];

sub cmap_lookup {
  my $cp = shift;
  my $o = $best;
  my $fmt = u16($o);
  if ($fmt == 4) {
    my $segX2 = u16($o+6); my $segCount = $segX2/2;
    my $endO = $o+14;
    my $startO = $endO + $segX2 + 2;
    my $deltaO = $startO + $segX2;
    my $rangeO = $deltaO + $segX2;
    for my $i (0..$segCount-1) {
      my $end = u16($endO+2*$i);
      next if $cp > $end;
      my $start = u16($startO+2*$i);
      return 0 if $cp < $start;
      my $delta = s16($deltaO+2*$i);
      my $ro = u16($rangeO+2*$i);
      if ($ro == 0) { return ($cp + $delta) & 0xFFFF }
      my $gi = u16($rangeO+2*$i + $ro + 2*($cp-$start));
      return 0 if $gi == 0;
      return ($gi + $delta) & 0xFFFF;
    }
    return 0;
  }
  elsif ($fmt == 6) {
    my $first = u16($o+6); my $count = u16($o+8);
    return 0 if $cp < $first || $cp >= $first+$count;
    return u16($o+10+2*($cp-$first));
  }
  elsif ($fmt == 0) {
    return 0 if $cp > 255;
    return u8($o+6+$cp);
  }
  elsif ($fmt == 12) {
    my $ng = u32($o+12);
    for my $i (0..$ng-1) {
      my $g = $o+16+12*$i;
      my $s = u32($g); my $e = u32($g+4); my $sg = u32($g+8);
      return $sg + ($cp-$s) if $cp>=$s && $cp<=$e;
    }
    return 0;
  }
  return 0;
}

# parse a simple/composite glyph -> list of contours; each contour = list of
# [x,y,onCurve]
sub glyph_contours {
  my ($gid, $depth) = @_;
  $depth //= 0;
  return () if $depth > 5;
  my $start = $tab{glyf}{off} + $loca[$gid];
  my $end   = $tab{glyf}{off} + $loca[$gid+1];
  return () if $end <= $start;
  my $nc = s16($start);
  if ($nc < 0) {
    # composite
    my @all;
    my $o = $start + 10;
    while (1) {
      my $flags = u16($o); my $cgid = u16($o+2); $o += 4;
      my ($a1,$a2);
      if ($flags & 0x0001) { $a1 = s16($o); $a2 = s16($o+2); $o += 4 }
      else { $a1 = unpack('c',substr($f,$o,1)); $a2 = unpack('c',substr($f,$o+1,1)); $o += 2 }
      my ($sx,$sy,$s01,$s10) = (1,1,0,0);
      if ($flags & 0x0008) { $sx = $sy = s16($o)/16384; $o += 2 }
      elsif ($flags & 0x0040) { $sx = s16($o)/16384; $sy = s16($o+2)/16384; $o += 4 }
      elsif ($flags & 0x0080) { $sx = s16($o)/16384; $s01 = s16($o+2)/16384; $s10 = s16($o+4)/16384; $sy = s16($o+6)/16384; $o += 8 }
      my $dx = ($flags & 0x0002) ? $a1 : 0;
      my $dy = ($flags & 0x0002) ? $a2 : 0;
      for my $ct (glyph_contours($cgid,$depth+1)) {
        my @nc2 = map { [ $sx*$_->[0] + $s10*$_->[1] + $dx,
                          $s01*$_->[0] + $sy*$_->[1] + $dy,
                          $_->[2] ] } @$ct;
        push @all, \@nc2;
      }
      last unless $flags & 0x0020;
    }
    return @all;
  }
  my @ends = map { u16($start+10+2*$_) } (0..$nc-1);
  my $npts = $ends[-1]+1;
  my $io = $start + 10 + 2*$nc;
  my $il = u16($io); $io += 2 + $il;
  # flags
  my @flags;
  while (@flags < $npts) {
    my $fl = u8($io++); push @flags, $fl;
    if ($fl & 0x08) { my $rep = u8($io++); push @flags, ($fl) x $rep }
  }
  @flags = @flags[0..$npts-1];
  # x
  my @xs; my $x = 0;
  for my $fl (@flags) {
    if ($fl & 0x02) { my $dx = u8($io++); $x += ($fl & 0x10) ? $dx : -$dx }
    elsif (!($fl & 0x10)) { $x += s16($io); $io += 2 }
    push @xs, $x;
  }
  my @ys; my $y = 0;
  for my $fl (@flags) {
    if ($fl & 0x04) { my $dy = u8($io++); $y += ($fl & 0x20) ? $dy : -$dy }
    elsif (!($fl & 0x20)) { $y += s16($io); $io += 2 }
    push @ys, $y;
  }
  my @contours; my $s = 0;
  for my $e (@ends) {
    my @pts;
    for my $i ($s..$e) { push @pts, [ $xs[$i], $ys[$i], ($flags[$i] & 1) ? 1 : 0 ] }
    push @contours, \@pts;
    $s = $e+1;
  }
  return @contours;
}

# contour -> SVG path data (quadratic). y flipped: Y = EM - y
my $EM = $unitsPerEm;
sub contour_path {
  my ($pts, $ox) = @_;
  return '' unless @$pts;
  # ensure starts on-curve
  my @p = @$pts;
  my $startIdx = -1;
  for my $i (0..$#p) { if ($p[$i][2]) { $startIdx = $i; last } }
  my @seq;
  if ($startIdx < 0) {
    # all off-curve: synthesize start = midpoint of last & first
    my $mid = [ ($p[0][0]+$p[-1][0])/2, ($p[0][1]+$p[-1][1])/2, 1 ];
    @seq = ($mid, @p);
  } else {
    @seq = (@p[$startIdx..$#p], @p[0..$startIdx-1]);
  }
  my $X = sub { sprintf('%.2f', $_[0] + $ox) };
  my $Y = sub { sprintf('%.2f', $EM - $_[0]) };
  my $d = 'M'.$X->($seq[0][0]).' '.$Y->($seq[0][1]).' ';
  my $n = scalar @seq;
  my $i = 1;
  my ($cx,$cy) = ($seq[0][0],$seq[0][1]);
  while ($i <= $n) {
    my $cur = $seq[$i % $n];
    if ($cur->[2]) {
      $d .= 'L'.$X->($cur->[0]).' '.$Y->($cur->[1]).' ';
      ($cx,$cy)=($cur->[0],$cur->[1]);
      $i++;
    } else {
      my $ctrl = $cur;
      my $next = $seq[($i+1) % $n];
      my $ex; my $ey;
      if ($next->[2]) { $ex=$next->[0]; $ey=$next->[1]; $i += 2 }
      else { $ex = ($ctrl->[0]+$next->[0])/2; $ey = ($ctrl->[1]+$next->[1])/2; $i += 1 }
      $d .= 'Q'.$X->($ctrl->[0]).' '.$Y->($ctrl->[1]).' '.$X->($ex).' '.$Y->($ey).' ';
      ($cx,$cy)=($ex,$ey);
    }
  }
  $d .= 'Z ';
  return $d;
}

my $penx = 0;
my @out;
for my $ch (split //, $str) {
  my $cp = ord $ch;
  my $gid = cmap_lookup($cp);
  my $d = '';
  for my $ct (glyph_contours($gid)) { $d .= contour_path($ct, $penx) }
  push @out, qq{<path d="$d"/>} if length $d;
  $penx += advance($gid);
}
print "<!-- unitsPerEm=$EM totalAdvance=$penx -->\n";
print join("\n",@out),"\n";
