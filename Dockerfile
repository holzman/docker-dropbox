FROM fedora:23
MAINTAINER Burt Holzman <holzman@gmail.com>

RUN dnf -y install tar
RUN curl -L "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
RUN curl -L "https://www.dropbox.com/download?dl=packages/dropbox.py" > /usr/sbin/dropbox && chmod 755 /usr/sbin/dropbox
RUN dnf -y install python ca-certificates python-gpgme

RUN groupadd dropbox && useradd -m -d /dbox -c "Dropbox Daemon Account" -s /usr/sbin/nologin -g dropbox dropbox

USER dropbox
RUN mkdir -p /dbox/.dropbox /dbox/.dropbox-dist /dbox/Dropbox /dbox/base \
    && echo y | dropbox start -i

USER root
#
## Dropbox has the nasty tendency to update itself without asking. In the processs it fills the
## file system over time with rather large files written to /dbox and /tmp. The auto-update routine
## also tries to restart the dockerd process (PID 1) which causes the container to be terminated.
RUN mkdir -p /opt/dropbox \
    # Prevent dropbox to overwrite its binary
    && mv /dbox/.dropbox-dist/dropbox-lnx* /opt/dropbox/ \
    && mv /dbox/.dropbox-dist/dropboxd /opt/dropbox/ \
    && mv /dbox/.dropbox-dist/VERSION /opt/dropbox/ \
    && rm -rf /dbox/.dropbox-dist \
    && install -dm0 /dbox/.dropbox-dist \
    # Prevent dropbox to write update files
    && chmod u-w /dbox \
    && chmod o-w /tmp \
    && chmod g-w /tmp \
    # Prepare for command line wrapper
    && mv /usr/sbin/dropbox /usr/bin/dropbox-cli

## Install init script and dropbox command line wrapper
COPY run /root/
COPY dropbox-wrapper /usr/bin/dropbox
#

WORKDIR /dbox/Dropbox
EXPOSE 17500
VOLUME ["/dbox/.dropbox", "/dbox/Dropbox"]
ENTRYPOINT ["/root/run"]
