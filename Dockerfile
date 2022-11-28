ARG BASEIMAGE="i386/alpine:3.13.12"
FROM i386/alpine:3.13.12 AS builder

# Create Builder Image
RUN \
    # Install required packages
    apk --update --no-cache --virtual add imagemagick git && \
    #--------------
    # Get segoe-ui-linux Font
    FONTPATH=/usr/share/fonts/Microsoft/TrueType/SegoeUI && \
    mkdir -p $FONTPATH && \
    FONTFILES="segoeui segoeuib segoeuii segoeuiz segoeuil seguili segoeuisl seguisli seguisb seguisbi" && \
    for f in $FONTFILES; do wget -O $FONTPATH/$f.ttf https://raw.githubusercontent.com/mrbvrz/segoe-ui/master/font/$f.ttf; done && \
    #fc-cache -f $FONTPATH && \
    #--------------
    # Get noVNC
    NOVNCPATH="/opt/noVNC" && \
    git config --global advice.detachedHead false && \
    git clone https://github.com/novnc/noVNC --branch v1.3.0 $NOVNCPATH && \
    git clone https://github.com/novnc/websockify --branch v0.10.0 $NOVNCPATH/utils/websockify && \
    ln -s $NOVNCPATH/vnc.html $NOVNCPATH/index.html && \
    sed -i s"/'autoconnect', false/'autoconnect', 'true'/" $NOVNCPATH/app/ui.js && \
    rm -r $NOVNCPATH/.git* $NOVNCPATH/utils/websockify/.git* && \
    #--------------
    # Replace noVNC Icons
    wget -O logo.png https://www.backblaze.com/blog/wp-content/uploads/2017/12/backblaze_icon_transparent.png && \
    rm $NOVNCPATH/app/images/icons/novnc-*.png && \
    ICONSIZE="192x192 152x152 144x144 120x120 96x96 76x76 72x72 64x64 60x60 48x48 32x32 24x24 16x16" && \
    for i in $ICONSIZE; do convert -resize $i logo.png $NOVNCPATH/app/images/icons/novnc-$i.png; done && \
    #--------------
    # Get openbox themes
    git clone https://github.com/terroo/openbox-themes
    #--------------

FROM $BASEIMAGE
ARG BASEIMAGE

# Not needed for Alpine and Debian Images, but for Ubuntu
#ENV DEBIAN_FRONTEND=noninteractive

# Get Files from the builder image
# Install segoe-ui-linux Font instead of ttf-dejavu
COPY --from=builder /usr/share/fonts/Microsoft/TrueType/SegoeUI ./usr/share/fonts/Microsoft/TrueType/SegoeUI
# Install noVNC
COPY --from=builder /opt/noVNC ./opt/noVNC
# Install openbox theme
COPY --from=builder /openbox-themes/Afterpiece ./root/.themes/Afterpiece

# Build Final Image
RUN \
    # Set arch version
    if [ "$BASEIMAGE" = "i386/alpine:3.13.12" ]; then ARCH="32"; \
    elif [ "$BASEIMAGE" = "amd64/debian:buster-slim" ]; then ARCH="64"; else \
    echo -e "\033[0;31m!!!!!WARNING!!!!! BASEIMAGE must be 'i386/alpine:3.13.12' or 'amd64/debian:buster-slim'! EXIT BUILD !!!!!WARNING!!!!!\033[0m" && exit 1; \
    fi && \
    #--------------
    # Install Packages x86
    if [ "$ARCH" = "32" ]; then \
       # Install required packages
       apk --update --upgrade --no-cache add \
       wine xvfb x11vnc openbox samba-winbind-clients tzdata musl-locales \
       # for noVNC
       bash python3 procps \
       # numpy for noVNC - optional, not needed for this purpose
       #py3-numpy \
       #--------------
       ; \
    fi && \
    #--------------
    # Install Packages x64
    if [ "$ARCH" = "64" ]; then \
       # Add i386
       dpkg --add-architecture i386 && \
       #--------------
       # Install required packages
       apt-get update && \
       apt-get upgrade -y && \
       apt-get --no-install-recommends install \
       xvfb x11vnc openbox wget locales tzdata ca-certificates fonts-dejavu \
       #wine wine32 wine64 \
       # for noVNC
       python3 procps \
       # numpy for noVNC - optional, not needed for this purpose
       #python3-numpy \
       -y \
       #--------------
       # Install WineHQ
       && \
       WINEDISTRO="buster" && \
       WINEBRANCH="stable" && \
       WINEVERSION="4.0.4~buster" && \
       mkdir -pm755 /etc/apt/keyrings && \
       wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
       wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/$WINEDISTRO/winehq-$WINEDISTRO.sources && \
       apt-get update && \
       apt-get --no-install-recommends install \
       winehq-$WINEBRANCH=$WINEVERSION \
       wine-$WINEBRANCH=$WINEVERSION \
       wine-$WINEBRANCH-amd64=$WINEVERSION \
       wine-$WINEBRANCH-i386=$WINEVERSION \
       -y \
       #--------------
       ; \
    fi && \
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
    # Set openbox Titlebar Font Size
    sed -i s"/<size>8<\/size>/<size>10<\/size>/" $OBCONF && \
    # Disable openbox right click root menu
    sed -i s"/<action name=\"ShowMenu\"><menu>root-menu<\/menu><\/action>//" $OBCONF && \
    #--------------
    # Create wineprefix and data dir
    mkdir /wine /data && \
    #--------------
    # Cleanup x86
    if [ "$ARCH" = "32" ]; then \
       # Workaround for fontconfig invalid cache files spam - BUG!
       rm -R /usr/share/fonts/100dpi \
             /usr/share/fonts/75dpi \
             /usr/share/fonts/cyrillic \
             /usr/share/fonts/encodings \
             /usr/share/fonts/misc \
             /var/cache/fontconfig && \
       ln -s /dev/null /var/cache/fontconfig \
       ; \
    fi && \
    #--------------
    # Cleanup x64
    if [ "$ARCH" = "64" ]; then \
       rm -rf /var/lib/apt/lists/* \
              /usr/share/doc && \
       apt-get autoremove -y && \
       apt-get clean && \
       rm -rf /var/lib/apt/lists/* && \
       # Purge Possible not needed packages dirty
       dpkg --purge --force-depends \
               libsndfile1:amd64 libsndfile1:i386 \
               libsndio7.0:amd64 libsndio7.0:i386 \
               libasound2:amd64 libasound2:i386 libasound2-data \
               libdrm-amdgpu1 libdrm-common libdrm-intel1 libdrm-nouveau2 libdrm-radeon1 libdrm2:amd64 libdrm2:i386 \
               libgstreamer-plugins-base1.0-0:amd64 libgstreamer-plugins-base1.0-0:i386 libgstreamer1.0-0:amd64 libgstreamer1.0-0:i386 \
               libvulkan1:amd64 libvulkan1:i386 \
               libgpg-error0:i386 libgphoto2-6:amd64 libgphoto2-6:i386 libgphoto2-port12:amd64 libgphoto2-port12:i386 \
               libsensors-config libsensors5:amd64 \
               libgl1-mesa-dri:amd64 libllvm7:amd64 libicu63:i386 \
               libxml2:i386 iso-codes \
               libexif12:amd64 libexif12:i386 \
               libflac8:amd64 libflac8:i386 libmpg123-0:amd64 libmpg123-0:i386 \
               libopenal1:amd64 libopenal1:i386 libopenal-data \
               libpulse0:amd64 libpulse0:i386 libvkd3d1:amd64 libvkd3d1:i386 \
               libvorbis0a:amd64 libvorbis0a:i386 libvorbisenc2:amd64 libvorbisenc2:i386 \
               libavcodec58:amd64 libavcodec58:i386 \
               libatomic1:amd64 libatomic1:i386 \
               libx264-155:amd64 libx264-155:i386 \
               libsamplerate0:amd64 libsamplerate0:i386 \
               libgnutls30:i386 \
       ; \
    fi && \
    #--------------
    # get start.sh direct from Github
    wget https://raw.githubusercontent.com/semool/backblaze-personal-wine/master/start.sh && \
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

# redownload Client for update/reinstall
ENV CLIENTUPDATE 0

# Configure the wine prefix
ENV WINEPREFIX /wine

# Disable wine debug messages
ENV WINEDEBUG -all

# Configure wine to run without mono or gecko as they are not required
ENV WINEDLLOVERRIDES mscoree,mshtml=

# Set the wine computer name
ENV COMPUTERNAME bz-docker

# Healthcheck for Client GUI
HEALTHCHECK CMD pidof bzserv.exe >/dev/null || exit 1

# Set the start script as entrypoint
ENTRYPOINT ./start.sh
