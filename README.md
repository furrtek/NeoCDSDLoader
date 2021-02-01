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

To put it simply, '''these files are literally a gift''' which come with a simple rule:
you can do almost anything you want with them (see LICENSE), but I will NOT provide any kind of support.

Manufacturing issues ? Component sourcing problems ? Software questions ? If the answer isn't in this README,
in `Docs/doc.odt`, or in source code comments, sorry but you're on your own.

# Hardware

The PCB files are unbranded. Apart from the "Neo CD SD Loader" logo, all references to my name and my
website were removed.

The assembly files only cover SMD components.
Back-side and through hole components were soldered manually:
* Main PCB CPU socket: Modified MILL-MAX 540-44-068-17-400000 SMT PLCC68 socket (bottom plate removed).
Be VERY careful about those, other models may cause serious connectivity issues (such as MILL-MAX 940-44-068-17-400000 and 3M 8468-21B1-RK-TP).
* Main PCB CDDA connector: Right-angle 2mm pitch 3-pin header.
* Full size SD slot PCB: Straight 2.54mm pitch 12-pin header.
* Micro SD slot PCB: Straight 1.27mm pitch 12-pin header.

PCB are all 2-layers 1.6mm FR4, 6/6mils, min hole 0.3mm, HASL, any color (full size SD slot PCB looks better in black).

FFC: 12 conductors, 1mm pitch, same side contacts, length 200mm. LCSC part C12148 is fine.

## Main board
Same one for both SD card slot options. Manual assembly required for the CDDA header and the PLCC68 socket.
* `HW/NGCDLoaderE`: GERBERs, BOM and pick & place files.

## Full size SD card slot assembly
These go together. Manual assembly required, connect together with header mentionned above.
* `HW/UserBoardB`: Support board - GERBERs, BOM and pick & place files.
* `HW/SlotBoardC`: Slot board - GERBERs, BOM and pick & place files.

## MicroSD card slot assembly
These go together. Manual assembly required, connect together with header mentionned above.
* `HW/UserBoardD`: Support board - GERBERs, no assembly files, done by hand.
* `HW/SlotBoardD`: Slot board - GERBERs, BOM and pick & place files.

# Software

See `Docs/doc.odt` for details.

MCU firmware built with STM32CubeIDE, BIOS patches built with the macro assembler AS, CPLD bitstream built with Quartus 12.
