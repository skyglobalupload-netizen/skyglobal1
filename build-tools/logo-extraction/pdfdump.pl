use strict; use warnings;
use Compress::Zlib;
# pdfdump.pl <file.pdf> [outdir]  -> writes each inflated stream to outdir/streamN.txt
my $f = $ARGV[0] or die "need pdf\n";
my $outdir = $ARGV[1] || 'streams';
mkdir $outdir unless -d $outdir;
local $/; open(my $fh,'<:raw',$f) or die $!; my $d=<$fh>; close $fh;
my $n=0;
# iterate objects
while ($d =~ /(\d+)\s+(\d+)\s+obj\b(.*?)\bendobj/sg) {
  my ($num,$gen,$body)=($1,$2,$3);
  if ($body =~ /stream\r?\n(.*?)\r?\nendstream/s) {
    my $raw = $1;
    my $dict = substr($body,0,index($body,'stream'));
    my $out;
    if ($dict =~ /FlateDecode/) {
      my ($i,$status);
      ($i,$status)=inflateInit();
      my ($buf,$s)=$i->inflate($raw);
      $out = defined $buf ? $buf : "<<inflate failed: $s>>";
    } else {
      $out = $raw;
    }
    my $type = ($dict =~ m{/Subtype\s*/(\w+)}) ? $1 : (($dict=~m{/Type\s*/(\w+)})?$1:'raw');
    my $len = length($out);
    my $fn = "$outdir/obj${num}_${type}_${len}.txt";
    open(my $o,'>:raw',$fn) or die $!; print $o $out; close $o;
    print "obj $num  $type  dict=[".substr($dict,0,120)."]  -> $fn ($len bytes)\n";
    $n++;
  }
}
print "wrote $n streams to $outdir/\n";
