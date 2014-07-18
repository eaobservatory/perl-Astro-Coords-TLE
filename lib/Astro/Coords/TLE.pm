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

=item epoch_year

=item epoch_day

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

    # Convert epoch year and (fractional) day into a DateTime object.
    my $year = $opt{'epoch_year'};
    my $fracday = $opt{'epoch_day'};
    my $day = int($fracday);
    my $nanoseconds = 24000000000.0 * 3600.0 * ($fracday - $day);

    my $epoch = DateTime->from_day_of_year(
                    time_zone => 'UTC',
                    year => $year,
                    day_of_year => $day) +
                DateTime::Duration->new(nanoseconds => $nanoseconds);

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
