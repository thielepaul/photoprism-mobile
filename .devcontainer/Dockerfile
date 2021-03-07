FROM cirrusci/flutter:2.0.1
RUN useradd -m flutter
RUN adduser flutter sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R flutter:flutter /sdks/flutter
RUN chown -R flutter:flutter /opt/android-sdk-linux
RUN apt update && apt install -y libsqlite3-dev
USER flutter