FROM raspbian_armhf:2015-05-12
RUN rm /etc/apt/sources.list.d/collabora.list; \
    rm /etc/apt/sources.list.d/raspi.list; \
    echo deb http://legacy.raspbian.org/raspbian/ wheezy main contrib non-free rpi > /etc/apt/sources.list; \
    apt-get update && apt-get install -y \
    build-essential git automake libcurl4-openssl-dev curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
run cd /tmp; git clone https://github.com/roswell/roswell; \
    cd /tmp/roswell;./bootstrap;./configure --with-fixed-arch=armhf --with-sbcl-bin-variant='-glibc2.13' ;make; make install; \
    cd /tmp;rm -rf /tmp/roswell; \
    mkdir -p /root/.roswell/archives/; \
    curl -k -L -o /root/.roswell/archives/sbcl-bin-2.4.8-armhf-linux.tar.bz2 https://github.com/roswell/sbcl_bin/releases/download/2.4.8/sbcl-2.4.8-armhf-linux-glibc2.13-binary.tar.bz2; \
    ros -v install sbcl-bin/2.4.8
run ros install snmsts/sn.github
