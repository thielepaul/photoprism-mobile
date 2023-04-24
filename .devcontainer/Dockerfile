FROM docker pull ghcr.io/cirruslabs/flutter:3.7.12
RUN useradd -m flutter -s /bin/bash
RUN adduser flutter sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R flutter:flutter /sdks/flutter
RUN chown -R flutter:flutter /opt/android-sdk-linux
RUN chmod 755 /root
RUN apt update && apt install -y libsqlite3-dev
RUN apt install -y libjsoncpp-dev libsecret-1-dev libgtk-3-dev pkg-config clang ninja-build cmake
USER flutter