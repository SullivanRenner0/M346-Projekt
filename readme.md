# M346-Projekt

## Übersicht
Das ist das Hauptrepository von Sullivan Renner und Lenny Gianfranceschi für das Projekt im Modul 346. Es besteht aus den folgenden Hauptordnern:

  - Code (Enthält alle Dateien die für das Erstellen der Buckets nötig sind)
  - Testbild (Enthält ein Testbild welches am Ende jedes Erstellen hoch und wieder heruntergeladen wird)

## Erste Schritte
1. Als erstes muss man AWS auf seiner Konsole installieren. Dazu eine Anleitung [hier](https://docs.aws.amazon.com/de_de/cli/latest/userguide/getting-started-install.html)
2. Dann muss man sich in der Konsole mit AWS verbinden. Dazu eine Anleitung [hier](./connectToAWS.md).<br>
2. Dannach muss das Repository entweder mit git geklont oder als Zip herunterladen und entzippt werden.<br>
3. Zum Schluss nur noch [create.sh](./Code/create.sh) in der Konsole aufrufen.<br>
Denn Rest erledigt das Skript.

 

## Namen anpassen

Die Name aller AWS Komponenten können im [create.sh](./Code/create.sh) angepasst werden. Falls einer der 3 Namen nicht verfügbar ist (Buckets & Lamda Funktion), wird am Ende eine Zahl angefügt. Wenn dieser Name auch nicht verfügbar ist wird die Zahl um eins erhöht, bis alle Namen verfügbar sind.


### <ins>bucket1original</ins>
Der favorisierte Name des Buckets, in dem die Bilder in der orginalen Grösse hochgeladen werden sollen.

### <ins>bucket2original</ins>
Der favorisierte Name des Buckets, in dem die Bilder in er verkleinert gespeichert werden sollen.

### <ins>functionNameoriginal</ins>
Der favorisierte Name der Lambda Funktion.

### **Beispiel**
bucket1original = "Bucket-original"<br>
bucket2original = "Bucket-resized"<br>
functionNameoriginal = "copyImage"<br>

#### <ins>Ergebniss</ins><br>
Bucket-original = "Bucket-original-2"<br>
Bucket-verkleinert = "Bucket-resized-2"<br>
Bucket1 = "copyImage-2"

 

## Grösse der verkleinerten Bilder ändern
In der Datei [index.py](./Code/index.py) hat es eine Variable names size.<br>
Mit dieser kann die Grösse der verkleinerten Bilder angepasst werden.
<br>
<br>
<ins>**Wichtig:**</ins><br>
Das Seitenverhältniss des Orginalen Bildes bleibt bestehen.

 

## Testbild
Im Ordner [Testbild](./Testbild/) befindet sich die Datei [Testbild.png](./Testbild/Testbild.png).<br>
Diese wird am Ende jedes Erstellens als Test hoch und wieder heruntergeladen.
Diese kann frei geändert und/oder umbenannt werden.

 

## Tests
Alle Tests finde Sie [hier](./tests.md)

## **Wichtig**
Zu Beginn werden sie eventuell nach dem Passwort gefragt. Das liegt daran dass der Code die Packages zip und jq benötigt.