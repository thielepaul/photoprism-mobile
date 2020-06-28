FROM cirrusci/flutter:1.17.4
RUN sudo chmod -R 777 /opt/android-sdk-linux
RUN sudo bash -c "echo 'adb kill-server && sudo /opt/android-sdk-linux/platform-tools/adb start-server' > /usr/bin/restart-adb" && \
    sudo chmod +x /usr/bin/restart-adb
RUN rm /home/cirrus/.android/adbkey /home/cirrus/.android/adbkey.pub /home/cirrus/.gitconfig