# Linux-Konsole mit AWS verbinden

1. AWS konfigurieren<br>
    Falls man dies bereits einmal gemacht hat ist dies nicht mehr notwendig.
    
       aws configure

    ![aws configure](./AWS%20Bilder/AWS-Configure.png)
    <ins>Zu eigenen Werten ändern:</ins><br>
    - AWS Access Key ID
    - AWS Secret Access Key
    - Default region name
<br>
<br>

2. Session-Token hinzufügen<br>

    2.1. In den .aws Ordner wechseln (Pfad muss eventuell angepasst werden)<br>
    
           cd .aws
    ![to aws folder](./AWS%20Bilder/To-AWS-Folder.png)
    <br><br>


    2.2. Session-Token in credentials Datei hinzufügen<br>

           nano credentials

    ![open credentials](./AWS%20Bilder/AWS-Open-Credentials.png)

    <ins>Vorher:</ins>
    ![](./AWS%20Bilder/AWS-Credentials-Before.png)

    <ins>Nachher:</ins>
    ![](./AWS%20Bilder/AWS-Credentials-After.png)

    **Speichern!**





