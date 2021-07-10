FROM alpine:3.13

# Configure a nice terminal
# Fake poweroff (stops the container from the inside by sending SIGTERM to PID 1)
RUN echo "export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/profile && \
    echo "alias poweroff='kill 1'" >> /etc/profile

# Whenever possible, install tools using the distro package manager
RUN apk add --quiet --no-cache tini git iproute2 tcpdump

WORKDIR .
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh", "-i", "-l"]
