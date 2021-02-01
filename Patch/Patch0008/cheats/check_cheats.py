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

# Reads out.bin and tries to parse it to see if everything is in order
import random
import os
import operator

out_file = open("out.bin", "rb")
file_data = bytearray(out_file.read())

game_count = file_data[3]

index_data = []
address = 4
for game in range(0, game_count):
    NGH = (file_data[address] << 8) + file_data[address+1]
    data_address = (file_data[address+2] << 8) + file_data[address+3]
    index_data.append([NGH, data_address])
    print("NGH " + hex(NGH) + " at " + hex(data_address))
    address += 4

for game in index_data:
    address = game[1]
    cheat_count = file_data[address + 1]
    address += 2
    print("NGH " + hex(game[0]) + " has " + str(cheat_count) + " cheats")
    for cheat in range(0, cheat_count):
        # Read action data offset
        action_offset = (file_data[address] << 8) + file_data[address+1]
        address += 2
        # Read desc string
        desc = "  "
        while True:
            char = file_data[address]
            address += 1
            if char == 0:
                break
            if char < 128:
                desc += chr(char)
        print(desc)

        # Read action codes
        while True:
            type_byte = file_data[action_offset]
            action_offset += 1
            if type_byte == 0:
                break

            opcode = type_byte & 3
            data_size = (type_byte >> 3) & 7
            script_type = (type_byte >> 6) & 3

            op_addr = (file_data[action_offset] << 8) + file_data[action_offset+1]
            action_offset += 2    # Skip address

            #if (opcode == 0) or (opcode > 2):
            #    print("    Opcode error")
            #    exit()

            op_data = 0
            op_mask = 0

            if opcode == 1:
                op_offset = (file_data[action_offset] << 8) + file_data[action_offset+1]
                action_offset += 2    # Skip offset
            elif opcode == 3:
                for readbyte in range(0, data_size):
                    op_mask <<= 8
                    op_mask += file_data[action_offset]
                    action_offset += 1

            for readbyte in range(0, data_size):
                op_data <<= 8
                op_data += file_data[action_offset]
                action_offset += 1

            if (data_size == 0) or (data_size > 4):
                print("    Data size error")
                exit()


            print("    Script type " + str(script_type) + " - Opcode " + str(opcode))
            if opcode == 0:
                print("    Write " + hex(op_data) + " to " + hex(op_addr))
            elif opcode == 1:
                print("    Write " + hex(op_data) + " to (" + hex(op_addr) + ")+" + hex(op_offset))
            elif opcode == 2:
                print("    Mask " + hex(op_data) + " at " + hex(op_addr))
            elif opcode == 3:
                print("    Mask " + hex(op_mask) + " and set " + hex(op_data) + " at " + hex(op_addr))

exit()
