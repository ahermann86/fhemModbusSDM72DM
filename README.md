# fhemModbusSDM72DM
#### FHEM Module zur Anbindung eines SDM72DM Modbus 3~ Energiemessgerät

<img src="https://user-images.githubusercontent.com/48262831/111083910-2a43f600-8510-11eb-9881-79e6771f47ec.jpg" alt="RS485 oben" width="400"/>

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

#### Aufzeichnung

![Tagesverbrauch](https://user-images.githubusercontent.com/48262831/112735986-a4806b80-8f4f-11eb-9b64-9ee7c6134786.png)

1. Energiemessung in ein Logfile:
- `define Log_Waermepumpe FileLog ./log/Waermepumpe-%Y-%m.log SDM72DM_Z1:Energy_total__kWh:.*|SDM72DM_Z1:Power_Sum__W:.*`
- `attr Log_Waermepumpe room Logs`
2. Ein Plot erzeugen:
- `define SVG_Log_Waermepumpe SVG Log_Waermepumpe:SVG_Log_Waermepumpe:CURRENT`
- `attr SVG_Log_Waermepumpe label sprintf("Wärmepumpe Akt.: %.3f kW Tagesverbrauch %.2f kWh", $data{currval1}/1000, $data{currval2})`
- `attr SVG_Log_Waermepumpe room Plots`
- *oder mit Create SVG plot im Logfile Modul*
- Die SVG_Log_Waermepumpe.gplot (kann in dem SVG Modul über das INTERNAL GPLOTFILE als Textblock editiert werden):
```
# Created by FHEM/98_SVG.pm, 2021-02-11 08:48:12
set terminal png transparent size <SIZE> crop
set output '<OUT>.png'
set xdata time
set timefmt "%Y-%m-%d_%H:%M:%S"
set xlabel " "
set title '<L1>'
set ytics 
set y2tics 
set grid
set ylabel "Leistung [W]"
set y2label ""
set yrange [0:4500]
set y2range [0:50]

#Log_Waermepumpe 4:SDM72DM_Z1.Power_Sum__W\x3a::
#Log_Waermepumpe 4:SDM72DM_Z1.Energy_total__kWh\x3a::delta-d

plot "<IN>" using 1:2 axes x1y1 title 'Power [W]' ls l4 lw 1 with steps,\
     "<IN>" using 1:2 axes x1y2 title 'Verbrauch [kWh]' ls l0 lw 1 with bars
```



#### Erfassung des stündlich, täglich und monatlichen Verbrauchs

Das kann am einfachsten mit dem statistics Modul gemacht werden.
Nachfolgend ein Beispiel, mit dem die Statistikwerte in dem definierten Modul "SDM72DM_Z1" als Readings ergänzt werden:

1. Statistics Modul definieren (https://wiki.fhem.de/wiki/Statistics):
- `define myStatistics statistics SDM72DM_Z1 Stat.`
- `attr myStatistics alias myStatistics`
- `attr myStatistics dayChangeTime 00:00:00`
- `attr myStatistics deltaReadings Energy_total__kWh`
- `attr myStatistics room Logs`
- `attr myStatistics singularReadings SDM72DM_Z1:Energy_total__kWh:(Day|Month|Year)`
2. Statistikdaten in ein Logfile:
- `define Log_SDM72 FileLog ./log/SDM72-%Y-%m.log SDM72DM_Z1:Stat.Energy_total__kWh:.*`
- `Log_SDM72 alias Log_SDM72`
- `Log_SDM72 room Logs`
3. Ein Plot erzeugen:
- `define SVG_Log_SDM72_1 SVG Log_SDM72:SVG_Log_SDM72_1:CURRENT`
- `attr SVG_Log_SDM72_1 room Plots`
- *oder mit Create SVG plot im Logfile Modul*
- Die SVG_Log_SDM72_1.gplot (kann in dem SVG Modul über das INTERNAL GPLOTFILE als Textblock editiert werden):
```
# Created by FHEM/98_SVG.pm, 2021-03-27 22:00:10
set terminal png transparent size <SIZE> crop
set output '<OUT>.png'
set xdata time
set timefmt "%Y-%m-%d_%H:%M:%S"
set xlabel " "
set title '<TL>'
set ytics 
set y2tics 
set grid
set ylabel "Verbrauch"
set y2label ""
set yrange [0:20]

#Log_SDM72 5:SDM72DM_Z1.Stat.Energy_total__kWh\x3a::
#Log_SDM72 7:SDM72DM_Z1.Stat.Energy_total__kWh\x3a::

plot "<IN>" using 1:2 axes x1y1 title 'Stunde' ls l0 lw 1 with steps,\
     "<IN>" using 1:2 axes x1y1 title 'Tag' ls l1 lw 1 with steps
```

![Statistics_SVG](https://user-images.githubusercontent.com/48262831/112735964-89adf700-8f4f-11eb-938f-bf38b9d2bec7.png)


