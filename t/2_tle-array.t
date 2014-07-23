use Test::More tests => 12;

use strict;

use Astro::Coords::Angle;
use Astro::Coords::TLE;

my $c = new Astro::Coords::TLE(
    name => 'a piece of space junk',
    epoch_year => 1970,
    epoch_day => 1.5,
    bstar => 0.1,
    e => 0.9,
    inclination => new Astro::Coords::Angle(0.75, units => 'rad'),
    mean_anomaly => new Astro::Coords::Angle(0.25, units => 'rad'),
    mean_motion => 7.5,
    perigee => new Astro::Coords::Angle(1.4, units => 'rad'),
    raanode => new Astro::Coords::Angle(0.44, units => 'rad'),
);

isa_ok($c, 'Astro::Coords::TLE');

my @a = $c->array();

is($a[0], 'TLE', 'type');
ok(! defined $a[1], 'ra');
ok(! defined $a[2], 'dec');
is($a[3], 12 * 3600, 'epoch');
is($a[4], 0.1, 'bstar');
is($a[5], 0.75, 'inclination');
is($a[6], 0.44, 'ra a node');
is($a[7], 0.9, 'e');
is($a[8], 1.4, 'perigee');
is($a[9], 0.25, 'mean anomaly');
is($a[10], 7.5, 'mean motion');
