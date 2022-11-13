echo "Starting the virtual display & vnc server"
rm -f /tmp/.X0-lock
Xvfb :0 -screen 0 700x570x24 & openbox & x11vnc -nopw -q -forever -loop -shared &

if [ -f /opt/noVNC/utils/novnc_proxy ]; then
  /opt/noVNC/utils/novnc_proxy --vnc :5900 &
fi

function configure_wine {
  unlink $WINEPREFIX/dosdevices/z:
  ln -s /data/ $WINEPREFIX/dosdevices/d:

  if [ ${#COMPUTER_NAME} -gt 15 ]; then 
    echo "Error: computer name cannot be longer than 15 characters"
    exit 1
  fi
  echo "Setting the wine computer name"
  wine reg add "HKCU\\SOFTWARE\\Wine\\Network\\" /v UseDnsComputerName /f /d N
  wine reg add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\ComputerName\\ComputerName" /v ComputerName /f /d $COMPUTER_NAME
  wine reg add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\ComputerName\\ActiveComputerName" /v ComputerName /f /d $COMPUTER_NAME
  echo "Setting WindeDbg BreakOnFirstChance 0 - let applications handle exceptions themselves"
  wine reg add "HKCU\\SOFTWARE\\Wine\\WineDbg\\" /v BreakOnFirstChance /t REG_DWORD /f /d 0
}

until [ -f $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzbui.exe ]; do
  echo "Backblaze not installed"
  echo "Initializing the wine prefix"
  wineboot -i -u
  configure_wine
  echo "Downloading the Backblaze personal installer..."
  wget -q https://www.backblaze.com/win32/install_backblaze.exe -P $WINEPREFIX/drive_c/
  echo "Backblaze installer started, please go through the graphical setup in by logging onto the containers vnc server"
  wine $WINEPREFIX/drive_c/install_backblaze.exe
  echo "Installation finished or aborted, trying to start the Backblaze client..."
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "Renaming x64 Binaries (we are running x86 only in this Container)!"
  echo "Without renaming them the Client try continusly starting them and wine will go in Debug Mode = High CPU Load!"
  echo "When a Message Pops up with Client is not installed correctly ignore it and click in the main Client Window to hide the Warning in the background"
  echo "The Client will run fine!"
  mv $WINEPREFIX/drive_c/Program\ Files/Backblaze/x64 $WINEPREFIX/drive_c/Program\ Files/Backblaze/x64-DISABLED
  mv $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzfilelist64.exe $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzfilelist64.exe-DISABLED
  mv $WINEPREFIX/drive_c/Program\ Files/Backblaze/bztransmit64.exe $WINEPREFIX/drive_c/Program\ Files/Backblaze/bztransmit64.exe-DISABLED
  echo "---------------------------------------------------------------------------------------------------------------"
  wineserver -k
done

if [ -f $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzbui.exe ]; then
  configure_wine
  echo "Backblaze found, starting the Backblaze client..."
  wine $WINEPREFIX/drive_c/Program\ Files/Backblaze/bzbui.exe -noqiet
fi
