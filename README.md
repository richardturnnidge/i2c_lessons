# i2c_lessons
This folder contains binaries and code for all lessons on i2c.

<B>REAL TIME CLOCK modules</B>

This is for RTC modules based on the DS 3231 chip.

<i>mos_setrtc.bin</i>

Place this binary in your SD card's BIN folder.
Add the command 'mos_setrtc' to your autoexec.txt file if you want it to run after each boot.
Or, call it whenever you want with:
*mos_setrtc

<i>settime.bin</i>

Place this binary in your SD card's BIN folder.
Use the command:

*setttime seconds minutes hours day date month year

eg: 
*settime 0 21 17 1 31 12 24

For 5:21pm and 0 seconds, Sunday, 31st December 2024

(You don't need to type the '*', that is just to indicate the command prompt)
