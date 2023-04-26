![Last Commit](https://img.shields.io/github/last-commit/semool/backblaze-personal-wine?style=flat-square)
![x86 Image Size (compressed)](https://img.shields.io/docker/image-size/loomes/backblaze-personal-wine/x86.alpine?color=magenta&label=x86%20Image%20%28compressed%29&style=flat-square)
![x64 Image Size (compressed)](https://img.shields.io/docker/image-size/loomes/backblaze-personal-wine/x64.debian?color=magenta&label=x64%20Image%20%28compressed%29&style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/loomes/backblaze-personal-wine?style=flat-square)

## Infos
Looking for a (relatively) easy way to backup your personal linux system via Backblaze Personal unlimited? 
Then look no further, this container automatically creates a tiny Wine prefix that runs the Backblaze personal client to backup any mounted directory in your linux filesystem.
Please note, Linux specific file attributes (like ownership, acls or permissions) will not be backed up.

* The original x86 Image comes from [tom300z](https://github.com/tom300z/backblaze-personal-wine)
* Multi Dockerfile for x86 and x64
* (x86) Alpine version 3.13.12, Wine 4.0.3, Image Size only ~348MB!
* (x64) Debian 10 Buster, Wine 4.0.4, Image Size ~956MB!
* Adding user configurable LANGUAGE and TIMEZONE. Defaults are 'en_US.UTF-8' and 'Etc/UTC'
* Disable openbox right click root menu (not needed)
* Install a dark [Theme (Afterpiece)](https://github.com/terroo/openbox-themes/tree/main/Afterpiece) for Openbox
* Adding Font [segoe-ui-linux](https://github.com/mrbvrz/segoe-ui-linux) for the Gui instead of ttf-dejavu
* Adding [noVNC](https://github.com/novnc/noVNC) Webinterface with optional https Support
* Adding Backblaze noVNC Favicon
* Making the virtual Display Size configurable (Default: 910x740)
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
docker build -t backblaze-personal-wine:x86.alpine .
```
### To build the x64 Version:
```
docker build -t backblaze-personal-wine:x64.debian --build-arg BASEIMAGE="amd64/debian:buster-slim" .
```
</details><br/>
  
## Docker run example
<details>
  <summary>Click to expand!</summary>

### Simple
```
docker run -d \
    --init \
    -e USER_ID=0 \
    -e GROUP_ID=0 \
    -v backblaze_data:/wine \ #<- This can be a Docker Volume
    -v /mnt/backblaze-temp:/data \ #<- This must be a Folder that is big enough to save the bigest file from your Backup (look at 'Data Dir Tips')
    -v /mnt/backupfolder1:/data/backupfolder1 \ #<- A Folder that should be Backuped
    -v /mnt/backupfolder2:/data/backupfolder2 \ #<- A Folder that should be Backuped
    --name=backblaze \
    --restart=always \
    backblaze-personal-wine:x86.alpine # <- or x64.debian
```

### Advanced
```
docker run -d \
    -h Backblaze-PB \ # <- The Hostname
    --init \
    -p 5900:5900 \ # <- The VNC Port
    -p 6080:6080 \ # <- The noVNC Webif Port
    -e USER_ID=0 \
    -e GROUP_ID=0 \
    -e TZ=Europe/Berlin \
    -e LANG=de_DE.UTF-8 \
    -e COMPUTERNAME=pcname \ # <- Wine Computername
    -e VNCPASSWORD=password \
    -e NOVNCSSL=1 \ # <- Look in the VNC Server Security Section
    -e MOUNTEXPERT=1 \ # Every single dir/mount under Data will be a seperate Backup drive (look at 'Data Dir Tips')
    -e DISPLAYSIZE=910x740 \ # <- The virtual Display Size
    -e CLIENTUPDATE=0 \ # <- Set this to 1 (2 for Beta Version) for Client Update/Reinstall
    -v backblaze_data:/wine \ #<- This can be a Docker Volume
    -v /mnt/backupfolder1:/data/d__backupfolder1 \ #<- A Folder that should be Backuped, first Part is the Drive Letter to mount
    -v /mnt/backupfolder2:/data/e__backupfolder2 \ #<- A Folder that should be Backuped, first Part is the Drive Letter to mount
    --name=backblaze \
    --restart=always \
    backblaze-personal-wine:x86.alpine # <- or x64.debian
```
</details><br/>

## VNC Server and Security
<details>
  <summary>Click to expand!</summary>

### Connecting to the VNC Server
To go through the setup process you must connect to the integrated vnc server. 
* You can use a VNC Client (Port 5900) like [TigerVNC Viewer](https://github.com/TigerVNC/tigervnc)
* or you can use the integrated noVNC Webinterface (Port 6080).

### VNC Password
You can set a password to secure the VNC Server by add ```-e VNCPASSWORD=yourpwd``` to the docker run command.
The Password will be saved to ```/wine/.vncpassword```.
For extra Security you can now change ```-e VNCPASSWORD=yourpwd``` to ```-e VNCPASSWORD=anything ,but not to 'none'```.
The encryptet ```/wine/.vncpassword``` will continue to be used.
When you set the Password back to 'none' the saved file will be deletet.
In the same way you can change the Password, set to 'none', start/stop the Container and set a new Password.

### Security
The server runs an unencrypted integrated VNC server.
Make sure you dont accept Connections from outside your local Network.

### Simple https
You can set ```-e NOVNCSSL=1``` to the docker run command.
Then the Container will create a Keyfile for https: ```/wine/.novnc.pem```.
Optional you can replace it with your own compatible Keyfile.
When ```-e NOVNCSSL=1``` is set you can only access the noVNC Webinterface with https.
The normal VNC Server will not acceppt connections on Port 5900 now.

### https
When you need access over the Internet with legit Certificates (Lets Encrypt) you can use [NGINX Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager) to setup https for the noVNC Webinterface.
Optional you can disable the VNC Port expose:
* comment the ```EXPOSE 5900``` in the Dockerfile before you build your Image to only allow Connections to the noVNC Webinterface.
* or you can modify the Port Mapping in your run command: ```-p 127.0.0.1:5900:5900```
</details><br/>

## Setup guide
<details>
  <summary>Click to expand!</summary>

### Step 1: DATA Dir Tips
* Normal Mode (Default):
Mount a very Big empty Folder directly to '/data' first. This is your Drive D: root and must be 'rw'. It must have free Space for the bigest File you will Backup.
The Client uploads big files in Chunks (10MB) and they are temporarily saved here.
Also a directory '.bzvol' will create here. The Files inside are unique and needed for the client to redetect this as D: Drive.
Now you can mount all your Folders for Backup inside. They can be 'ro'. You can remove or add Folders at any time (Look in the 'Docker run Example').

* Expert Mode:
When you set ```-e MOUNTEXPERT=1``` every single mount in /data becomes a own Driveletter (Look in the 'Docker run Advanced Example').
The '.bzvol' will create in every single mounted dir. So they must be 'rw'.

### Step 2: Installation
When starting the container for the first time, it will automatically initialize a new Wine prefix and download & run the backblaze installer.

When you only see a black screen once you are connected press alt-tab to activate the installer window.

Eventually the installer might look a bit weird (all white) at the very beginning. Just enter your backblaze account email into the white box and hit enter, then you should see the rest of the ui.
Or you can move the Window around a little bit, that fixed the view.

Then enter your password and hit "Install", the installer will start scanning your drive.

* For x86 Image: After Backblaze Client Installation ALL x64 Binaries are get renamed while this is a i386 only Container. Without renaming them the Client try continusly starting them and wine will go in Debug Mode = High CPU Load! When a Message Pops up with Client is not installed correctly ignore it and click in the main Client Window to hide the Warning in the background. Client will run fine!
* For X64 Image: When you become a Popup at Client Start 'ERR_NotificationDialog_bad_bzdata_permissions', ignore it and place it behind the Main Client Window. In newer Versions this String is translated and say you must check Permissions for the bzdata dir. This can be also ignored.

### Step 3: Troubleshooting:
Sometimes the Main Gui will start with ? instead of Text and crash after some seconds. The File Transfer in the background works great. When this happens reopen the Main Gui by Clicking on the Icon in the Tray Application. After 2-3 Attemps the Gui starts fine and will running.
When the Gui will crash more than one time open a Shell on the Docker Image and run `wine "C:\Program Files\Backblaze\bzbui.exe" &`. Or do it with docker exec (Look in 'Useful Docker commands'). Now the Gui will run forever. I dont know why.

### Step 4: Configuration
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

### Step 5: Client Update
To reinstall/update the Client start the Container with ```-e CLIENTUPDATE=1```
With ```-e CLIENTUPDATE=2``` the latest Beta Version will be downloaded.
The old Installer will be renamed and then the actual one will be downloaded.
After this the Installation will start. Go to the VNC Server to complete. The Client will start automaticaly after this.
When you restart the complete Container set 'CLIENTUPDATE' back to 0.
</details><br/>
  
## Useful Docker commands
<details>
  <summary>Click to expand!</summary>

### Starting the Backblaze Gui after Crash:
```
docker exec -d backblaze wine "C:\Program Files\Backblaze\bzbui.exe"
```
### Get the Container Logfile:
```
docker logs -f backblaze
```
### Open a bash Shell for the Container:
```
docker exec -it backblaze bash
```
### You can open a Explorer Window in your VNC Session to check the mounts:
```
docker exec backblaze wine explorer &
```
### Getting access to the Registry:
```
docker exec backblaze wine registry &
```
### Getting access to the Wine Console (cmd like):
```
docker exec backblaze wine wineconsole &
## Checking if the Dir is detected as link or mount (then it will not Backuped)
"C:\Program Files\Backblaze\bzfilelist.exe" -fileinfo D:\MyBackupDir
```
### Getting access to the Wine Config Window:
```
docker exec backblaze wine winecfg &
```
</details><br/>
