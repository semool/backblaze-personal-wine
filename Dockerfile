FROM i386/alpine:3.12.1

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apk --update --upgrade --no-cache add wine xvfb x11vnc openbox samba-winbind-clients ttf-dejavu \
    libintl tzdata bash python3 procps

# Virtual Packages only for Image Build
RUN apk --update --no-cache --virtual .build-deps add cmake make musl-dev gcc gettext-dev git \
    build-base python3-dev py-pip

# Install Languages
ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"
RUN git clone https://gitlab.com/rilian-la-te/musl-locales.git && \
    cd musl-locales && cmake -DLOCALE_PROFILE=OFF -DCMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install && \
    cd .. && rm -r musl-locales

# Install noVNC
RUN git config --global advice.detachedHead false && git clone https://github.com/novnc/noVNC --branch v1.3.0 /opt/noVNC && \
    git clone https://github.com/novnc/websockify --branch v0.10.0 /opt/noVNC/utils/websockify && \
    rm -R /opt/noVNC/.git* && \
    rm -R /opt/noVNC/utils/websockify/.git* && \
    cp /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    sed -i s"/'autoconnect', false/'autoconnect', 'true'/" /opt/noVNC/app/ui.js && \
    # Delete virtual Packages
    apk del .build-deps

# Replace noVNC Favicon
COPY icons.zip /opt/noVNC/app/images/icons/
RUN unzip -o /opt/noVNC/app/images/icons/icons.zip -d /opt/noVNC/app/images/icons/ && rm /opt/noVNC/app/images/icons/icons.zip

# Disable openbox right click menu
COPY rc.xml /root/.config/openbox/rc.xml

# Configure the wine prefix location and Data Dir
RUN mkdir /wine && mkdir /data
ENV WINEPREFIX /wine

# Workaround for fontconfig invalid cache files spam - BUG?!
RUN rm -R /usr/share/fonts/100dpi \
          /usr/share/fonts/75dpi \
          /usr/share/fonts/cyrillic \
          /usr/share/fonts/encodings \
          /usr/share/fonts/misc && \
          rm -R /var/cache/fontconfig && \
          ln -s /dev/null /var/cache/fontconfig

# Set Language
ENV LANGUAGE=$LANGUAGE

# Add Timezone
ENV TZ=$TZ

# Configure the virtual display port
ENV DISPLAY :0

# Disable wine debug messages
ENV WINEDEBUG -all

# Configure wine to run without mono or gecko as they are not required
ENV WINEDLLOVERRIDES mscoree,mshtml=

# Set the wine computer name
ENV COMPUTER_NAME bz-docker

# Expose the VNC and noVNC-Web port
EXPOSE 5900 6080

# Copy the start script to the container
COPY start.sh /start.sh

# Set the start script as entrypoint
ENTRYPOINT ./start.sh
