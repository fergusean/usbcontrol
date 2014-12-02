usbcontrol
==========
List, suspend, and resume USB devices on OS X from the command line based on vendor and product ID and/or location ID. The location ID, to quote , "is a 32 bit number which is unique among all USB devices in the system, and which will not change on a system reboot unless the topology of the bus itself changes".

Suspended devices act as if they're not plugged into your computer. As such, the power to the USB port is turned off. HID devices appear to resume as soon as the process terminates, but all other devices tested remain suspended until either physically re-plugged or resumed via usbcontrol.

Usage
==========
usbcontrol list|suspend|resume [--vid=0x1234] [--pid=0x5678] [--location=0x123456789]
 
Lists, suspends, or resumes USB devices. Suspend & resume require a filter.
VID and PID must be used together. Location can be used with or without VID+PID.

Sample List Output
==========
```
vid=0x05ac pid=0x8006 release=0x0200 location=0xfa000000 vendor="Apple Inc." product="EHCI Root Hub Simulation" serial="(null)"
vid=0x05ac pid=0x8006 release=0x0200 location=0xfd000000 vendor="Apple Inc." product="EHCI Root Hub Simulation" serial="(null)"
vid=0x05ac pid=0x8005 release=0x0110 location=0x1a000000 vendor="Apple Inc." product="UHCI Root Hub Simulation" serial="(null)"
vid=0x05ac pid=0x8005 release=0x0110 location=0x5a000000 vendor="Apple Inc." product="UHCI Root Hub Simulation" serial="(null)"
vid=0x05ac pid=0x8005 release=0x0110 location=0x3a000000 vendor="Apple Inc." product="UHCI Root Hub Simulation" serial="(null)"
vid=0x05ac pid=0x8005 release=0x0110 location=0x5d000000 vendor="Apple Inc." product="UHCI Root Hub Simulation" serial="(null)"
vid=0x05ac pid=0x8005 release=0x0110 location=0x3d000000 vendor="Apple Inc." product="UHCI Root Hub Simulation" serial="(null)"
vid=0x05ac pid=0x8005 release=0x0110 location=0x1d000000 vendor="Apple Inc." product="UHCI Root Hub Simulation" serial="(null)"
vid=0x05e3 pid=0x0608 release=0x3298 location=0xfd100000 vendor="(null)" product="USB2.0 Hub" serial="(null)"
vid=0x05e3 pid=0x0608 release=0x3298 location=0xfd110000 vendor="(null)" product="USB2.0 Hub" serial="(null)"
vid=0x0a5c pid=0x4500 release=0x0100 location=0x5a100000 vendor="Apple Inc." product="BRCM2046 Hub" serial="(null)"
vid=0x05ac pid=0x1006 release=0x9615 location=0xfd130000 vendor="Apple, Inc." product="Keyboard Hub" serial="000000000000"
vid=0x05e3 pid=0x0608 release=0x3298 location=0xfd114000 vendor="(null)" product="USB2.0 Hub" serial="(null)"
vid=0x051d pid=0x0002 release=0x0090 location=0xfd120000 vendor="American Power Conversion" product="Back-UPS XS 1500G FW:866.L6 .D USB FW:L6 " serial="**MASKED**"
vid=0x0bc2 pid=0xa0a4 release=0x0100 location=0xfd140000 vendor="Seagate" product="Backup+ Desk" serial="**MASKED**"
vid=0x05ac pid=0x8215 release=0x0207 location=0x5a110000 vendor="Apple Inc." product="Bluetooth USB Host Controller" serial="**MASKED**"
vid=0x05ac pid=0x024f release=0x0074 location=0xfd132000 vendor="Apple Inc." product="Apple Keyboard" serial="(null)"
vid=0x1edb pid=0xbd43 release=0x0100 location=0xfa200000 vendor="Blackmagic Design" product="H.264 Pro Recorder" serial="(null)"
vid=0x1edb pid=0xbd43 release=0x0100 location=0xfd300000 vendor="Blackmagic Design" product="H.264 Pro Recorder" serial="(null)"
```
