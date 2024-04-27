use Test::More tests => 3;

use strict;

use Astro::Coords::TLE;

my @iss = (
    '1 25544U 98067A   08264.51782528 -.00002182  00000-0 -11606-4 0  2927',
    '2 25544  51.6416 247.4627 0006703 130.5360 325.0288 15.72125391563537',
);

my $c = Astro::Coords::TLE->parse_tle(@iss);
isa_ok($c, 'Astro::Coords::TLE');

my @rewrite = $c->format_tle();
is(@rewrite[0], $iss[0], 'Rewrite ' . $iss[0]);
is(@rewrite[1], $iss[1], 'Rewrite ' . $iss[1]);
