# i2c_lessons
This folder contains binaries and code for all lessons on i2c.

i2c requires 4 wires to work. 3.3v and GND are obvious, but in addition there is SDA and SCL to connect - a data line and a clock signal.

Either the UEXT connector on the Olimex Agon Light 2 can be used, or the correct pins on any other Agon machine's GPIO bus.

![](./io_uext2.png)

See the community docs for further pinout reference:
https://agonconsole8.github.io/agon-docs/GPIO/

<B>PCF8574 module</B>
This is an 8bit digital i/o expander.

- TO DO-

<B>PCF8575 module</B>
This is a 16bit digital i/o expander.

- TO DO-

<B>MCP4725 module</B>
This is a 12bit digital to analog output converter.

- TO DO-

<B>HTU21D module</B>
This is a temperature and humity sensor.

- TO DO-

<B>VEML7700 module</B>
This is an ambient light level sensor.

- TO DO-

<B>ADC1115 module</B>
This is a 4 channel analog to digital converter.

- TO DO-

<B>REAL TIME CLOCK modules</B>

This code has been written for RTC modules based on the DS 3231 chip, and also assumes a bus address of $68.

<b>settime.bin</b>

Place this binary in your SD card's MOS folder. This command will allow you to set the time stored on the DS3231 module. With an onboard battery, this will keep the correct time, even when your Agon is powered down.

Use the command:

<i>*setttime seconds minutes hours day date month year</i>

eg: 
<i>*settime 0 21 17 1 31 12 24</i>

For 5:21pm and 0 seconds, Sunday, 31st December 2024

(You don't need to type the '*', that is just to indicate the command prompt)



<b>mos_setrtc.bin</b>

This command is to set the Agon's internal clock to the time stored on your RTC module. So, after the Agon has booted, for example, you can automatically set the internal clock to be the correct time.

Place this binary in your SD card's MOS folder.
Add the command 'mos_setrtc' to your autoexec.txt file if you want it to run after each boot.
Or, call it whenever you want with:

<i>*mos_setrtc</i>

You can check from MOS that the correct time has been set, by using the built-in command:

<i>*time</i>


![](./agontime.jpg)
![](./rtc%20module.jpg)

