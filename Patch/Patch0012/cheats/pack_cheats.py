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

# Reads MAME cheats in xml files and packs them in a binary database file to
# be read from the SD card by the NSDL BIOS patch

# Since action formulas are only of a few types, they're lazily parsed.
# Strict evaluation would make my brain hurt.

# Output data format:
#   Game count.w
#   Offset to dictionary.w
#   Index: Unique block made of 4-byte entries for each game:
#     NGH.w: Game's NGH number in normal BCD format
#     Offset.w: Offset to where the cheat list for that game is
#   Cheat lists: blocks of variable length entries for each game:
#     Count.b: Number of cheats for this game
#     Offset.w: Offset to where the action data for the cheat is
#     Desc.v: Text description of the cheat, null-terminated string
#   Action data: entries for action data for each cheat:
#     Size.b: Size of the action data in bytes
#     Type.b: Bitmap containing the cheat type (one-off or VBL), the data size (B, W or L) and the opcode
# Opcode 0: Direct write
# address.w data.v
# Opcode 1: Indirect+offset write
# address.w offset.w data.v
# Opcode 2: Mask (clear)
# address.w mask.v
# Opcode 3: Mask and set
# address.w mask.v data.v

from xml.dom import minidom, Node
import random
import os
import operator

word_list = [
    "P1 ",
    "P2 ",
    "Inf. ",
    "Energy",
    "lways ",
    "Time",
    "Power",
    "has ",
    "Drain ",
    "All ",
    "Set ",
    "Max ",
    "Wins",
    "Lives",
    "core",
    "Get ",
    "Invincibility",
    "Finish ",
    "Fire",
    "Rapid",
    "this ",
    "Never ",
    "Continues",
    "Round",
    "Boss",
    "Guard",
    "Penalt",
    "Crush",
    "Recover"
]

subs_dict = {}
i = 128
for word in word_list:
    subs_dict[word] = i
    i += 1

def MakeBytes(data_size, data):
    data_out = bytearray()
    if data_size == 1:
        data_out.append(data)
    elif data_size == 2:
        data_out.append((data >> 8) & 255)
        data_out.append(data & 255)
    elif data_size == 4:
        data_out.append((data >> 24) & 255)
        data_out.append((data >> 16) & 255)
        data_out.append((data >> 8) & 255)
        data_out.append(data & 255)
    else:
        print("Unsupported data size: " + data_size) 
        exit()
    return data_out

desc_max_length = 24

action_acc = 0
entry_acc = 0
word_dict = {}   # Used to list often-used words for silly compression
bytepair_dict = {}
file_count = 0
text_size_acc = 0
game_data = []

final_data = bytearray()

for file in os.listdir("."):
    skipped_count = 0
    if file.endswith(".xml"):
        file_count += 1

        doc = minidom.parse(file)
        
        # Get NGH number tag (needs to be added manually !)
        NGH = doc.getElementsByTagName('NGH')
        if (len(NGH) != 1):
            print("NGH number not found for " + file)
            exit()
            continue
        ngh_number = int(NGH[0].childNodes[0].data, 16)

        cheat_count = 0
        cheat_data = []
        for cheat in doc.getElementsByTagName('cheat'):
            desc = cheat.getAttribute('desc')
            if desc == "Select Cartridge/NeoGeo Type":
                continue
            if desc == "Skip Boot Animations":
                continue

            if len(desc) > 1:
                # Stupid
                desc = desc.replace("now!", "")
                desc = desc.replace("Now!", "")
                desc = desc.replace("minimum", "min")
                desc = desc.replace("Minimum", "Min")
                desc = desc.replace("maximum", "max")
                desc = desc.replace("Maximum", "Max")
                desc = desc.replace("Infinite", "Inf.")
                desc = desc.replace("infinite", "inf.")
                desc = desc.replace("character", "char")
                desc = desc.replace("Character", "Char")

                if len(desc) > desc_max_length:
                    desc = desc[0:desc_max_length]
                    trimmed_desc = True
                else:
                    trimmed_desc = False

                if len(cheat.getElementsByTagName('parameter')) > 0:
                    #print("  Parametrized cheat, skip")
                    skipped_count += 1
                    continue

                script = cheat.getElementsByTagName('script')

                if len(script) > 1:
                    #print("  Multiple scripts, skip")
                    skipped_count += 1
                    continue
                elif len(script) == 1:
                    script_type = script[0].getAttribute('state')

                    action_code = bytearray()
                    action_code.append(0)   # Action code size, filled in later

                    if script_type == 'run':
                        script_type_str = "each frame"
                        script_type = 1
                    elif script_type == 'on':
                        script_type_str = "at enable"
                        script_type = 2
                    elif script_type == 'off':
                        # Should not occur, as cheats with multiple scripts are ignored right now
                        print("Script type error")
                        exit()
                        script_type_str = "at disable"
                        script_type = 3

                    action_count = 0
                    for action in script[0].getElementsByTagName('action'):
                        destination = action.childNodes[0].data.split('@')
                        
                        if (action.getAttribute('condition')):
                            #print("  Conditional action, skip")
                            break

                        #if len(destination) != 2:
                        #    print("  Complex formula, skip")
                        #    exit()
                        #    break
                        #else:
                        opleft = destination[0].split('.')
                        data_size = opleft[1]

                        if opleft[0] != 'maincpu':
                            # Music disable cheats cause this
                            #print("  Destination is not maincpu !")
                            break
                        else:
                            operation = action.childNodes[0].data.split('@')[-1].split('=')

                            if data_size == 'pb':
                                data_size_str = "RAM byte"
                                xor_mask = 0xFF
                                data_size = 1
                            elif data_size == 'pw':
                                data_size_str = "RAM word"
                                xor_mask = 0xFFFF
                                data_size = 2
                            elif data_size == 'pd':
                                data_size_str = "RAM longword"
                                xor_mask = 0xFFFFFFFF
                                data_size = 4
                            else:
                                print("Unsupported data size: " + data_size) 
                                exit()

                            opcode = -1
                            if len(destination) == 3:
                                # Check if this is a complex formula
                                if destination[1] == "(maincpu.pd":
                                    # Indirect + offset
                                    params = operation[0].split(')+')
                                    if params[1][-1] == ')':
                                        params[1] = params[1][0:-1]
                                    address = int(params[0], 16)
                                    offset = int(params[1], 16)
                                    data = int(operation[1], 16)
                                    opcode = 1  # Indirect offset write
                                elif '|' in destination[1]:
                                    # Bit set/reset
                                    addr_dest = destination[1].split('|')[0].split('=')[0]
                                    data = int(destination[1].split('|')[0].split('=')[1], 16)
                                    addr_src = destination[2].split(' ')[0]
                                    op_name = destination[2].split(' ')[1]
                                    val_mask = destination[2].split(' ')[2].replace(')', '')
                                    if '~' in val_mask:
                                        val_mask = int(val_mask.replace('~', ''), 16) ^ xor_mask
                                        if op_name == "BAND":
                                            if addr_src == addr_dest:
                                                if data == 0:
                                                    op_name = "BCLR"
                                                    opcode = 2
                                                else:
                                                    op_name = "BSET"
                                                    opcode = 3
                                                address = int(addr_src, 16)
                                                mask_bytes = MakeBytes(data_size, val_mask)
                                                #print("  " + op_name + " " + hex(data) + " mask " + hex(val_mask) + " at " + addr_dest + ":")
                                            else:
                                                print("addr_src != addr_dest")
                                                exit()
                                        else:
                                            print("op_name not BAND")
                                            exit()
                                    else:
                                        print("val_mask is not inverted")
                                        exit()
                            elif len(destination) == 2:
                                address = int(operation[0], 16)
                                data = int(operation[1], 16)
                                opcode = 0  # Direct write

                            if opcode == -1:
                                #print("  Complex formula, skip")
                                break

                            if (address < 0x100000) or (address > 0x10FFFF):
                                print("  Address isn't in RAM !")
                                exit()

                            data_bytes = MakeBytes(data_size, data)

                            action_code.append((script_type << 6) | (data_size << 3) | opcode)
                            action_code.append((address >> 8) & 255)
                            action_code.append(address & 255)

                            if (opcode == 0):
                                action_code.extend(data_bytes)
                            elif (opcode == 1):
                                action_code.append((offset >> 8) & 255)
                                action_code.append(offset & 255)
                                action_code.extend(data_bytes)
                            elif (opcode == 2):
                                action_code.extend(mask_bytes)
                            elif (opcode == 3):
                                action_code.extend(mask_bytes)
                                action_code.extend(data_bytes)

                            action_count += 1

                    if (action_count > 0):

                        if (trimmed_desc == True):
                            print("  TRIM ! " + desc)
                            exit()
                        
                        action_code[0] = len(action_code)

                        # Stats - byte pairs
                        for c in range(0, len(desc) - 1):
                            bytepair = desc[c:c+2]
                            if bytepair in bytepair_dict:
                                bytepair_dict[bytepair] += 1
                            else:
                                bytepair_dict[bytepair] = 1

                        alias_desc = desc
                        for word in subs_dict:
                            alias_desc = alias_desc.replace(word, unichr(subs_dict[word]))

                        # Stats
                        for word in alias_desc.split(' '):
                            if word in word_dict:
                                word_dict[word] += 1
                            else:
                                word_dict[word] = 1

                        desc_data = bytearray(alias_desc.encode('latin_1'))
                        desc_data.append(0)

                        text_size_acc += len(alias_desc)
                        print("  %s: %s" % (desc, ''.join(format(x, '02X') for x in action_code)))

                        for game_cheat in cheat_data:
                            if action_code == game_cheat[1]:
                                print("Duplicate in %s !" % file)
                                exit()

                        cheat_data.append([desc_data, action_code])

                        cheat_count += 1
                        action_acc += action_count

        if (cheat_count == 0):
            print(file + ": No cheats\n")
        elif (cheat_count > 32):
            print(file + ": Too many cheats: " + str(cheat_count) + "\n")
            exit()
        else:
            print(file + ": " + str(cheat_count) + "/" + str(skipped_count) + "\n")
            entry_acc += cheat_count
            game_data.append([ngh_number, cheat_count, cheat_data])

        doc.unlink()

final_data = bytearray()
desc_data = bytearray()
action_data = bytearray()

final_data.append(0)   # Game count
final_data.append(len(game_data))
final_data.append(0)    # Dictionnary offset (filled later)
final_data.append(0)

index_size = 4 * len(game_data) + 4

# Predict desc_data size
desc_data_size = index_size
for data in game_data:
    desc_data_size += 1
    for cheat in data[2]:
        desc_data_size += (len(cheat[0]) + 2)

# Generate cheat data and index at the same time
seen_NGHs = []
for data in game_data:
    if data[0] in seen_NGHs:
        print("Multiple occurences of same NGH " + str(data[0]))
        exit()
    seen_NGHs.append(data[0])  # NGH number

    final_data.append(data[0] >> 8)     # Index NGH number
    final_data.append(data[0] & 255)

    cheat_count = data[1]
    #desc_data_size = 2 + 2*cheat_count + len(data[2][0])  # Cheat count.w + offsets and desc strings
    #if (len(cheat_data) & 512) != ((len(cheat_data) + cheat_data_size) & 512):
    #    print("Crosses boundary ! Padding")
    #cheat_data.extend(b"\0" * (512 - (len(cheat_data) & 511)))

    cur_desc_address = len(desc_data) + index_size
    final_data.append(cur_desc_address >> 8)     # Index offset to desc data
    final_data.append(cur_desc_address & 255)

    desc_data.append(cheat_count)   # cheat_count.b
    for cheat in data[2]:
        cur_action_address = len(action_data) + desc_data_size
        desc_data.append(cur_action_address >> 8)
        desc_data.append(cur_action_address & 255)
        desc_data.extend(cheat[0])    # desc_data
        action_data.extend(cheat[1])  # action_data


final_data.extend(desc_data)
final_data.extend(action_data)
offset = len(final_data)
final_data[2] = (offset >> 8) & 255
final_data[3] = offset & 255
for word in word_list:
    final_data.extend(bytearray(word.encode('latin_1')))
    final_data.append(0)
    final_data.extend(b"\0" * (16 - (len(word) +1)))

print("Total files: " + str(file_count))
print("Total cheats: " + str(entry_acc))
print("Total actions: " + str(action_acc))
print("Total text size: " + str(text_size_acc))

out_file = open("out.bin", "wb")
out_file.write(final_data)

#print(sorted(word_dict.items(), key=lambda x: x[1]))

