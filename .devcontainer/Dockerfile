FROM cirrusci/flutter:v1.12.13-hotfix.9
RUN sudo chmod -R 777 /opt/android-sdk-linux
RUN sudo bash -c "echo 'adb kill-server && sudo /opt/android-sdk-linux/platform-tools/adb start-server' > /usr/bin/restart-adb" && \
    sudo chmod +x /usr/bin/restart-adb
RUN sudo bash -c "echo fs.inotify.max_user_watches=524288 >> /etc/sysctl.conf" && sudo sysctl -p
RUN rm /home/cirrus/.android/adbkey /home/cirrus/.android/adbkey.pub