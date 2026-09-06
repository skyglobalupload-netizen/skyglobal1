use strict; use warnings;
# p2s.pl  PAGE_H  < content-stream  > svg <path> elements
# Handles q/Q with full 2x3 cm matrix stack, m l c v y h re, f/f*/B/b/S/n,
# rg/g/k (fill) and RG/G/K (stroke) colour, w (stroke width).
# Emits one <path> per painting op, with the CTM applied and Y flipped to page height.
my $H = shift // 0;
local $/; my $s = <STDIN>;

# tokenize: numbers, operators, strings (skip), names
my @tok;
while ($s =~ /\G\s*(?:
      \((?:[^()\\]|\\.)*\)            # literal string
    | <[0-9A-Fa-f\s]*>                # hex string
    | \/[^\s\/\[\]<>(){}]+            # name
    | [-+]?(?:\d+\.?\d*|\.\d+)        # number
    | [A-Za-z*'"]+                    # operator
    | [\[\]]
   )/xgc) {
  my $t = $&; $t =~ s/^\s+//;
  push @tok, $t if length $t;
}

my @mstack;
my @ctm = (1,0,0,1,0,0);      # a b c d e f
sub mul { my($m,$n)=@_;
  return (
    $m->[0]*$n->[0] + $m->[2]*$n->[1],
    $m->[1]*$n->[0] + $m->[3]*$n->[1],
    $m->[0]*$n->[2] + $m->[2]*$n->[3],
    $m->[1]*$n->[2] + $m->[3]*$n->[3],
    $m->[0]*$n->[4] + $m->[2]*$n->[5] + $m->[4],
    $m->[1]*$n->[4] + $m->[3]*$n->[5] + $m->[5],
  );
}
sub apply { my($x,$y)=@_;
  my $px = $ctm[0]*$x + $ctm[2]*$y + $ctm[4];
  my $py = $ctm[1]*$x + $ctm[3]*$y + $ctm[5];
  return ($px, $H - $py);
}
sub n3 { my $v=shift; $v = sprintf('%.3f',$v); $v =~ s/\.?0+$// if $v =~ /\./; $v='0' if $v eq '-0'; $v }

my @st;                # operand stack
my $d = '';            # current path data (SVG, device space)
my ($cx,$cy) = (0,0);  # current point in USER space (pre-CTM)
my ($sx,$sy) = (0,0);
my $fill = '#000000'; my $stroke = '#000000'; my $lw = 1;
my $eo = 0;            # even-odd for current path
my @out;

sub emit {
  my ($mode) = @_;   # 'f' fill, 's' stroke, 'b' both
  return unless length $d;
  my $attr;
  my $fr = $eo ? ' fill-rule="evenodd"' : '';
  if ($mode eq 'f') { $attr = qq{fill="$fill"$fr}; }
  elsif ($mode eq 's') { $attr = qq{fill="none" stroke="$stroke" stroke-width="}.n3($lw).qq{"}; }
  else { $attr = qq{fill="$fill"$fr stroke="$stroke" stroke-width="}.n3($lw).qq{"}; }
  push @out, qq{<path $attr d="$d"/>};
  $d = ''; $eo = 0;
}
sub scn2hex { my @c = @_;
  # drop a trailing pattern-name operand if present (non-numeric handled by caller)
  if    (@c == 4) { return k2hex(@c) }
  elsif (@c == 3) { return rg2hex(@c) }
  elsif (@c == 1) { return rg2hex($c[0],$c[0],$c[0]) }
  return '#000000';
}
sub num { return 0+ (shift // 0) }
sub rg2hex { my($r,$g,$b)=@_; sprintf('#%02x%02x%02x', map { my $v=$_*255; $v<0?0:$v>255?255:$v+0.5 } ($r,$g,$b)) }
sub k2hex { my($c,$m,$y,$k)=@_;
  rg2hex( (1-$c)*(1-$k), (1-$m)*(1-$k), (1-$y)*(1-$k) ) }

my $i=0;
while ($i <= $#tok) {
  my $t = $tok[$i++];
  if ($t =~ /^[-+]?(?:\d+\.?\d*|\.\d+)$/) { push @st, $t+0; next; }
  if ($t eq '[' ) { # skip dash array to matching ]
     while ($i<=$#tok && $tok[$i] ne ']') { $i++ } $i++; next;
  }
  if (substr($t,0,1) eq '/') { push @st, $t; next; }
  if (substr($t,0,1) eq '(' || substr($t,0,1) eq '<') { push @st, $t; next; }

  if    ($t eq 'q') { push @mstack, [ [@ctm], $fill, $stroke, $lw ]; }
  elsif ($t eq 'Q') { my $g = pop @mstack; if ($g) { @ctm = @{$g->[0]}; $fill = $g->[1]; $stroke = $g->[2]; $lw = $g->[3]; } }
  elsif ($t eq 'cm' && @st>=6) { my @m = splice(@st,-6); @ctm = mul(\@ctm, \@m); }
  elsif ($t eq 'm' && @st>=2) { ($cx,$cy)=splice(@st,-2); ($sx,$sy)=($cx,$cy); my($X,$Y)=apply($cx,$cy); $d.="M".n3($X)." ".n3($Y)." "; }
  elsif ($t eq 'l' && @st>=2) { ($cx,$cy)=splice(@st,-2); my($X,$Y)=apply($cx,$cy); $d.="L".n3($X)." ".n3($Y)." "; }
  elsif ($t eq 'c' && @st>=6) { my($x1,$y1,$x2,$y2,$x3,$y3)=splice(@st,-6);
        my @p=(apply($x1,$y1),apply($x2,$y2),apply($x3,$y3));
        $d.="C".join(" ",map{n3($_)}@p)." "; ($cx,$cy)=($x3,$y3); }
  elsif ($t eq 'v' && @st>=4) { my($x2,$y2,$x3,$y3)=splice(@st,-4);
        my @p=(apply($cx,$cy),apply($x2,$y2),apply($x3,$y3));
        $d.="C".join(" ",map{n3($_)}@p)." "; ($cx,$cy)=($x3,$y3); }
  elsif ($t eq 'y' && @st>=4) { my($x1,$y1,$x3,$y3)=splice(@st,-4);
        my @p=(apply($x1,$y1),apply($x3,$y3),apply($x3,$y3));
        $d.="C".join(" ",map{n3($_)}@p)." "; ($cx,$cy)=($x3,$y3); }
  elsif ($t eq 're' && @st>=4) { my($x,$y,$w,$hh)=splice(@st,-4);
        my @a=apply($x,$y); my @b=apply($x+$w,$y); my @c=apply($x+$w,$y+$hh); my @e=apply($x,$y+$hh);
        $d.="M".n3($a[0])." ".n3($a[1])." L".n3($b[0])." ".n3($b[1])." L".n3($c[0])." ".n3($c[1])." L".n3($e[0])." ".n3($e[1])." Z ";
        ($cx,$cy)=($x,$y); ($sx,$sy)=($x,$y); }
  elsif ($t eq 'h') { $d.="Z "; ($cx,$cy)=($sx,$sy); }
  elsif ($t eq 'n') { $d=''; @st=(); $eo=0; }
  elsif ($t eq 'f' || $t eq 'F' || $t eq 'f*') { $eo=1 if $t eq 'f*'; emit('f'); @st=(); }
  elsif ($t eq 'S' || $t eq 's') { $d.="Z " if $t eq 's'; emit('s'); @st=(); }
  elsif ($t eq 'B' || $t eq 'B*' || $t eq 'b' || $t eq 'b*') { $eo=1 if $t=~/\*/; $d.="Z " if $t=~/^b/; emit('b'); @st=(); }
  elsif ($t eq 'W' || $t eq 'W*') { }   # clip - ignore (path still painted/cleared by next op)
  elsif ($t eq 'w' && @st>=1) { $lw = pop @st; }
  elsif ($t eq 'g'  && @st>=1) { my $v=pop @st; $fill = rg2hex($v,$v,$v); }
  elsif ($t eq 'G'  && @st>=1) { my $v=pop @st; $stroke = rg2hex($v,$v,$v); }
  elsif ($t eq 'rg' && @st>=3) { my @c=splice(@st,-3); $fill = rg2hex(@c); }
  elsif ($t eq 'RG' && @st>=3) { my @c=splice(@st,-3); $stroke = rg2hex(@c); }
  elsif ($t eq 'k'  && @st>=4) { my @c=splice(@st,-4); $fill = k2hex(@c); }
  elsif ($t eq 'K'  && @st>=4) { my @c=splice(@st,-4); $stroke = k2hex(@c); }
  elsif ($t eq 'cs' || $t eq 'CS') { pop @st; }
  elsif ($t eq 'scn' || $t eq 'sc') { my @c = grep { /^-?[\d.]+$/ } @st; $fill = scn2hex(@c) if @c; @st=(); }
  elsif ($t eq 'SCN' || $t eq 'SC') { my @c = grep { /^-?[\d.]+$/ } @st; $stroke = scn2hex(@c) if @c; @st=(); }
  else { @st=(); }   # any other operator: clear operands
}
print join("\n",@out),"\n";
