#!/bin/bash

echo $TZ > /etc/timezone
echo "Setting Timezone to: $TZ"
date
echo "---------------------------------------------------"

echo "Setting Language to: $LANG"
localedef -i `echo $LANG | cut -d "." -f1` -c -f UTF-8 -A /usr/share/locale/locale.alias $LANG
export LANG=$LANG
export LANGUAGE=$LANG
echo "---------------------------------------------------"

echo "Setting Path Variables for Backblaze"
BZPATHUI="$WINEPREFIX/drive_c/Program Files (x86)/Backblaze/bzbui.exe"
RUNTRAY="C:\Program Files (x86)\Backblaze\bzbuitray.exe"
RUNUI="C:\Program Files (x86)\Backblaze\bzbui.exe"
echo "---------------------------------------------------"

if [ "$VNCPASSWORD" != "none" ]; then
   if [ ! -e "$WINEPREFIX/.vncpassword" ]; then
      echo "Setting the VNC Server Password: $WINEPREFIX/.vncpassword"
      x11vnc -storepasswd $VNCPASSWORD $WINEPREFIX/.vncpassword &>/dev/null
   else
      echo "VNC Server Password File exist"
   fi
   VNCAUTH="-rfbauth $WINEPREFIX/.vncpassword"
   echo "---------------------------------------------------"
else
   if [ -e "$WINEPREFIX/.vncpassword" ]; then rm $WINEPREFIX/.vncpassword; fi
   VNCAUTH="-nopw"
fi

echo "Starting the VNC Server on Port: 5900"
LOCALONLY=""
if [ "$NOVNCSSL" != "0" ]; then
   echo "SSL is active, dont accept direct connections"
   LOCALONLY="-localhost"
fi
rm -f /tmp/.X0-lock
Xvfb $DISPLAY -screen 0 "$DISPLAYSIZE"x24 & openbox & x11vnc $LOCALONLY $VNCAUTH -q -forever -loop -shared &>/dev/null &
echo "---------------------------------------------------"

if [ "$NOVNCSSL" != "0" ]; then
   echo "Starting the noVNC Webinterface (SSL) on Port: 6080"
   echo "Goto: https://$HOSTNAME:6080"
   if [ ! -e "$WINEPREFIX/.novnc.pem" ]; then
      echo "Create noVNC self sign certificate: $WINEPREFIX/.novnc.pem"
      openssl req -x509 -nodes -newkey rsa:2048 -keyout $WINEPREFIX/.novnc.pem -out $WINEPREFIX/.novnc.pem -days 365 \
      -subj "/C=/ST=/L=/O=Backblaze Docker noVNC/OU=Backblaze Docker noVNC/CN=Backblaze Docker noVNC" &>/dev/null
   fi
   NOVNCCERT="--cert $WINEPREFIX/.novnc.pem --ssl-only --vnc :5900"
else
   echo "Starting the noVNC Webinterface on Port: 6080"
   echo "Goto: http://$HOSTNAME:6080"
   if [ -e "$WINEPREFIX/.novnc.pem" ]; then rm $WINEPREFIX/.novnc.pem; fi
   NOVNCCERT="--vnc :5900"
fi
/opt/noVNC/utils/novnc_proxy $NOVNCCERT &>/dev/null &
echo "---------------------------------------------------"

function configure_wine {
  echo "Configure Wine..."

  if [ -e $WINEPREFIX/dosdevices/z: ]; then
     echo "- Unlink $WINEPREFIX/dosdevices/z:"
     unlink $WINEPREFIX/dosdevices/z:
  fi

  if [ "$MOUNTEXPERT" == "0" ]; then
     if [ ! -e $WINEPREFIX/dosdevices/d: ]; then
        echo "- Link /data/ -> $WINEPREFIX/dosdevices/d:"
        ln -s /data/ $WINEPREFIX/dosdevices/d:
     fi
  else
     for n in /data/*; do
        b="$(basename "$n")"
        d="${b//__*/}"
        if ! [[ $d =~ ^[d-y]$ ]]; then
           echo "- Invalid Directory Name: $d"
           echo "  Should be: <letter d-y>__$d"
           continue
        fi

        if [ -L "$WINEPREFIX/dosdevices/$d:" ]; then
           checkl="$(readlink $WINEPREFIX/dosdevices/$d:)"
           if [ "$checkl" == "$n" ]; then
              echo "- Link already exist: $n -> $d:"
              continue
           else
              echo "- Unlink old $checkl -> $d:"
              unlink $WINEPREFIX/dosdevices/$d:
           fi
        fi

        echo "- Link $n -> $d:"
        ln -s $n $WINEPREFIX/dosdevices/$d:
     done
  fi

  echo "Setting Wine Registry Entries:"
  if [ ${#COMPUTER_NAME} -gt 15 ]; then
    echo "Error: computer name cannot be longer than 15 characters!"
    echo "Execution stopped!"
    exit 1
  fi
  echo "- Setting Computer Name: $COMPUTERNAME"
  wine reg add "HKCU\\SOFTWARE\\Wine\\Network\\" /v UseDnsComputerName /f /d N &>/dev/null
  wine reg add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\ComputerName\\ComputerName" /v ComputerName /f /d $COMPUTERNAME &>/dev/null
  wine reg add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\ComputerName\\ActiveComputerName" /v ComputerName /f /d $COMPUTERNAME &>/dev/null
  echo "- Setting Font DPI"
  wine reg add "HKLM\\SYSTEM\\CurrentControlSet\\Hardware Profiles\\Current\\Software\\Fonts\\" /v LogPixels /t REG_DWORD /f /d 125 &>/dev/null
  echo "- Setting Font Smoothing"
  wine reg add "HKCU\\Control Panel\\Desktop\\" /v FontSmoothing /f /d 2 &>/dev/null
  wine reg add "HKCU\\Control Panel\\Desktop\\" /v FontSmoothingGamma /t REG_DWORD /f /d 578 &>/dev/null
  wine reg add "HKCU\\Control Panel\\Desktop\\" /v FontSmoothingOrientation /t REG_DWORD /f /d 1 &>/dev/null
  wine reg add "HKCU\\Control Panel\\Desktop\\" /v FontSmoothingType /t REG_DWORD /f /d 2 &>/dev/null
  echo "---------------------------------------------------"
}

function install_backblaze {
  echo "Backblaze Installer started, please go through the graphical Setup by logging onto the Containers (no)VNC server"
  wine $WINEPREFIX/drive_c/install_backblaze.exe
  echo "---------------------------------------------------"
  echo "Installation finished or aborted! Lets check..."
  echo "Trying to start the Backblaze Client..."
  wineserver -k
}

until [ -f "$BZPATHUI" ]; do
  echo "Backblaze not installed - Initializing the Wine prefix..."
  wineboot -i -u
  echo "---------------------------------------------------"
  configure_wine
  if [ ! -e $WINEPREFIX/drive_c/install_backblaze.exe ]; then
     echo "Downloading Backblaze Personal Final Installer..."
     wget -O $WINEPREFIX/drive_c/install_backblaze.exe https://www.backblaze.com/win32/install_backblaze.exe
     echo "---------------------------------------------------"
  fi
  install_backblaze
done

if [ "$CLIENTUPDATE" != "0" ]; then
  configure_wine
  if [ "$CLIENTUPDATE" == "1" ]; then echo "Client Update Mode ON!"; fi
  if [ "$CLIENTUPDATE" == "2" ]; then echo "Client Update Mode ON for BETA VERSION!"; fi
  if [ "$CLIENTUPDATE" == "3" ]; then echo "Client Reinstall Mode ON!"; fi
  DATE=$(date '+%Y-%m-%d-%H.%M')
  if [ -e $WINEPREFIX/drive_c/install_backblaze.exe -a "$CLIENTUPDATE" != "3" ]; then
    echo "Renaming old Installer to: $WINEPREFIX/drive_c/install_backblaze.exe_$DATE"
    mv -f $WINEPREFIX/drive_c/install_backblaze.exe $WINEPREFIX/drive_c/install_backblaze.exe_$DATE
  fi
  if [ "$CLIENTUPDATE" == "1" ]; then
    echo "Downloading Backblaze Personal Final Installer..."
    wget https://www.backblaze.com/win32/install_backblaze.exe -P $WINEPREFIX/drive_c/
  elif [ "$CLIENTUPDATE" == "2" ]; then
    echo "Downloading the Backblaze Personal BETA Installer..."
    wget https://f000.backblazeb2.com/file/backblazefiles/install_backblaze.exe -P $WINEPREFIX/drive_c/
  fi
  CLIENTUPDATE=0
  echo "---------------------------------------------------"
  install_backblaze
fi

if [ -f "$BZPATHUI" ]; then
  configure_wine
  echo "Backblaze found..."
  echo "- Starting the Backblaze Tray Symbol"
  wine "$RUNTRAY" &
  echo "--------------------------------------------------"
  echo "- Go into the Container Shell with:"
  echo "  docker exec -it backblaze bash"
  echo "  And then run the following command:"
  echo "  wine \"C:\Program Files (x86)\Backblaze\bzbui.exe\" -quiet &"
  echo "  Use the Tray Icon to open the Main Gui"
  sleep infinity
fi
