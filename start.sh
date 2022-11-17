#!/bin/sh

if [ "$CLIENTUPDATE" != "0" ]; then
   echo "Client Update Mode ON!"
   touch $WINEPREFIX/drive_c/.CLIENTUPDATE
   echo "************************************"
fi

echo $TZ > /etc/timezone
echo "Setting Timezone to: $TZ"
date
echo "************************************"

echo "Setting Language to: $LANGUAGE"
export LC_ALL=$LANGUAGE
echo "************************************"

echo "Starting the VNC Server on Port: 5900"
rm -f /tmp/.X0-lock
Xvfb :0 -screen 0 910x730x24 & openbox & x11vnc -nopw -q -forever -loop -shared &>/dev/null &

if [ -f /opt/noVNC/utils/novnc_proxy ]; then
  echo "************************************"
  echo "Starting the noVNC Webinterface on Port: 6080"
  /opt/noVNC/utils/novnc_proxy --vnc :5900 &>/dev/null &
fi

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
  echo "- Setting the wine computer name: $COMPUTER_NAME"
  wine reg add "HKCU\\SOFTWARE\\Wine\\Network\\" /v UseDnsComputerName /f /d N &>/dev/null
  wine reg add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\ComputerName\\ComputerName" /v ComputerName /f /d $COMPUTER_NAME &>/dev/null
  wine reg add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\ComputerName\\ActiveComputerName" /v ComputerName /f /d $COMPUTER_NAME &>/dev/null
  echo "- Setting Font DPI"
  wine reg add "HKLM\\SYSTEM\\CurrentControlSet\\Hardware Profiles\\Current\\Software\\Fonts\\" /v LogPixels /t REG_DWORD /f /d 125 &>/dev/null
  echo "- Setting Font Smoothing"
  wine reg add "HKCU\\Control Panel\\Desktop\\" /v FontSmoothing /f /d 2 &>/dev/null
  wine reg add "HKCU\\Control Panel\\Desktop\\" /v FontSmoothingGamma /t REG_DWORD /f /d 578 &>/dev/null
  wine reg add "HKCU\\Control Panel\\Desktop\\" /v FontSmoothingOrientation /t REG_DWORD /f /d 1 &>/dev/null
  wine reg add "HKCU\\Control Panel\\Desktop\\" /v FontSmoothingType /t REG_DWORD /f /d 2 &>/dev/null
  echo "- Setting WineDbg BreakOnFirstChance 0 - let applications handle exceptions themselves"
  wine reg add "HKCU\\SOFTWARE\\Wine\\WineDbg\\" /v BreakOnFirstChance /t REG_DWORD /f /d 0 &>/dev/null
  echo "************************************"
}

function install_backblaze {
  echo "Backblaze installer started, please go through the graphical setup by logging onto the containers [no]VNC server"
  wine $WINEPREFIX/drive_c/install_backblaze.exe
  echo "************************************"
  echo "Installation finished or aborted! Lets check..."
  echo "************************************"
  echo "Try to renaming x64 Binaries (we are running x86 only in this Container)!"
  echo "Without renaming them the Client try continusly starting them and wine will go in Debug Mode = High CPU Load!"
  echo "When a Message Pops up with 'Client is not installed correctly' ignore it and click in the main Client Window to hide the Warning in the background"
  echo "The Client will run fine!"
  if [ -e $WINEPREFIX/drive_c/Program\ Files/Backblaze/x64 ]; then
     if [ -e $WINEPREFIX/drive_c/Program\ Files/Backblaze/x64-DISABLED ]; then 
        rm -rf $WINEPREFIX/drive_c/Program\ Files/Backblaze/x64-DISABLED
     fi
     mv -f $WINEPREFIX/drive_c/Program\ Files/Backblaze/x64 $WINEPREFIX/drive_c/Program\ Files/Backblaze/x64-DISABLED
  fi
  if [ -e $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzfilelist64.exe ]; then
     mv -f $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzfilelist64.exe $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzfilelist64.exe-DISABLED
  fi
  if [ -e $WINEPREFIX/drive_c/Program\ Files/Backblaze/bztransmit64.exe ]; then
     mv -f $WINEPREFIX/drive_c/Program\ Files/Backblaze/bztransmit64.exe $WINEPREFIX/drive_c/Program\ Files/Backblaze/bztransmit64.exe-DISABLED
  fi
  echo "************************************"
  echo "Trying to start the Backblaze client..."
  wineserver -k
}

until [ -f $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzbui.exe ]; do
  echo "************************************"
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
  echo "************************************"
  configure_wine
  echo "Update Mode! Downloading the newest Client and starting install..."
  DATE=$(date '+%Y-%m-%d-%H.%M')
  if [ -e $WINEPREFIX/drive_c/install_backblaze.exe ]; then
    echo "Renaming old Installer to: $WINEPREFIX/drive_c/install_backblaze.exe_$DATE"
    mv -f $WINEPREFIX/drive_c/install_backblaze.exe $WINEPREFIX/drive_c/install_backblaze.exe_$DATE
  fi
  echo "************************************"
  echo "Downloading the Backblaze personal installer..."
  wget https://www.backblaze.com/win32/install_backblaze.exe -P $WINEPREFIX/drive_c/
  sleep 2
  CLIENTUPDATE=0
  rm -f $WINEPREFIX/drive_c/.CLIENTUPDATE
  echo "************************************"
  install_backblaze
fi

if [ -f $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzbui.exe ]; then
  echo "************************************"
  configure_wine
  echo "Backblaze found, starting the Backblaze client..."
  wine $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzbui.exe -noqiet
fi
