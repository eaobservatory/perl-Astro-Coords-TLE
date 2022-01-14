use Test::More;
use Test::Number::Delta within => 0.05;

use strict;

eval {
    require UKIRT::JunkTrack::Parse;
};
if ($@) {
    plan skip_all => 'UKIRT::JunkTrack::Parse module not installed';
    exit;
}
else {
    plan tests => 1 + 6000 * 2;
}

use Astro::Coords::TLE;
use Astro::Telescope;
use Math::Trig qw/pi/;

# Create TLE object for SSN 39504.

my $c = new Astro::Coords::TLE(
    name => 'SSN 39504',
    epoch_year => 2014,
    epoch_day => 90.51853956,
    bstar => 0.0,
    inclination => new Astro::Coords::Angle(6.9693, units => 'degrees'),
    raanode => new Astro::Coords::Angle(338.3797, units => 'degrees'),
    e => 0.0001636,
    perigee => new Astro::Coords::Angle(42.8768, units => 'degrees'),
    mean_anomaly => new Astro::Coords::Angle(204.2600, units => 'degrees'),
    mean_motion => 1.00276036,
);

isa_ok($c, 'Astro::Coords::TLE');

$c->telescope(new Astro::Telescope('UKIRT'));

# Get reference data for SSN 39504.
my $ref = UKIRT::JunkTrack::Parse::parse_file('t/data/uk1920140909504.txt2.mlb');

foreach my $record (@$ref) {
    my ($dt, $ra_ref, $dec_ref) = @$record;

    $c->datetime($dt);

    my ($ra_calc, $dec_calc) = $c->apparent();
    $ra_calc = $ra_calc->degrees();
    $dec_calc = $dec_calc->degrees();

    # Check that the RAs didn't fall just to either side of 0 degrees.
    my $ra_diff = $ra_calc - $ra_ref;
    $ra_diff += 360.0 if $ra_diff < -180.0;
    $ra_diff -= 360.0 if $ra_diff > 180.0;

    delta_ok($ra_diff, 0.0, 'ra difference');
    delta_ok($dec_calc, $dec_ref, 'dec');
}
