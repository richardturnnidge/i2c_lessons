# i2c_lessons
This folder contains binaries and code for all lessons on i2c. Whilst these lessons are aimed at z80 assembly language on the Agon light, the theory will be applicable to any microprocessor or computer, such as Raspberry Pi or Pico, Arduino models, and so on.

See accompanying videos at:

https://www.youtube.com/watch?v=WQATfp2rR_Y&list=PL-WZxPxo1iaBRPJj_mS7feUh_gO6pn-Qe&index=3


i2c requires 4 wires to work. 3.3v and GND are obvious, but in addition there is SDA and SCL to connect - a data line and a clock signal.

Either the UEXT connector on the Olimex Agon Light 2 can be used, or the correct pins on any other Agon machine's GPIO bus.

You can connect many different i2c devices at the same time, by linking from one to the next, as long as each device has a diffrent bus address. Some devices have fixed addresses, some can be set, or modified within a range (usually by jumpers or solder pads).

![](./io_uext2.png)

See the community docs for further pinout reference:
https://agonconsole8.github.io/agon-docs/GPIO/


<B>i2ctest.bin</B>
Place this binary in your MOS directory and you can call it at any time by typing:
<i>i2ctest</i>.
It will list the addresses of all modules attached to the i2c bus.

<B>PCF8574 module</B>
This is an 8bit digital i/o expander.

Default bus address: $20-28.

The sample code configures the module, then sends a series of bytes to change the output of 8 LEDs.

<B>PCF8575 module</B>
This is a 16bit digital i/o expander.
Default bus address: $20-28

Demonstrates reading button inputs and LED outputs.

<B>HT16K33 LED matrix module</B>

This is a 8x8 LED matrix.

Code allows the creation of a buffer to send data to the display. 

Two demo routines, one to send graphical characters to the display, and one to plot/clear random pixels.

Default bus address: $70-$77


<B>MCP4725 module</B>
This is a 12bit digital to analog output converter.
Default bus address: $62-61 ?

- TO DO-

<B>HTU21D module</B>
This is a temperature and humity sensor.
Default bus address: $40

- TO DO-

<B>VEML7700 module</B>
This is an ambient light level sensor.
Default bus address: $10

- TO DO-

<B>ADC1115 module</B>
This is a 4 channel analog to digital converter.
Default bus address: $48-4B

- TO DO-

<B>Nintendo WII Nunchuck controller</B>
This is controller has multiple sensors and buttons for user input.
Default bus address: $52

- TO DO-





<B>DS3231 REAL TIME CLOCK modules</B>
Default bus address: $68

This code has been written for RTC modules based on the DS3231 chip, and also assumes a bus address of $68.

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

