# Neo CD SD Loader

SD card game loader mod kit for the Neo Geo CD - http://www.furrtek.org/sdloader/

* TODO: Add schematics in PDF format
* TODO: Add links to tools (ASW, gfxcc, flip.exe...)

# Rules
First of all, a few things need to be perfectly clear (this is the part where I sound like an asshole).

This was NOT made over a week-end. Almost a whole year of my life went into the development, the manufacturing,
the documentation and the distribution of this project.

I have absolutely no obligation to share these files. The only two reasons I chose to do so are:
1. I don't want the work to be lost.
2. I want to forget about it and move on to new projects.

To put it simply, **these files are literally a gift** which come with a simple rule:
you can do almost anything you want with them (see LICENSE), but ***I will NOT provide any kind of support***.

Manufacturing issues ? Component sourcing problems ? Software questions ? If the answer isn't in this README,
in `Docs/doc.odt`, or in source code comments, sorry but you're on your own.

If you chose to ignore this paragraph and decide to send me an e-mail starting with something like "I know you don't provide any help except for clients, but..." like several already have, you'll regret it.

# Hardware

The PCB files are unbranded. Apart from the "Neo CD SD Loader" logo, all references to my name and my
website were removed.

The assembly files only cover SMD components.

## Main board
Same for all SD card slot options. Manual assembly required for the CDDA header pins and the PLCC68 socket.
* `HW/NGCDLoaderE`: GERBERs, BOM and pick & place files (top-loading console version).
* `HW/NGCDLoaderF`: GERBERs, BOM and pick & place files (front-loading console version).

## Full size SD card slot assembly for top-loading consoles
These go together. Manual assembly required, connect together with header mentionned above.
* `HW/UserBoardB`: Support board - GERBERs, BOM and pick & place files.
* `HW/SlotBoardC`: Slot board - GERBERs, BOM and pick & place files.

## MicroSD card slot assembly for top-loading consoles
These go together. Manual assembly required, connect together with header mentionned above.
* `HW/UserBoardD`: Support board - GERBERs, no assembly files, done by hand.
* `HW/SlotBoardD`: Slot board - GERBERs, BOM and pick & place files.

## MicroSD card slot for front-loading consoles
* `HW/SlotBoardE`: Single slot board - GERBERs, BOM and pick & place files.

# Software

See `Docs/doc.odt` for details about how things work.

MCU firmware built with STM32CubeIDE, BIOS patches built with the macro assembler AS, CPLD bitstream built with Quartus 12.

# How to build

* Have the main board, and one of the UserBoard/SlotBoard pair made with the following specs: 2-layers 1.6mm FR4, 6/6mils, min hole 0.3mm, HASL, any color (full size SD slot PCB looks better in black).
* Order:
  * All the components if you're assembling the boards yourself (NOT recommended). See BOM files.
  * FFC: 12 conductors, 1mm pitch, same side contacts, length 200mm. LCSC part C12148 is fine.
  * SMT PLCC68 socket: MILL-MAX 540-44-068-17-400000. Be VERY careful about these, other models (such as MILL-MAX 940-44-068-17-400000 and 3M 8468-21B1-RK-TP) may cause serious connectivity issues.
  * Right-angle 2mm pitch 3-pin header.
  * For the full size SD card version: Straight 2.54mm pitch 12-pin header.
  * For the Micro SD card version: Straight 1.27mm pitch 12-pin header.
* Cut away the bottom plate of the PLCC socket.
* Solder on to main board with beveled corner in the bottom right with the silkscreen arrow pointing to the right.
* Solder two 3-pin headers in CDDA marked locations on the main board, pins pointing outwards.
* Assemble UserBoard and SlotBoard together with the appropriate 12-pin header. Orientation: silkscreen arrows must match and be visible. Space boards 2mm+ to allow bending.
* Clean PLCC socket contacts with IPA.
* Plug main board in console, or power it with +5V via a wire to the 5V rail (C1 for example).
* Connect USB cable (in order: > D+, D-, GND) to the 3 unmarked holes next to one of the CDDA footprints.
* Bridge the two half-circle pads near the MCU together, power up, USB device "STM32 BOOTLOADER" should be detected.
* Run program.bat in the `ProdBoot003` folder to program the MCU bootloader.
* Power off, remove USB cable, clear MCU programming pads.
* All done ! Follow installation instructions.
