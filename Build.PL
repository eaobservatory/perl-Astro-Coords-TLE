#!/usr/bin/env perl

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

use strict;
use warnings;

use Module::Build;

new Module::Build(
    module_name => 'Astro::Coords::TLE',
    license => 'gpl3',
    requires => {
        'Astro::Coords' => 0,
        'Astro::Coord::ECI' => 0,
        'DateTime' => 0,
        'DateTime::Duration' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Number::Delta' => 0,
    },
    recommends => {
        'UKIRT::JunkTrack::Parse' => 0,
    },
)->create_build_script();
