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

use parent qw/Astro::Coords/;

our $VERSION = '0.001';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Construct a new object.

=cut

sub new {
    my $class = shift;
    my %opt = @_;

    my $self = {
        name => $opt{'name'},
    };

    return bless $self, (ref $class) || $class;
}

=back

=head2 Accessor Methods

=over 4

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
