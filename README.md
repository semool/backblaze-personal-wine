# backblaze-personal-wine

## Infos
Looking for a (relatively) easy way to backup your personal linux system via Backblaze Personal unlimited? 
Then look no further, this container automatically creates a tiny Wine prefix that runs the Backblaze personal client to backup any mounted directory in your linux filesystem.
Please note, Linux specific file attributes (like ownership, acls or permissions) will not be backed up.

* The original x86 Image comes from [tom300z](https://github.com/tom300z/backblaze-personal-wine)
* Multi Dockerfile for x86 and x64
* (x86) Alpine version 3.13.12, Wine 4.0.3, Image Size only ~348MB!
* (x64) Debian 10 Buster, Wine 4.0.2, Image Size only ~700MB!
* Adding user configurable LANGUAGE and TIMEZONE. Defaults are 'en_US.UTF-8' and 'Etc/UTC'
* Disable openbox right click root menu (not needed)
* Install a dark [Theme (Afterpiece)](https://github.com/terroo/openbox-themes/tree/main/Afterpiece) for Openbox
* Adding Font [segoe-ui-linux](https://github.com/mrbvrz/segoe-ui-linux) for the Gui instead of ttf-dejavu
* Adding [noVNC](https://github.com/novnc/noVNC) Webinterface
* Adding Backblaze noVNC Icons
* Adding ENV to initiate a Client Redownload/Update
* Changing Wine DPI and activate Font Smoothing
* (x86) Disable Wine Debugger
* (x86) Workaround for fontconfig cache file spam in /var/cache/fontconfig

### The x64 Image
It runs fine. But i prefer the x86 one. Its smaller. The only x64 Binaries from the Client are the list and transfer ones. I haven't noticed any benefits from the x64.

## Container Build Instructions
<details>
  <summary>Click to expand!</summary>

### To build the x86 Version:
```
docker build -t backblaze-personal-wine:x86 .
```
### To build the x64 Version:
```
docker build -t backblaze-personal-wine:x64 --build-arg BASEIMAGE="amd64/debian:buster-slim" .
```
</details><br/>
  
## Docker run example
<details>
  <summary>Click to expand!</summary>

### Simple
```
docker run -d \
    --init \
    -v backblaze_data:/wine \ #<- This can be a Docker Volume
    -v /mnt/backblaze-temp:/data \ #<- This must be a Folder that is big enough to save the bigest file from your Backup (look at 'Data Dir Tips')
    -v /mnt/backupfolder1:/data/backupfolder1 \ #<- A Folder that should be Backuped
    -v /mnt/backupfolder2:/data/backupfolder2 \ #<- A Folder that should be Backuped
    --name=backblaze \
    --restart=always \
    backblaze-personal-wine:x86 # <- or x64
```

### Advanced
```
docker run -d \
    -h Backblaze-PB \ # <- The Hostname
    --init \
    -p 5900:5900 \ # <- The VNC Port
    -p 6080:6080 \ # <- The noVNC Webif Port
    -e LANGUAGE=de_DE.UTF-8 \
    -e TZ=Europe/Berlin \
    -e COMPUTERNAME=pcname \ # <- Wine Computername
    -e VNCPASSWORD=password \
    -e CLIENTUPDATE=0 \ # <- Set this to 1 (2 for Beta Version) for Client Update/Reinstall
    -v backblaze_data:/wine \ #<- This can be a Docker Volume
    -v /mnt/backblaze-temp:/data \ #<- This must be a Folder that is big enough to save the bigest file from your Backup (look at 'Data Dir Tips')
    -v /mnt/backupfolder1:/data/backupfolder1 \ #<- A Folder that should be Backuped
    -v /mnt/backupfolder2:/data/backupfolder2 \ #<- A Folder that should be Backuped
    --name=backblaze \
    --restart=always \
    backblaze-personal-wine:x86 # <- or x64
```
</details><br/>

## VNC Server and Security
<details>
  <summary>Click to expand!</summary>

### VNC Password
You can set a password to secure the VNC Server by add ```-e VNCPASSWORD=yourpwd``` to the docker run command.

### Connecting to the VNC Server
To go through the setup process you must connect to the integrated vnc server. You can use a VNC Client (Port 5900) like [TigerVNC Viewer](https://github.com/TigerVNC/tigervnc) or you can use the integrated noVNC Webinterface (Port 6080).

### Security
The server runs an unencrypted integrated VNC server.
Make sure you dont accept Connections from outside your local Network.

### https
When you need access over the Internet you can use [NGINX Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager) to setup https for the noVNC Webinterface.
Optional you can disable the VNC Port expose when you comment the ```EXPOSE 5900``` in the Dockerfile before you build your Image to only allow Connections to the noVNC Webinterface.
</details><br/>

## Setup guide
<details>
  <summary>Click to expand!</summary>

### Step 1: DATA Dir Tips
Mount a very Big empty Folder directly to '/data' first. It must have free Space for the bigest File you will Backup.
The Client uploads big files in Chunks (10MB) and they are temporarily saved here.
Also a directory '.bzvol' will create here. The Files inside are unique and needed for the client to redetect this as D: Drive.
Now you can mount all your Folders for Backup inside. you can remove or add Folders at any time (Look in the 'Docker run Example').

### Step 2: Installation
When starting the container for the first time, it will automatically initialize a new Wine prefix and download & run the backblaze installer.

When you only see a black screen once you are connected press alt-tab to activate the installer window.

Eventually the installer might look a bit weird (all white) at the very beginning. Just enter your backblaze account email into the white box and hit enter, then you should see the rest of the ui.
Or you can move the Window around a little bit, that fixed the view.

Then enter your password and hit "Install", the installer will start scanning your drive.

* For x86 Image: After Backblaze Client Installation ALL x64 Binaries are get renamed while this is a i386 only Container. Without renaming them the Client try continusly starting them and wine will go in Debug Mode = High CPU Load! When a Message Pops up with Client is not installed correctly ignore it and click in the main Client Window to hide the Warning in the background. Client will run fine!
* For X64 Image: When you become a Popup at Client Start 'ERR_NotificationDialog_bad_bzdata_permissions', ignore it and place it behind the Main Client Window. Eventually this is a Message that says you to enable Windows Location Services.

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

### Step 4: Client Update
To reinstall/update the Client start the Container with ```-e CLIENTUPDATE=1```
With ```-e CLIENTUPDATE=2``` the latest Beta Version will be downloaded.
The old Installer will be renamed and then the actual one will be downloaded.
After this the Installation will start. Go to the VNC Server to complete. The Client will start automaticaly after this.
When you restart the complete Container set 'CLIENTUPDATE' back to 0.
</details><br/>
  
## Useful Docker commands
<details>
  <summary>Click to expand!</summary>

### You can open a Explorer Window in your VNC Session to check the mounts:
```
docker exec backblaze wine explorer &
```
### Getting access to the Wine Config Window:
```
docker exec backblaze wine winecfg &
```
</details><br/>
