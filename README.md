# i2c_lessons
This folder contains binaries and code for all lessons on i2c.

i2c requires 4 wires to work. 3.3v and GND are obvious, but in addition there is SDA and SCL to connect - a data line and a clock signal.

Either the UEXT connector on the Olimex Agon Light 2 can be used, or the correct pins on any othere Agon machine's GPIO bus.

![](./io_uext2.png)



<B>REAL TIME CLOCK modules</B>

This is for RTC modules based on the DS 3231 chip.

<b>mos_setrtc.bin</b>

Place this binary in your SD card's BIN folder.
Add the command 'mos_setrtc' to your autoexec.txt file if you want it to run after each boot.
Or, call it whenever you want with:
<i>*mos_setrtc</i>

<b>settime.bin</b>

Place this binary in your SD card's BIN folder.
Use the command:

<i>*setttime seconds minutes hours day date month year</i>

eg: 
<i>*settime 0 21 17 1 31 12 24</i>

For 5:21pm and 0 seconds, Sunday, 31st December 2024

(You don't need to type the '*', that is just to indicate the command prompt)

![](./agontime.jpg)
![](./rtc%20module.jpg)

