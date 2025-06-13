#
# Copyright (C) 2023 Salvo Giangreco
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
#

# UN1CA configuration file
ROM_VERSION="2.5.6"
ROM_VERSION+="-$(git rev-parse --short HEAD)"
ROM_CODENAME="Eureka"

# Source ROM firmware

# Galaxy A36 (parrot)
SOURCE_FIRMWARE="SM-A366B/EUX/355838615182742"
SOURCE_EXTRA_FIRMWARES=()
SOURCE_PRODUCT_CODE=SM-A366BLVGEUE
SOURCE_HAS_SYSTEM_EXT=true
SOURCE_HAS_PRODUCT=true
SOURCE_SUPER_GROUP_NAME="qti_dynamic_partitions"

return 0
