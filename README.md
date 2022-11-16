# backblaze-personal-wine-x86

Looking for a (relatively) easy way to backup your personal linux system via Backblaze Personal unlimited? 
Then look no further, this container automatically creates a tiny Wine prefix that runs the Backblaze personal client to backup any mounted directory in your linux filesystem.
Please note, Linux specific file attributes (like ownership, acls or permissions) will not be backed up;

Modifications by semool:
* The Complete Image will have only ~368MB!
* Set the right Alpine version (3.12)
* Fix the Wine Install (4.0.3)
* Add Language Support
* Adding user configurable LANGUAGE and TIMEZONE. Defaults are 'en_US.UTF-8' and 'Etc/UTC'
* Add required Fonts for Openbox Font Issue
* Disable openbox right click menu (not required)
* Workaround for fontconfig cache file spam in /var/cache/fontconfig
* After Backblaze Client Installation renaming ALL x64 Binaries while this is a i386 only Container. Without renaming them the Client try continusly starting them and wine will go in Debug Mode = High CPU Load! When a Message Pops up with Client is not installed correctly ignore it and click in the main Client Window to hide the Warning in the background. Client will run fine!
* Adding noVNC Webinterface

## Docker run example
<details>
  <summary>Click to expand!</summary>

```
docker run -d \
    -h Backblaze-PB \
    --init \
    -p 5900:5900 \
    -p 6080:6080 \
    -e LANGUAGE=de_DE.UTF-8 \
    -e TZ=Europe/Berlin \
    -v backblaze_data:/wine \ #<- This can be a Docker Volume
    -v /mnt/backblaze-temp:/data \ #<- This must be a Folder that is big enough to save the bigest file from your Backup (look at 'Data Dir Tips')
    -v /mnt/backupfolder1:/data/backupfolder1 \ #<- A Folder that should be Backuped
    -v /mnt/backupfolder2:/data/backupfolder2 \ #<- A Folder that should be Backuped
    --name=backblaze \
    --restart=always \
    backblaze-personal-wine:x86
```

### Connecting to the VNC Server
To go through the setup process you must connect to the integrated vnc server via a client like RealVNC Client.
address: yourip:5900
user: none (admin)
password: none

### Connecting to the VNC Server (Webinterface)
You can open the noVNC client in your browser (make sure your firewall allows acess to the port):
address: http://yourip:6080

### Security
The server runs an unencrypted integrated VNC server. 
If you need to connect to the vnc server from a different machine (on headless systems), please make sure to configure your firewall to only allow local connections to the VNC.
firewalld example:
```
firewall-cmd --permanent --add-rich-rule "rule family="ipv4" source address="192.168.178.0/24" port port="5900" protocol="tcp" accept"
firewall-cmd --permanent --add-rich-rule "rule family="ipv4" source address="192.168.178.0/24" port port="6080" protocol="tcp" accept"
firewall-cmd --reload
```
</details><br/>

## Setup guide

### Step 1: DATA Dir Tips
Mount a very Big empty Folder directly to '/data' first. It must have free Space for the bigest File you will Backup.
The Client uploads big files in Chunks (10MB) and they are temporarily saved here.
Also a directory '.bzvol' will create here. The Files inside are unique and needed for the client to redetect this as D: Drive.
Now you can mount all your Folders for Backup inside. you can remove or add Folders at any time (Look in the 'Docker run Example').

### Step 2: Installation
When starting the container for the first time, it will automatically initialize a new Wine prefix and download & run the backblaze installer.

When you only see a black screen once you are connected press alt-tab to activate the installer window.
The installer might look a bit weird (all white) at the very beginning. Just enter your backblaze account email into the white box and hit enter, then you should see the rest of the ui.
Or you can move the Window up/down a little bit, that fixed the view.
Enter your password and hit "Install", the installer will start scanning your drive.

### Step 3: Configuration
Once the Installer is finished the backblaze client should open automatically.

You will notice that currently only around 10 files are backed up. 
To change that click the Settings button and check the box for the "D:" drive, this drive corresponds to the /data/ directory of your container. 
You can also set a better name for your backup here.
I'd also reccommend to remove the blacklisted file extensions from the "Exclusions" tab.

Once you hit "Ok" or "Apply" the client will start scanning your drives again, this might take a very long time depending on the number of files you mounted under the /data/ dir, just be patient and leave the container running.
You can dis- and reconnect from and to the VNC server at any time, this will not affect the Backblaze client.

When the analysis is complete make shoure the client performs the initial backup (this should happen automatically).
Depending on the number and size of the files you want to back up and your upload speed, this will take quite some time.
If you have to stop the container during the initial backup the backup will continue where it left once the container is started again.

Backblaze is now configured to automatically backup your linux files,  to check the progress or change settings use the VNC Server.
