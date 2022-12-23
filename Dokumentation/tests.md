# Tests

## Fehler
### <ins>Keine Internetverbindung</ins>
Wenn keine Internetverbindung hergestellt werden kann wird dies so ausgegeben
   ![](../AWS%20Bilder/No-Internet-Connection.png)

### <ins>Keine verbindung zu AWS</ins>
Dies passiert wenn es ein Fehler im credentials hat und/oder der Session-Token nicht mehr aktuell ist.<br>
[Credentials aktualisieren](./connectToAWS.md)
![](../AWS%20Bilder/No-Connection-To-AWS.png)

### <ins>Das Skript läuft nicht mehr weiter</ins>
Normalerweise braucht das Skript ca. 50-60 Sekunden.<br>
Falls es länger dauert, kann dass mehrere Gründe haben:
- <ins>Man hat aus Versehen in die Konsole geklickt</ins><br>
Wenn man in die Konsole klickt, wird sie pausiert.<br>
Durch das drücken der Enter-Taste läuft es wieder weiter.
<br>

- <ins>Es braucht lange da es bereits viele Buckets mit diesen Name gibt</ins><br>
Da das Skript so lange nach Namen sucht bis alle gültig sind, kann es sein, dass es sehr lange dauert bis gültige Namen gefunden werden.<br>
In diesem Fall empfehle ich das Skript abzubrechen und die Namen der Buckets und der Funktion zu ändern.<br>
Mehr dazu [hier](./readme.md) unter "Namen anpassen"
<br>

- <ins>Session wurde beendet/Session-Token ist nicht mehr aktuell</ins><br>
Wenn es 3min+ dauert köntte es daran liegen.<br>
Mehr dazu [hier](./connectToAWS.md) unter "Session-Token hinzufügen"
<br>

- <ins>Schlechte Internetverbindung</ins><br>
Manchmal liegt es auch ganz Simpel an einer schlechten Internetverbindung.<br>
In diesem Fall nach Möglichkeit mit einem besseren besseren Netzt verbinden und nochmals versuchen.
<br>

- <ins>Keines der oben genannten trifft zu</ins><br>
In diesem Fall hat bei mir nur ein Neustart des Computer geholfen. Dannach brauchte es wieder nur 50 Sekunden.



## <ins>Erfolg</ins>
Wenn das Skript erfolgreich druchläuft wird am Ende das Beispielbild hochgeladen und dann verkleinert wieder heruntergeladen.
![AWS Success](../AWS%20Bilder/AWS-Success.png)

![AWS Success Files](../AWS%20Bilder/AWS-Success-Files.png)