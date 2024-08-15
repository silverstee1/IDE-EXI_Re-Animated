# IDE-EXI_Re-Animated
IDE-EXI for GameCube with front facing IDE connector slot.

Inspired by the front facing version made by Megalomaniac.

This uses the V2 IDE-EXI source released on GC-Forever and can be flashed directly as it is pin compatible
with the old IDE-EXI stick design.

https://www.gc-forever.com/forums/viewtopic.php?t=4843

You'll need to use Xilinx Impact or an XSVF player to flash the XC95144XL CPLD on the board using the JTAG header.
Make sure you have the capacitors soldered on before flashing as it will likely fail flashing if they aren't on the board.

6Pin clip that I use to help make flashing easier https://www.aliexpress.us/item/3256805030490716.html

You'll need either a Xilinx Platform cable such as this https://www.aliexpress.us/item/2251832404583497.html or Parallel port programmer to flash it via the Xilinx ISE in Impact, or some kind of XSVF Player that supports Flashing Xilinx XC95xxx CPLDs.

Example of CheapTag Parallel Port III DIY JTAG Cable for use in Xilinx Impact.

![cheaptag](https://github.com/user-attachments/assets/b19aa58e-b4ea-41fd-97be-7089c8e5e8da)



  

**Important**

When using the adapter make sure to have the Latest Version of Swiss.

https://github.com/emukidid/swiss-gc


![kicad_g6jn60xyCd](https://github.com/user-attachments/assets/e48d86ef-7825-4ca5-904c-26c82cf879d2)


![kicad_trGBMmJAJH](https://github.com/user-attachments/assets/e0d741aa-d3db-4362-bab1-34cb889fb254)


![20240814_181402](https://github.com/user-attachments/assets/237d5728-ccf0-4769-b158-24dc9456e817)


![20240814_182543](https://github.com/user-attachments/assets/c732d98a-bd5f-402f-9872-d9e99b31a5ad)



IDE-EXI_Re-Animated BOM
=====================================
The PCB must be ordered (e.g. from jlcpcb) in 1.6mm thickness with surface finish ENIG at minimum.

**3D Printed Case Enclosure**

You'll need to 3D print the case enclosure Top and Bottom pieces from the Case folder to use it in your Memcard Slot preferably on an FDM printer, 
the case screws are self tapping M2x4 pan head screws.

**IDE-EXI_Re-Animated PCB**

**C1:** 0402 0.1uF Capacitor (16V Min) - DigiKey Part# 490-3261-1-ND

LCSC Part# C71629

**C2:** 0402 0.1uF Capacitor (16V Min) - DigiKey Part# 490-3261-1-ND

LCSC Part# C71629

**R1:** 0402 100ohm Resistor - Digikey Part# 311-100LRCT-ND

LCSC Part# C106232

**R2:** 0402 10Kohm Resistor - Digikey Part# 1276-3431-1-ND

LCSC Part# C60490

**R3:** 0402 10Kohm Resistor - Digikey Part# 1276-3431-1-ND

LCSC Part# C60490

**R4:** 0402 14ohm Resistor - Digikey Part# P14.0LCT-ND

LCSC Part# C400609

**D1:** 0402 Blue Led 20ma (Dot on PCB footprint marks LED Cathode side) - Digikey Part# 1516-1215-1-ND

LCSC Part # C965797

**IDE Socket:** DigiKey Part# ED10529-ND

LCSC Part# C9138

**U1:** XC95144XL-10TQG100C CPLD - DigiKey Part# 122-1372-ND

LCSC Part# C45126

CPLD's from link I've ordered before that worked
Aliexpress: https://www.aliexpress.us/item/3256804827509319.html
