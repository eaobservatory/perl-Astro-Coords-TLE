use Test::More tests => 9;
use Test::Number::Delta;

use strict;

use Astro::Coords::TLE;
use Math::Trig qw/pi/;

my $c = new Astro::Coords::TLE(
    name => 'a piece of space junk',
    epoch_year => 1970,
    epoch_day => 1.5,
    bstar => 0.125,
    e => 1.0,
    inclination => new Astro::Coords::Angle(2.0, units => 'rad'),
    mean_anomaly => new Astro::Coords::Angle(0.5, units => 'rad'),
    mean_motion => 24.0,
    perigee => new Astro::Coords::Angle(1.75, units => 'rad'),
    raanode => new Astro::Coords::Angle(1.5, units => 'rad'),
);

my $object = $c->{'eci_object'};
isa_ok($object, 'Astro::Coord::ECI::TLE');

is($object->get('epoch'), 43200, 'epoch');

delta_ok($object->get('argumentofperigee'), 1.75, 'perigee');
delta_ok($object->get('ascendingnode'), 1.5, 'ra a node');
delta_ok($object->get('bstardrag'), 0.125, 'bstar');
delta_ok($object->get('eccentricity'), 1.0, 'e');
delta_ok($object->get('inclination'), 2.0, 'inclination');
delta_ok($object->get('meananomaly'), 0.5, 'mean anomaly');
delta_ok($object->get('meanmotion'), 2.0 * pi / 60.0, 'mean motion');
