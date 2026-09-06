#!/usr/bin/perl
# Minimal static file server for local preview.
#   perl build-tools/server.pl [port] [web-root]
# Defaults: port 4321, web-root = current working directory.
# From the repo root:  perl build-tools/server.pl 4321   ->  http://127.0.0.1:4321
use strict; use warnings;
use IO::Socket::INET;
use Cwd qw(abs_path);
use File::Basename;

my $port = $ARGV[0] || 4321;
my $root = abs_path($ARGV[1] || '.');
$| = 1;

my $srv = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1', LocalPort => $port,
  Proto => 'tcp', Listen => 20, ReuseAddr => 1
) or die "bind $port: $!";
print "serving $root on http://127.0.0.1:$port\n";

my %MIME = (
  html=>'text/html; charset=utf-8', css=>'text/css; charset=utf-8',
  js=>'text/javascript; charset=utf-8', json=>'application/json',
  svg=>'image/svg+xml', jpg=>'image/jpeg', jpeg=>'image/jpeg',
  png=>'image/png', webp=>'image/webp', gif=>'image/gif',
  woff2=>'font/woff2', woff=>'font/woff', ico=>'image/x-icon',
  mp4=>'video/mp4', webm=>'video/webm', mov=>'video/quicktime',
);

while (my $c = $srv->accept) {
  my $req = <$c>;
  if (!$req || $req !~ m{^GET\s+(\S+)\s+HTTP}) { close $c; next; }
  my $path = $1;
  $path =~ s/\?.*$//;
  $path = '/index.html' if $path eq '/';
  $path =~ s{\.\.}{}g;
  my $file = $root . $path;
  1 while <$c> =~ /\S/;   # drain headers
  if (-d $file) { $file .= '/index.html'; }
  if (-f $file) {
    my ($ext) = $file =~ /\.([^.]+)$/;
    my $mime = $MIME{lc($ext||'')} || 'application/octet-stream';
    open my $fh, '<:raw', $file or do { print $c "HTTP/1.1 500\r\n\r\n"; close $c; next; };
    local $/; my $body = <$fh>; close $fh;
    print $c "HTTP/1.1 200 OK\r\nContent-Type: $mime\r\nContent-Length: ".length($body)."\r\nCache-Control: no-cache\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n";
    print $c $body;
  } else {
    my $b = "404 Not Found: $path";
    print $c "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: ".length($b)."\r\nConnection: close\r\n\r\n$b";
  }
  close $c;
}
