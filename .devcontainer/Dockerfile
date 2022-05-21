FROM cirrusci/flutter:3.0.0
RUN useradd -m flutter
RUN adduser flutter sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R flutter:flutter /sdks/flutter
RUN chown -R flutter:flutter /opt/android-sdk-linux
RUN chown -R flutter:flutter /root/.pub-cache
RUN chmod 755 /root
RUN apt update && apt install -y libsqlite3-dev
USER flutter