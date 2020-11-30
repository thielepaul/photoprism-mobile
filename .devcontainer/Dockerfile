FROM cirrusci/flutter:1.22.4
RUN sudo chmod -R 777 /opt/android-sdk-linux
RUN sudo bash -c "echo 'adb kill-server && sudo /opt/android-sdk-linux/platform-tools/adb start-server' > /usr/bin/restart-adb" && \
    sudo chmod +x /usr/bin/restart-adb
RUN useradd -m flutter
RUN adduser flutter sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R flutter:flutter /sdks/flutter/
USER flutter