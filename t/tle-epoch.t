use Test::More tests => 14;

use strict;

use Astro::Coords::Angle;
use Astro::Coords::TLE;
use DateTime;

my %common = (
    name => 'a piece of space junk',
    bstar => 0.0,
    e => 0.0,
    inclination => new Astro::Coords::Angle(0.0, units => 'rad'),
    mean_anomaly => new Astro::Coords::Angle(0.0, units => 'rad'),
    mean_motion => 0.0,
    perigee => new Astro::Coords::Angle(0.0, units => 'rad'),
    raanode => new Astro::Coords::Angle(0.0, units => 'rad'),
);

my $c = new Astro::Coords::TLE(%common, epoch => 6 * 3600);
isa_ok($c, 'Astro::Coords::TLE');

is($c->epoch_year(), 1970, 'epoch year from UNIX time');
is($c->epoch_day(), 1.25, 'epoch day from UNIX time');

my $dt = new DateTime(year => 1993, month => 12, day => 25,
                      hour => 15, minute => 0, second => 0,
                      time_zone => 'UTC');
$c = new Astro::Coords::TLE(%common, epoch => $dt);
isa_ok($c, 'Astro::Coords::TLE');

is($c->epoch_year(), 1993, 'epoch year from DateTime');
is($c->epoch_day(), 359.625, 'epoch day from DateTime');

$c = new Astro::Coords::TLE(%common, epoch_year => 2013, epoch_day => 91.5);
isa_ok($c, 'Astro::Coords::TLE');

$dt = $c->{'epoch'};
is($dt->year(), 2013, 'year from year/day');
is($dt->month(), 4, 'month from year/day');
is($dt->day(), 1, 'day from year/day');
is($dt->hour(), 12, 'hour from year/day');
is($dt->minute(), 0, 'minute from year/day');
is($dt->second(), 0, 'second from year/day');
is($dt->nanosecond(), 0, 'nanosecond from year/day');
