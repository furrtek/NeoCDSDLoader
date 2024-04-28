#
# Copyright (C) 2020 Sean Gonsalves
#
# This file is part of Neo CD SD Loader.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.

f = open("sample_table.inc", "w")

for i in range(0, 127):
    if (i == 0x30):
        f.write("\t.db $00, $00, $01, $0C, $01\t; " + hex(i) + "\n")
    elif (i == 0x41):
        f.write("\t.db $01, $D2, $01, $D6, $01\t; " + hex(i) + "\n")
    elif (i == 0x42):
        f.write("\t.db $01, $D7, $01, $DF, $01\t; " + hex(i) + "\n")
    elif (i == 0x43):
        f.write("\t.db $01, $E0, $01, $E8, $01\t; " + hex(i) + "\n")
    elif (i == 0x44):
        f.write("\t.db $01, $E9, $01, $ED, $01\t; " + hex(i) + "\n")
    elif (i == 0x45):
        f.write("\t.db $01, $EE, $01, $F2, $01\t; " + hex(i) + "\n")
    else:
        f.write("\t.db $00, $00, $00, $00, $00\t; " + hex(i) + "\n")

f.close()
