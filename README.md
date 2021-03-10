# fhemModbusSDM72DM
FHEM Module zur Anbindung eines SDM72DM Modbus 3~ Energiemessgerät

<img src="https://user-images.githubusercontent.com/48262831/110222695-66ee6c80-7ed4-11eb-983f-f0cfcc7891d7.jpg" alt="RS485 oben" width="400"/>

Das Modul ist eine Abwandlung von Roger's "98_ModbusSDM630M.pm" -> https://forum.fhem.de/index.php/topic,25315.msg274011.html#msg274011

*daher ist vielleicht der ein oder andere Kommentar im Quelltext nicht ganz passend*

HowTo Beispiel:

1. Datei in FHEM hinein kopieren und laden. Wie z.B. https://wiki.fhem.de/wiki/Rotex_HPSU_Compact#Dateien
2. In FHEM Modbus Schnittstelle definieren. 
- `define Modbus_Z1 Modbus /dev/serial/by-path/pci-0000:00:12.0-usb-0:1:1.0-port0@9600`
3. In FHEM Modbus Zähler Device mit dem Modul definieren:
- `define SDM72DM_Z1 ModbusSDM72DM 1 10`
- `attr SDM72DM_Z1 IODev Modbus_Z1`
- `attr SDM72DM_Z1 event-on-change-reading Energy_total__kWh.*:0.5,Power_Sum__W:5,.*`

Hardware Beispiele:

<img src="https://user-images.githubusercontent.com/48262831/110222604-b6806880-7ed3-11eb-9222-cb7f73c09996.jpg" alt="RS485 oben" width="300"/>

<img src="https://user-images.githubusercontent.com/48262831/110222514-0874be80-7ed3-11eb-9424-000616daa5ba.jpg" alt="RS485 unten" width="300"/>

*Ich selbst habe den isolierten USB -> RS485 Adapter im Einsatz*
