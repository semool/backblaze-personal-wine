ARG BASEIMAGE="i386/alpine:3.13.12"
FROM $BASEIMAGE
ARG BASEIMAGE

# Not needed for Alpine and Debian Images, but for Ubuntu
ENV DEBIAN_FRONTEND=noninteractive

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
       wine xvfb x11vnc openbox samba-winbind-clients tzdata \
       # for noVNC
       bash python3 procps \
       # for language
       libintl && \
       #--------------
       # Install temporary packages
       apk --update --no-cache --virtual .build-deps add \
       # for language
       cmake make musl-dev gcc gettext-dev \
       # for noVNC
       imagemagick \
       # for numpy
       #build-base python3-dev py-pip \
       # for language and novnc
       git \
       #--------------
       && \
       # Install locales
       git clone https://gitlab.com/rilian-la-te/musl-locales.git && \
       cd musl-locales && \
       cmake -DLOCALE_PROFILE=OFF -DCMAKE_INSTALL_PREFIX:PATH=/usr . && \
       make && \
       make install && \
       cd .. \
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
       wine wine32 wine64 xvfb x11vnc openbox wget locales tzdata ca-certificates \
       # for noVNC
       python3 procps imagemagick git \
       # for numpy
       #build-base python3-dev py-pip \
       -y \
       ; \
    fi && \
    #--------------
    # Install segoe-ui-linux Font instead of ttf-dejavu
    DEST_DIR="/usr/share/fonts/Microsoft/TrueType/Segoe UI/" && \
    mkdir -p "$DEST_DIR" && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/segoeui.ttf?raw=true -O "$DEST_DIR"/segoeui.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/segoeuib.ttf?raw=true -O "$DEST_DIR"/segoeuib.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/segoeuii.ttf?raw=true -O "$DEST_DIR"/segoeuii.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/segoeuiz.ttf?raw=true -O "$DEST_DIR"/segoeuiz.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/segoeuil.ttf?raw=true -O "$DEST_DIR"/segoeuil.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/seguili.ttf?raw=true -O "$DEST_DIR"/seguili.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/segoeuisl.ttf?raw=true -O "$DEST_DIR"/segoeuisl.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/seguisli.ttf?raw=true -O "$DEST_DIR"/seguisli.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/seguisb.ttf?raw=true -O "$DEST_DIR"/seguisb.ttf && \
    wget https://github.com/mrbvrz/segoe-ui/raw/master/font/seguisbi.ttf?raw=true -O "$DEST_DIR"/seguisbi.ttf && \
    fc-cache -f "$DEST_DIR" && \
    #--------------
    # Install noVNC
    # Not needed for this purpose and saves ~100MB # pip install --no-cache-dir numpy && \
    git config --global advice.detachedHead false && \
    git clone https://github.com/novnc/noVNC --branch v1.3.0 /opt/noVNC && \
    git clone https://github.com/novnc/websockify --branch v0.10.0 /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    sed -i s"/'autoconnect', false/'autoconnect', 'true'/" /opt/noVNC/app/ui.js && \
    #--------------
    # Replace noVNC Icons
    wget -O logo.png https://www.backblaze.com/blog/wp-content/uploads/2017/12/backblaze_icon_transparent.png && \
    rm /opt/noVNC/app/images/icons/novnc-*.png && \
    ICONSIZE="192x192 152x152 144x144 120x120 96x96 76x76 72x72 64x64 60x60 48x48 32x32 24x24 16x16" && \
    for i in $ICONSIZE; do convert -resize $i logo.png /opt/noVNC/app/images/icons/novnc-$i.png; done && \
    rm logo.png && \
    #--------------
    # Install openbox theme
    git clone https://github.com/terroo/openbox-themes && \
    mkdir -p /root/.themes && \
    cd openbox-themes && \
    mv Afterpiece /root/.themes/ && \
    cd .. && \
    #--------------
    # Copy openbox config
    mkdir -p /root/.config/openbox && \
    cp /etc/xdg/openbox/rc.xml /root/.config/openbox/rc.xml && \
    #--------------
    # Disable non existent Debian Menu
    if [ "$ARCH" = "64" ]; then \
       sed -i s"/<file>\/var\/lib\/openbox\/debian-menu.xml<\/file>//" /root/.config/openbox/rc.xml \
       ; \
    fi && \
    #--------------
    # Set openbox theme
    sed -i s"/<name>Clearlooks<\/name>/<name>Afterpiece<\/name>/" /root/.config/openbox/rc.xml && \
    #--------------
    # Set openbox Titlebar Font Size
    sed -i s"/<size>8<\/size>/<size>10<\/size>/" /root/.config/openbox/rc.xml && \
    #--------------
    # Disable openbox right click root menu
    sed -i s"/<action name=\"ShowMenu\"><menu>root-menu<\/menu><\/action>//" /root/.config/openbox/rc.xml && \
    #--------------
    # get start.sh direct from Github
    wget https://raw.githubusercontent.com/semool/backblaze-personal-wine/master/start.sh && \
    chmod 755 start.sh && \
    #--------------
    # Create wineprefix and data dir
    mkdir /wine /data && \
    #--------------
    # Cleanup x86/x64
    rm -R openbox-themes \
          /opt/noVNC/.git* \
          /opt/noVNC/utils/websockify/.git* && \
    #--------------
    # Cleanup x86
    if [ "$ARCH" = "32" ]; then \
       apk del .build-deps && \
       rm -R musl-locales && \
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
       apt-get purge git imagemagick \
       -y && \
       apt-get autoremove -y && \
       apt-get clean && \
       rm -rf /var/lib/apt/lists/* && \
       dpkg -r --force-depends fonts-dejavu-core \
       ; \
    fi
    #--------------

# Copy the start script to the container
#COPY start.sh /start.sh

# Set Language
ENV LANGUAGE=en_US.UTF-8

# Set Timezone
ENV TZ=Etc/UTC

# Configure the virtual display port
ENV DISPLAY :0

# Expose the VNC and noVNC-Web port
EXPOSE 5900 6080

# redownload Client for update/reinstall
ENV CLIENTUPDATE=0

# Configure the wine prefix
ENV WINEPREFIX /wine

# Disable wine debug messages
ENV WINEDEBUG -all

# Configure wine to run without mono or gecko as they are not required
ENV WINEDLLOVERRIDES mscoree,mshtml=

# Set the wine computer name
ENV COMPUTER_NAME bz-docker

# Healthcheck for Client GUI
HEALTHCHECK CMD pidof bzbui.exe >/dev/null || exit 1

# Set the start script as entrypoint
ENTRYPOINT ./start.sh
