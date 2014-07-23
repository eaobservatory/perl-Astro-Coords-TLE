use Test::More tests => 6;
use Test::Number::Delta;

use strict;

use Astro::Telescope;
use Astro::Coords::TLE;

my $c = new Astro::Coords::TLE(
    name => 'a piece of space junk',
    epoch_year => 1970,
    epoch_day => 1.5,
    bstar => 0.0,
    e => 0.0,
    inclination => new Astro::Coords::Angle(0.0, units => 'rad'),
    mean_anomaly => new Astro::Coords::Angle(0.0, units => 'rad'),
    mean_motion => 0.0,
    perigee => new Astro::Coords::Angle(0.0, units => 'rad'),
    raanode => new Astro::Coords::Angle(0.0, units => 'rad'),
);

$c->telescope(new Astro::Telescope('UKIRT'));

my $telescope = $c->telescope();
isa_ok($telescope, 'Astro::Telescope');

is($telescope->name(), 'UKIRT');

my $station = $c->{'eci_station'};
isa_ok($station, 'Astro::Coord::ECI');

my ($x, $y, $z, undef, undef, undef) = $station->ecef();
delta_within($x, -5464.374, 0.001);
delta_within($y, -2493.677, 0.001);
delta_within($z, 2150.638, 0.001);
