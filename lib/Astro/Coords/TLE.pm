# Copyright (C) 2014 Science and Technology Facilities Council.
# Copyright (C) 2024 East Asian Observatory.
# All Rights Reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

Astro::Coords::TLE - TLE wrapper class for Astro::Coords

=cut

package Astro::Coords::TLE;

use strict;
use warnings;

use Astro::Coord::ECI;
use Astro::Coord::ECI::TLE;
use Astro::Coords::Angle;
use DateTime;
use DateTime::Duration;
use Math::Trig qw/pi/;

use parent qw/Astro::Coords/;

use overload '""' => \&stringify;

our $VERSION = '0.001';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Construct a new object.  Takes the following parameters:

=over 4

=item name

=item epoch (fractional UNIX time), or:

=over 4

=item epoch_year

=item epoch_day

=back

=item bstar (inverse Earth radii)

=item e

=item inclination (angle object)

=item mean_anomaly (angle object)

=item mean_motion (revolutions per day)

=item perigee (angle object)

=item raanode (angle object)

=back

And optionally:

=over 4

=item class (U, C or S)

=item intl_desig

=item first_d

=item second_d

=item ephem_type (always zero)

=item elset_num

=item rev_at_epoch (revolutions)

=back

=cut

sub new {
    my $class = shift;
    my %opt = @_;

    my $epoch;

    if (exists $opt{'epoch'}) {
        if (UNIVERSAL::isa($opt{'epoch'}, 'DateTime')) {
            $epoch = $opt{'epoch'}->clone();
        }
        else {
            $epoch = DateTime->from_epoch(
                            time_zone => 'UTC',
                            epoch => $opt{'epoch'},
            );
        }
    }
    else {
        # As we didn't get epoch, check epoch_year and epoch_day.
        die 'TLE epoch or epoch_day and epoch_year must be defined'
            unless ((defined $opt{'epoch_year'})
                and (defined $opt{'epoch_day'}));

        # Ensure epoch number is not negative.
        # die 'TLE epoch year should not be before 1970'
        #    if $opt{'epoch_year'} < 1970;

        # Convert epoch year and (fractional) day into a DateTime object.
        my $year = $opt{'epoch_year'};
        my $fracday = $opt{'epoch_day'};
        my $day = int($fracday);
        my $nanoseconds = 24000000000.0 * 3600.0 * ($fracday - $day);

        $epoch = DateTime->from_day_of_year(
                        time_zone => 'UTC',
                        year => $year,
                        day_of_year => $day) +
                    DateTime::Duration->new(nanoseconds => $nanoseconds);
    }

    my $self = {
        name => $opt{'name'},
        epoch => $epoch,
    };

    # Handle angular parameters.
    foreach (qw/inclination raanode perigee mean_anomaly/) {
        my $val = $opt{$_};
        die "TLE parameter $_ should be an angle"
            unless UNIVERSAL::isa($val, 'Astro::Coords::Angle');
        $self->{$_} = $val;
    }

    # Handle general numeric parameters.
    foreach (qw/e mean_motion bstar/) {
        my $val = $opt{$_};
        die "TLE parameter $_ is not defined"
            unless defined $val;
        $self->{$_} = $val;
    }

    # Handle optional parameters.
    foreach (qw/class intl_desig first_d second_d ephem_type elset_num rev_at_epoch/) {
        if (exists $opt{$_}) {
            my $val = $opt{$_};
            $self->{$_} = $val if defined $val;
        }
    }

    $self->{'eci_object'} = new Astro::Coord::ECI::TLE(
        id => 99999,
        argumentofperigee => $self->{'perigee'}->radians(),
        ascendingnode => $self->{'raanode'}->radians(),
        bstardrag => $self->{'bstar'},
        eccentricity => $self->{'e'},
        epoch => $epoch->hires_epoch(),
        inclination => $self->{'inclination'}->radians(),
        meananomaly => $self->{'mean_anomaly'}->radians(),
        meanmotion => ($self->{'mean_motion'} * 2.0 * pi / (24.0 * 60.0)),
    );

    return bless $self, (ref $class) || $class;
}

=back

=head2 Parsing and Formatting Methods

=over 4

=item B<parse_tle>

Parse two line elements:

    $coords = Astro::Coords::TLE->parse_tle($line1, $line2);

=cut

# Parsing routine, conversion to Perl of omp.tle.parse.TLEParser.parse_tle by BHG.

sub parse_tle {
    my $cls = shift;
    my $line1 = shift;
    my $line2 = shift;

    if (length($line1) < 62 or length($line2) < 69) {
        die 'Unparseable TLE';
    }

    my $id = substr($line1, 2, 5);
    unless ($id =~ /^[0-9]+$/) {
        die 'invalid identifier';
    }

    return $cls->new(
        name => (sprintf 'NORAD%05d', $id),
        epoch => _convert_epoch(substr($line1, 18, 14)),
        bstar => _parse_decimal_rhs(substr($line1, 53, 8)),
        inclination => Astro::Coords::Angle->new(substr($line2, 8, 8), units => 'degrees'),
        raanode => Astro::Coords::Angle->new(substr($line2, 17, 8), units => 'degrees'),
        e => ('0.' . substr($line2, 26, 7)),
        perigee => Astro::Coords::Angle->new(substr($line2, 34, 8), units => 'degrees'),
        mean_anomaly => Astro::Coords::Angle->new(substr($line2, 43, 8), units => 'degrees'),
        mean_motion => substr($line2, 52, 11),

        # Optional parameters:
        class => substr($line1, 7, 1),
        intl_desig => (substr($line1, 9, 8) =~ s/ *$//r),
        first_d => substr($line1, 33, 10),
        second_d => _parse_decimal_rhs(substr($line1, 44, 8)),
        ephem_type => substr($line1, 62, 1),
        elset_num => substr($line1, 64, 4),
        rev_at_epoch => substr($line2, 63, 5),
    );
}

sub _convert_epoch {
    my $astro = shift;

    require DateTime::Format::Strptime;

    $astro =~ s/^\s*//;
    $astro =~ s/\s*$//;

    my $strp = DateTime::Format::Strptime->new(
        pattern => '%Y %j',
        time_zone => 'UTC');

    my $year = '20' . substr($astro, 0, 2);
    my ($day, $decimal) = split /\./, substr($astro, 2), 2;
    my $tday = $strp->parse_datetime($year . ' ' . $day);
    my $eday = $strp->parse_datetime('1970 1');
    my $days = ($eday->delta_days($tday))->in_units('days');

    return ($days + ('0.' . $decimal)) * 24 * 3600;
}

# Routine to parse TLE-style right hand sides of
# truncated decimals.  (i.e. the bit after the decimal
# point)

sub _parse_decimal_rhs {
    my $decimal = shift;

    $decimal =~ s/^\s*//;
    $decimal =~ s/\s*$//;

    my $sign = 1.0;
    if ($decimal =~ /^-/) {
        $decimal = substr($decimal, 1);
        $decimal =~ s/^\s*//;
        $sign = -1.0
    }
    elsif ($decimal =~ /^\+/) {
        $decimal = substr($decimal, 1);
        $decimal =~ s/^\s*//;
    }

    if ($decimal =~ /^(.*)([+-].*)$/) {
        $decimal = sprintf '%sE%s', $1, $2;
    }

    return $sign * ('0.' . $decimal);
}

=item B<format_tle>

Format object as two line elements:

    ($line1, $line2) = $coords->format_tle();

=cut

sub format_tle {
    my $self = shift;

    my $number = $self->name;
    $number =~ s/^NORAD//;

    return map {$_ . _line_checksum($_)} (
        (sprintf '1 %05d%1s %-8s %02d%12.8f %s %s %s %1d %4d',
            $number,
            $self->class,
            $self->intl_desig,
            (substr $self->epoch_year, 2),
            $self->epoch_day,
            _format_decimal($self->first_d, 10),
            _format_decimal_rhs($self->second_d),
            _format_decimal_rhs($self->bstar),
            $self->ephem_type,
            $self->elset_num,
        ),
        (sprintf '2 %05d %8.4f %8.4f %s %8.4f %8.4f %s%5d',
            $number,
            $self->inclination->degrees,
            $self->raanode->degrees,
            _format_decimal_nodp($self->e, 7),
            $self->perigee->degrees,
            $self->mean_anomaly->degrees,
            _format_decimal($self->mean_motion, 11),
            $self->rev_at_epoch,
        ),
    );
}

sub _format_decimal {
    my $value = shift;
    my $width = shift;

    my $sign = '';
    if ($value < 0.0) {
        $sign = '-';
        $width -= 1;
        $value *= -1.0;
    }

    my $strip = 0;
    if ($value < 1.0) {
        $strip = 1;
    }
    else {
        $width -= 1 + int(log($value) / log(10));
    }

    my $decimal = sprintf '%.*f', $width - 1, $value;

    $decimal =~ s/^0// if $strip;

    return $sign . $decimal;
}

sub _format_decimal_nodp {
    my $value = shift;
    my $width = shift;

    die 'Invalid value for nodp formatting'
        if $value < 0.0 or $value >= 1.0;

    my $decimal = sprintf '%.*f', $width, $value;

    $decimal =~ s/^0\.//;

    return $decimal;
}

sub _format_decimal_rhs {
    my $value = shift;

    return ' 00000-0' if $value == 0.0;

    my $sign = ' ';
    if ($value < 0.0) {
        $sign = '-';
        $value *= -1.0;
    }

    die 'Invalid value for decimal_rhs formatting'
        if $value >= 1.0;

    my $exp = - int(log($value) / log(10));

    $value *= 10 ** $exp;

    $exp = sprintf '%d', $exp;

    return sprintf '%s%s-%s', $sign, _format_decimal_nodp($value, 6 - length $exp), $exp;
}

sub _line_checksum {
    my $line = shift;

    my $sum = 0;
    foreach (split '', $line) {
        if (/[1-9]/) {
            $sum += $_;
        }
        elsif (/-/) {
            $sum ++;
        }
    }

    return sprintf '%1d', $sum % 10;
}

=back

=head2 Accessor Methods

=over 4

=item B<bstar>

Return the bstar drag term (inverse Earth radii).

=cut

sub bstar {
    my $self = shift;
    return $self->{'bstar'};
}

=item B<e>

Return the eccentricity.

=cut

sub e {
    my $self = shift;
    return $self->{'e'};
}

=item B<epoch_day>

Return the (fractional) epoch day of the year.

=cut

sub epoch_day {
    my $self = shift;
    my $epoch = $self->{'epoch'};

    return $epoch->day_of_year() +
           (($epoch->fractional_second() / 60.0 +
             $epoch->minute()) / 60.0 +
            $epoch->hour()) / 24.0;
}

=item B<epoch_year>

Return the epoch year.

=cut

sub epoch_year {
    my $self = shift;

    return $self->{'epoch'}->year();
}

=item B<inclination>

Return the inclination (angle object).

=cut

sub inclination {
    my $self = shift;
    return $self->{'inclination'};
}

=item B<mean_anomaly>

Return the mean anomaly (angle object).

=cut

sub mean_anomaly {
    my $self = shift;
    return $self->{'mean_anomaly'};
}

=item B<mean_motion>

Return the mean motion (revolutions per day).

=cut

sub mean_motion {
    my $self = shift;
    return $self->{'mean_motion'};
}

=item B<raanode>

Return the RA ascending node (angle object).

=cut

sub raanode {
    my $self = shift;
    return $self->{'raanode'};
}

=item B<perigee>

Return the perigee (angle object).

=cut

sub perigee {
    my $self = shift;
    return $self->{'perigee'};
}

=item B<telescope>

Set or return the telescope (Astro::Telescope object).

=cut

sub telescope {
    my $self = shift;

    # If we were given a telescope, use its position to set up an
    # ECI station object.
    if (@_) {
        my $telescope = $_[0];
        die 'Telescope must be an Astro::Telescope object'
            unless UNIVERSAL::isa($telescope, 'Astro::Telescope');

        my $station = Astro::Coord::ECI->geodetic($telescope->lat(),
                                                  $telescope->long(),
                                                  $telescope->alt() / 1000.0);

        # Disable refraction for apparent RA/Dec calculation.
        $station->set('refraction', 0);

        $self->{'eci_station'} = $station;
    }

    # Call superclass telescope method.
    return $self->SUPER::telescope(@_);
}

=back

The following accessors can be used to retrieve optional parameters
(supported for parsing and rewriting TLEs but not used in calculations):

=over 4

=item B<class>

Classification (U: unclassified, C: classified, S: secret).

=cut

sub class {
    my $self = shift;
    return $self->{'class'};
}

=item B<intl_desig>

2-digit launch year, 3-digit launch number, piece.

=cut

sub intl_desig {
    my $self = shift;
    return $self->{'intl_desig'};
}

=item B<first_d>

First derivative of mean motion.

=cut

sub first_d {
    my $self = shift;
    return $self->{'first_d'};
}

=item B<second_d>

Second derivative of mean motion.

=cut

sub second_d {
    my $self = shift;
    return $self->{'second_d'};
}

=item B<ephem_type>

Ephemeris type.

=cut

sub ephem_type {
    my $self = shift;
    return $self->{'ephem_type'};
}

=item B<elset_num>

Element set number.

=cut

sub elset_num {
    my $self = shift;
    return $self->{'elset_num'};
}

=item B<rev_at_epoch>

Revolutions.

=cut

sub rev_at_epoch {
    my $self = shift;
    return $self->{'rev_at_epoch'};
}

=back

=head2 General Methods

=over 4

=item B<array>

Give a 11-element standard Astro::Coords array representation of
this object.  The array contains:

=over 4

=item 0

Coordinate type ("TLE").

=item 1

RA (undef).

=item 2

Dec (undef).

=item 3

Epoch (fractional UNIX epoch timestamp).

=item 4

Bstar (inverse Earth radii).

=item 5

Inclination (radians).

=item 6

RA of ascending node (radians).

=item 7

Eccentricity.

=item 8

Perigee (radians).

=item 9

Mean anomaly (radians).

=item 10

Mean motion (revolutions per day).

=back

The ordering of these terms has been chosen to match that conventionally
used when printing TLEs.

=cut

sub array {
    my $self = shift;

    return (
        $self->type(),
        undef,
        undef,
        $self->{'epoch'}->hires_epoch(),
        $self->{'bstar'},
        $self->{'inclination'}->radians(),
        $self->{'raanode'}->radians(),
        $self->{'e'},
        $self->{'perigee'}->radians(),
        $self->{'mean_anomaly'}->radians(),
        $self->{'mean_motion'},
    );
}

=item B<apparent>

Calculate apparent RA and Declination of the object from the
given telescope.

=cut

sub apparent {
    my $self = shift;

    # Check for cached values.
    my ($ra_app, $dec_app) = $self->_cache_read('RA_APP', 'DEC_APP');

    unless ((defined $ra_app) and (defined $dec_app)) {
        my $station = $self->{'eci_station'};
        die 'station (i.e. telescope) not defined' unless defined $station;

        my $object = $self->{'eci_object'};
        die 'object not defined' unless defined $object;

        my $dt = $self->datetime();
        # Astro::Coords still allows the old Time::Piece objects to be used
        # and those don't support hires_epoch.
        my $epoch = UNIVERSAL::isa($dt, 'Time::Piece')
                  ? $dt->epoch()
                  : $dt->hires_epoch();

        # Set the object's "universal" time in order to avoid a confusing
        # error message if the sgp4r method fails.  In that case
        # Astro::Coord::ECI::TLE attempts to generate an error message
        # but fails to do so if the object doesn't have the time set.
        $object->universal($epoch);

        $object->sgp4r($epoch);
        my ($ra, $dec, $range) = $station->equatorial($object);

        $ra_app = new Astro::Coords::Angle::Hour($ra, units => 'radians');
        $dec_app = new Astro::Coords::Angle($dec, units => 'radians');

        $self->_cache_write('RA_APP' => $ra_app, 'DEC_APP' => $dec_app);
    }

    return ($ra_app, $dec_app);
}

=item B<stringify>

Return a string representation of the object.

=cut

sub stringify {
    my $self = shift;

    return join ' ', 'TLE', $self->epoch_year(), map {sprintf '%.3f', $_} (
        $self->epoch_day(),
        $self->{'bstar'},
        $self->{'inclination'}->degrees(),
        $self->{'raanode'}->degrees(),
        $self->{'e'},
        $self->{'perigee'}->degrees(),
        $self->{'mean_anomaly'}->degrees(),
        $self->{'mean_motion'},
    );
}

=item B<type>

Return the type name associated with the coordinate system, which in the
case of this class is always TLE.

=cut

sub type {
    return 'TLE';
}

=back

=cut

1;
