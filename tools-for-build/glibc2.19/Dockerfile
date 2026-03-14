FROM ubuntu:14.04
RUN apt-get update && apt-get install -y \
    build-essential git automake libcurl4-openssl-dev curl software-properties-common \
 && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1E9377A2BA9EF27F \
 && apt-get update && apt-get install -y gcc-5 g++-5 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 60 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-5 \
 && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-5 60 \
 && (apt-get install -y gcc-multilib || true ) \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
run cd /tmp; git clone https://github.com/roswell/roswell; \
    cd /tmp/roswell;./bootstrap;./configure --with-sbcl-bin-variant='-glibc2.19' ;make; make install; \
    cd /tmp;rm -rf /tmp/roswell; \
    (ros install sbcl-bin/2.4.7 || true);
run (ros install snmsts/sn.github || true)
