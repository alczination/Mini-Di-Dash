### ***0x61A***

Przyklad: A9 24 04 5B 4B A0 00 02



**GEMINI:**

* Przebieg:

/ Byte 0: 

&nbsp;	=> 0424A9 => 271.529km



* Dzienny przebieg (Trip Meter)

/ Byte 3 i 4: 4B5B 

&nbsp;	=> 19.291/10 = 192.9km



* Inspekcja serwisowa

/ Byte 5, 6 i 7: A0 00 02



### ***0x613***

Przyklad: 10 6A 0B 00 00 09 10 00



**DOKUMENTACJA:**

* Przebieg: \[Lepiej wziąć ten]

/ Byte 0 - KM\_CTR\_CAN - LSB => 10

/ Byte 1 - KM\_CTR\_CAN - MSB => 6A



&nbsp;	Calculation = HEX value (MSB\_LSB) \* 10

&nbsp;	--> 6A10 = 27.152 \* 10



* Poziom paliwa (w litrach):

/ Byte 2 - FTL\_CAN => 0B



&nbsp;	Calculation = HEX value

&nbsp;	--> 0B = 11 litrow



* Rezerwa paliwa lampka:

/ Bit 7 - FTL\_RES\_CAN => 00



&nbsp;	Calculation = HEX value

&nbsp;	--> 00 - Off

&nbsp;	--> 01 - On



* Czas startu:

/ Byte 3 - T\_REL\_CAN - LSB => 00

/ Byte 4 - T\_REL\_CAN - MSB => 00



&nbsp;	Calculation = HEX value (MSB\_LSB)

&nbsp;	--> 0000 = 0 minut



### ***0x615***

Example: 00 00 00 10 02 00 00 00



**DOKUMENTACJA:**

* Tryb dzienny (lub wylaczone swiatla):

/ Bit 2 - LV\_LGT => 0



* Czujnik otwarcia maski:

/ Bit 3 - LV\_HS => 0



* Temperatura otoczenia:

/ Byte 3 - TAM\_CAN => 10

&nbsp;	Calculation = HEX value

&nbsp;	--> 16 stopni



* Drzwi przelacznik:

/ Byte 4, Bit 0 - LV\_DOOR => 0

&nbsp;	--> 0 = Off

&nbsp;	--> 1 = On



* Hamulec reczny przelacznik:

/ Byte 4, Bit 1 - LV\_HBR => 1

&nbsp;	--> 0 = Off

&nbsp;	--> 1 = On



* Wyswietlana predkosc ????



### ***0x61F***

Example: 00 74 0B 40 40 00 00 00



**GEMINI:**

* Przelacznik swiatel

/ Byte 1 (0x74) Bit 2, 4, 5 i 6



* Kierunkowskazy

/ Byte 2 (0x0B) Bit 0, 1, 3



* Manetka wycieraczek, kat rolki od regulacji swiatel, deska rozdzielcza dimmer

/ Byte 3, 4 (0x40 i 0x40)



### ***0x153***

Example: 00 51 00 00 00 FF 00 80



**DOKUMENTACJA:**

* Awaria systemu ABS lampka

/ Byte 0, Bit 7 - LV\_ABS\_LED => 0

&nbsp;	--> 0 = Off

&nbsp;	--> 1 = On



* Kontrolka ASC

/ Byte 1, Bit 1 => 51 = 0101 00**0**1 => 0

&nbsp;	--> 0 = Off

&nbsp;	--> 1 = On



* Predkosc

/ Byte 2 - VSS \[MSB]

&nbsp;	Calculation 

&nbsp;	= ( (HEX\[MSB] \* 256) + HEX\[LSB]) \* 0.0625



0x1F0

Example: 0A 20 0A 00 0A 00 0A 00



* Predkosc dla każdego osobnego kola





### ***0x1F8***

Example: 00 00 00 00 FE FF 00 00



**GEMINI:**

* Czujnik ciśnienia hamowania

/ 4-5 Byte



* Akcelerometr / G-Sensor





### ***0x316***

Example: 01 00 00 00 00 00 00 00



**DOKUMENTACJA:**

* Torque w %

/ Byte 1 - TQI\_TQR\_CAN

&nbsp;	Calculation =

&nbsp;	HEX \* 0.390625



* RPMy

/ Byte 2 - N\_ENG \[LSB]

/ Byte 3 - N\_ENG \[MSB]

&nbsp;	Calculation =

&nbsp;	((HEX\[MSB] \* 256) + HEX\[LSB]) \* 0.15625



### ***0x336***

Example: 00 00 FE 02 A7 0F E0 82





### ***0x329***

Example: 80 58 00 00 00 00 00 00



**DOKUMENTACJA:**

* Temperatura plynu chłodniczego w C

/ Byte 1 - TEMP\_ENG

&nbsp;	Calculation =

&nbsp;	(HEX \* 0.75) - 48°C



* Tempomat (przycisk)

/ Byte 3 Bit 5,6,7 - STATE\_MSW\_CAN\[2]

&nbsp;	4 = Deactivate (I/O)



* Pozycja pedału gazu

/ Byte 5 - TPS\_CAN

&nbsp;	Calculation =

&nbsp;	HEX \* 0.390625





### ***0x545***

Example: 12 00 00 00 00 00 00 00



**DOKUMENTACJA:**

* Check Engine kontrolka

/ Byte 0 Bit 1 - LV\_MIL



* Zuzycie paliwa

/ Byte 2 - FCO\[MSB]



* Temperatura oleju w C

/ Byte 4 - TOIL\_CAN

&nbsp;	Calculation = HEX - 48°C

&nbsp;	Min: 0x00 => -48C

&nbsp;	Max: 0xFE => 206C



* Slabe ciśnienie oleju kontrolka

/ Byte 7 Bit 7



### ***0x565***

Example: 50 20 66 02 00 02 00 63



**GEMINI:**

* Cisnienie oleju

/ Byte 1

&nbsp;	20 => 3.2 Bar



* Temperatura oleju

/ Byte 2

&nbsp;	0x66 => 102 C



* Temperatura plynu chlodzacego

/ Byte 7

&nbsp;	0x63 => 99

