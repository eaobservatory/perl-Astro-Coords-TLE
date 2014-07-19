# Copyright (C) 2014 Science and Technology Facilities Council.
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

use DateTime;
use DateTime::Duration;

use parent qw/Astro::Coords/;

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

    return bless $self, (ref $class) || $class;
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
