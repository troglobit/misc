FROM alpine:3.13

# Configure a nice terminal
# Fake poweroff (stops the container from the inside by sending SIGTERM to PID 1)
RUN echo "export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/profile && \
    echo "alias poweroff='kill 1'" >> /etc/profile

# Whenever possible, install tools using the distro package manager
RUN apk add --quiet --no-cache tini alpine-sdk linux-headers autoconf automake \
	iproute2 socat tcpdump tree libcap-dev libnet-dev

WORKDIR /root

# Nemesis isn't available in Alpine yet, drop man pages
RUN wget https://github.com/libnet/nemesis/releases/download/v1.8/nemesis-1.8.tar.gz;	\
    tar xf nemesis-1.8.tar.gz; cd nemesis-1.8/;					  	\
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var && make -j3;	\
    make install-strip; rm -rf /usr/share/man; cd ..; rm -rf nemesis-1.8*

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh", "-i", "-l"]
