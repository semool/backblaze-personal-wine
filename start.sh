#!/bin/bash

GETARCH=`getconf LONG_BIT`
echo "Detected Arch: $GETARCH bit"
echo "************************************"

echo "Setting $GETARCH bit Path for Backblaze Client"
if [ "$GETARCH" == "32" ]; then
   BZPATH="$WINEPREFIX/drive_c/Program Files/Backblaze/bzbui.exe"
   BZPATHROOT="$WINEPREFIX/drive_c/Program Files/Backblaze"
fi
if [ "$GETARCH" == "64" ]; then
   BZPATH="$WINEPREFIX/drive_c/Program Files (x86)/Backblaze/bzbui.exe"
fi
echo "************************************"

if [ "$CLIENTUPDATE" != "0" -a -e "$WINEPREFIX/drive_c/" ]; then
   echo "Client Update Mode ON!"
   touch $WINEPREFIX/drive_c/.CLIENTUPDATE
   if [ "$CLIENTUPDATE" == "2" ]; then
      echo "Client Update Mode for BETA VERSION!!"
      touch $WINEPREFIX/drive_c/.CLIENTUPDATEBETA
   fi
   echo "************************************"
fi

echo $TZ > /etc/timezone
echo "Setting Timezone to: $TZ"
date
echo "************************************"

echo "Setting Language to: $LANG"
if [ "$GETARCH" == "32" ]; then
   export LANG=$LANG
fi
if [ "$GETARCH" == "64" ]; then
   localedef -i `echo $LANG | cut -d "." -f1` -c -f UTF-8 -A /usr/share/locale/locale.alias $LANG
   export LANG=$LANG
   export LANGUAGE=$LANG
fi
echo "************************************"

if [ "$VNCPASSWORD" != "none" ]; then
   echo "Setting the VNC Server Password: $VNCPASSWORD"
   if [ ! -e "/root/.vnc" ]; then mkdir /root/.vnc; fi
   x11vnc -storepasswd $VNCPASSWORD /root/.vnc/passwd &>/dev/null
   VNCAUTH="-rfbauth /root/.vnc/passwd"
   echo "************************************"
else
   VNCAUTH="-nopw"
fi

echo "Starting the VNC Server on Port: 5900"
rm -f /tmp/.X0-lock
Xvfb $DISPLAY -screen 0 "$DISPLAYSIZE"x24 & openbox & x11vnc $VNCAUTH -q -forever -loop -shared &>/dev/null &
echo "************************************"

echo "Starting the noVNC Webinterface on Port: 6080"
/opt/noVNC/utils/novnc_proxy --vnc :5900 &>/dev/null &
echo "************************************"

function configure_wine {
  echo "Configure Wine..."
  if [ -e $WINEPREFIX/dosdevices/z: ]; then
     echo "- Unlink $WINEPREFIX/dosdevices/z:"
     unlink $WINEPREFIX/dosdevices/z:
  fi
  if [ ! -e $WINEPREFIX/dosdevices/d: ]; then
     echo "- Link /data/ -> $WINEPREFIX/dosdevices/d:"
     ln -s /data/ $WINEPREFIX/dosdevices/d:
  fi

  echo "Setting Wine Registry Entries:"
  if [ ${#COMPUTER_NAME} -gt 15 ]; then
    echo "Error: computer name cannot be longer than 15 characters"
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
  if [ "$GETARCH" == "32" ]; then
     echo "- Disable the Debugger"
     wine reg delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug" /f &>/dev/null
  fi
  echo "************************************"
}

function rename_x64 {
  if [ -e "$BZPATHROOT/x64" -o -e "$BZPATHROOT/bzfilelist64.exe" -o -e "$BZPATHROOT/bztransmit64.exe" ]; then
     echo "Try to renaming x64 Binaries (we are running x86 only in this Container)!"
     echo "Without renaming them the Client try continusly starting them and wine will go in Debug Mode = High CPU Load!"
     echo "When a Message Pops up with 'Client is not installed correctly' ignore it and click in the main Client Window to hide the Warning in the background"
     echo "The Client will run fine!"
     echo "************************************"
  fi
  if [ -e "$BZPATHROOT/x64" ]; then
     if [ -e "$BZPATHROOT/x64-DISABLED" ]; then
        rm -rf "$BZPATHROOT/x64-DISABLED"
     fi
     mv -f "$BZPATHROOT/x64" "$BZPATHROOT/x64-DISABLED"
  fi
  if [ -e "$BZPATHROOT/bzfilelist64.exe" ]; then
     mv -f "$BZPATHROOT/bzfilelist64.exe" "$BZPATHROOT/bzfilelist64.exe-DISABLED"
  fi
  if [ -e "$BZPATHROOT/bztransmit64.exe" ]; then
     mv -f "$BZPATHROOT/bztransmit64.exe" "$BZPATHROOT/bztransmit64.exe-DISABLED"
  fi
}

function install_backblaze {
  echo "Backblaze installer started, please go through the graphical setup by logging onto the containers (no)VNC server"
  wine $WINEPREFIX/drive_c/install_backblaze.exe
  echo "************************************"
  echo "Installation finished or aborted! Lets check..."
  echo "************************************"
  if [ "$GETARCH" == "32" ]; then rename_x64; fi
  echo "Trying to start the Backblaze client..."
  wineserver -k
}

until [ -f "$BZPATH" ]; do
  echo "Backblaze not installed - Initializing the wine prefix..."
  wineboot -i -u
  echo "************************************"
  configure_wine
  if [ ! -e $WINEPREFIX/drive_c/install_backblaze.exe ]; then
     echo "Downloading the Backblaze personal installer..."
     wget -O $WINEPREFIX/drive_c/install_backblaze.exe https://secure.backblaze.com/api/install_backblaze?file=bzinstall-win32-8.5.0.627.exe
     sleep 2
     echo "************************************"
  fi
  install_backblaze
done

if [ -e $WINEPREFIX/drive_c/.CLIENTUPDATE ]; then
  configure_wine
  echo "Update Mode! Downloading the newest Client and starting install..."
  DATE=$(date '+%Y-%m-%d-%H.%M')
  if [ -e $WINEPREFIX/drive_c/install_backblaze.exe ]; then
    echo "Renaming old Installer to: $WINEPREFIX/drive_c/install_backblaze.exe_$DATE"
    mv -f $WINEPREFIX/drive_c/install_backblaze.exe $WINEPREFIX/drive_c/install_backblaze.exe_$DATE
  fi
  echo "************************************"
  if [ -e $WINEPREFIX/drive_c/.CLIENTUPDATEBETA ]; then
    echo "Downloading the Backblaze personal BETA installer..."
    wget https://f000.backblazeb2.com/file/backblazefiles/install_backblaze.exe -P $WINEPREFIX/drive_c/
  else
    echo "Downloading the Backblaze personal installer..."
    wget https://www.backblaze.com/win32/install_backblaze.exe -P $WINEPREFIX/drive_c/
  fi
  sleep 2
  CLIENTUPDATE=0
  rm -f $WINEPREFIX/drive_c/.CLIENTUPDATE
  if [ -e $WINEPREFIX/drive_c/.CLIENTUPDATEBETA ]; then rm -f $WINEPREFIX/drive_c/.CLIENTUPDATEBETA; fi
  echo "************************************"
  install_backblaze
fi

if [ -f "$BZPATH" ]; then
  configure_wine
  echo "Backblaze found, starting the Backblaze client..."
  wine "$BZPATH" -noquiet
  sleep infinity
fi
