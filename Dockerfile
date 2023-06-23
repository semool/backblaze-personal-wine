FROM i386/alpine:3.13.12 AS builder

# Create Builder Image
RUN \
    # Install required packages
    apk --update --no-cache --virtual .build-deps add \
    git && \
    #--------------
    # Get segoe-ui-linux Font
    FONTPATH=/usr/share/fonts/Microsoft/TrueType/SegoeUI && \
    mkdir -p $FONTPATH && \
    FONTFILES="segoeui segoeuib segoeuii segoeuiz segoeuil seguili segoeuisl seguisli seguisb seguisbi" && \
    for f in $FONTFILES; do wget --no-check-certificate -O $FONTPATH/$f.ttf https://raw.githubusercontent.com/mrbvrz/segoe-ui/master/font/$f.ttf; done && \
    #--------------
    # Get noVNC
    NOVNCPATH="/opt/noVNC" && \
    NOVNCVERSION="1.4.0" && \
    SOCKIFYVERSION="0.11.0" && \
    git config --global advice.detachedHead false && \
    git clone https://github.com/novnc/noVNC --branch v$NOVNCVERSION $NOVNCPATH && \
    git clone https://github.com/novnc/websockify --branch v$SOCKIFYVERSION $NOVNCPATH/utils/websockify && \
    ln -s $NOVNCPATH/vnc.html $NOVNCPATH/index.html && \
    sed -i s"/'autoconnect', false/'autoconnect', 'true'/" $NOVNCPATH/app/ui.js && \
    #--------------
    # Replace noVNC Favicon
    rm $NOVNCPATH/app/images/icons/novnc.ico && \
    wget --no-check-certificate -O $NOVNCPATH/app/images/icons/novnc.ico https://www.backblaze.com/favicon.ico && \
    #--------------
    # Get openbox themes
    git clone https://github.com/terroo/openbox-themes && \
    #--------------
    # Cleanup
    apk del .build-deps && \
    rm -r $NOVNCPATH/.git* $NOVNCPATH/utils/websockify/.git*
    #--------------

FROM amd64/debian:buster-slim

# Not needed for Alpine and Debian Images, but for Ubuntu
#ENV DEBIAN_FRONTEND=noninteractive

# Get Files from the builder image

# Install segoe-ui-linux Font instead of ttf-dejavu
COPY --from=builder /usr/share/fonts/Microsoft/TrueType/SegoeUI ./usr/share/fonts/Microsoft/TrueType/SegoeUI
#--------------
# Install noVNC
COPY --from=builder /opt/noVNC ./opt/noVNC
#--------------
# Install openbox theme
COPY --from=builder /openbox-themes/Afterpiece ./root/.themes/Afterpiece
#--------------

# Build Final Image
RUN \
    DISTRO="debian" && \
    DISTROVERSION="buster" && \
    # Add i386
    dpkg --add-architecture i386 && \
    #--------------
    # Install required packages
    apt-get update && \
    apt-get upgrade -y && \
    apt-get --no-install-recommends install \
    xvfb x11vnc openbox wget locales tzdata ca-certificates \
    fonts-dejavu fonts-liberation fonts-wine \
    #wine wine32 wine64 \
    # for noVNC
    python3 procps openssl \
    # numpy for noVNC - optional, not needed for this purpose
    #python3-numpy \
    -y && \
    #--------------
    # Install WineHQ
    WINEDISTRO="$DISTROVERSION" && \
    WINEBRANCH="stable" && \
    WINEVERSION="4.0.4~$DISTROVERSION" && \
    mkdir -p /etc/apt/keyrings && \
    wget --no-check-certificate -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget --no-check-certificate -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/$DISTRO/dists/$WINEDISTRO/winehq-$WINEDISTRO.sources && \
    apt-get update && \
    apt-get --no-install-recommends install \
    winehq-$WINEBRANCH=$WINEVERSION \
    wine-$WINEBRANCH=$WINEVERSION \
    wine-$WINEBRANCH-amd64=$WINEVERSION \
    wine-$WINEBRANCH-i386=$WINEVERSION \
    -y && \
    #--------------
    # Rebuild Font Cache
    fc-cache -f /usr/share/fonts/Microsoft/TrueType/SegoeUI && \
    #--------------
    # Edit openbox config
    OBCONF="/root/.config/openbox/rc.xml" && \
    mkdir -p /root/.config/openbox && \
    cp /etc/xdg/openbox/rc.xml $OBCONF && \
    # Disable non existent Debian Menu
    sed -i s"/<file>\/var\/lib\/openbox\/debian-menu.xml<\/file>//" $OBCONF && \
    # Set openbox theme
    sed -i s"/<name>Clearlooks<\/name>/<name>Afterpiece<\/name>/" $OBCONF && \
    # Set Window Font
    sed -i s"/<name>sans<\/name>/<name>Segoe UI<\/name>/" $OBCONF && \
    # Set openbox Titlebar Font Size
    sed -i s"/<size>8<\/size>/<size>10<\/size>/" $OBCONF && \
    # Disable openbox right click root menu
    sed -i s"/<action name=\"ShowMenu\"><menu>root-menu<\/menu><\/action>//" $OBCONF && \
    #--------------
    # Create wineprefix and data dir
    mkdir /wine /data && \
    #--------------
    # Cleanup
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/cache/fontconfig/* \
          /var/lib/apt/lists/* \
         /usr/share/doc \
    && \
    #--------------
    # get start.sh direct from Github
    wget --no-check-certificate https://raw.githubusercontent.com/semool/backblaze-personal-wine/master/start.sh && \
    chmod 755 start.sh
    #--------------

# Copy the start script to the container
#COPY start.sh /start.sh

# Set Language
ENV LANG en_US.UTF-8

# Set Timezone
ENV TZ Etc/UTC

# Configure the virtual display port
ENV DISPLAY :0

# Displaysize
ENV DISPLAYSIZE 910x740

# Expose the VNC Port
EXPOSE 5900

# Expose the noVNC-Web port
EXPOSE 6080

# VNC Password
ENV VNCPASSWORD none

# noVNC SSL
ENV NOVNCSSL 0

# Expert Mount Modus
ENV MOUNTEXPERT 0

# redownload Client for update/reinstall
ENV CLIENTUPDATE 0

# Configure the wine prefix
ENV WINEPREFIX /wine

# Disable wine debug messages
ENV WINEDEBUG -all

# Configure wine to run without mono or gecko as they are not required
ENV WINEDLLOVERRIDES mscoree,mshtml=

# Set the wine computer name
ENV COMPUTERNAME backblaze

# Healthcheck for Client GUI
HEALTHCHECK CMD pidof bzserv.exe >/dev/null || exit 1

# Set the start script as entrypoint
ENTRYPOINT ./start.sh
