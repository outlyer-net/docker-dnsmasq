# dnsmasq in a Docker container
#
# This Dockerfile creates an image for the amd64 architecture.
#
# <https://github.com/outlyer-net/docker-dnsmasq-multiarch>
#
# Must be defined before the first FROM
ARG DOCKER_PREFIX=amd64
ARG ARCHITECTURE=amd64

# Stage 0: Preparations. To be run on the build host
FROM alpine:latest
ARG ARCHITECTURE
ARG ALPINE_ARCH=x86_64
# webproc release settings
ARG WEBPROC_VERSION=0.2.2
ARG WEBPROC_URL="https://github.com/jpillora/webproc/releases/download/$WEBPROC_VERSION/webproc_linux_${ARCHITECTURE}.gz"
# fetch webproc binary
RUN wget -O - ${WEBPROC_URL} | gzip -d > /webproc \
	&& chmod 0755 /webproc
# dnsmasq configuration
RUN echo -e "ENABLED=1\nIGNORE_RESOLVCONF=yes" > /dnsmasq.default
# FIXME: This is an ugly hack, but can't run apk cross-platform on stage 1
RUN apk update \
	&& wget -O /dnsmasq.apk `apk policy dnsmasq | tail -1`/${ALPINE_ARCH}/dnsmasq-`apk policy dnsmasq \
		| sed -e '2!d' -e 's/ *//' -e 's/://'`.apk
RUN tar xvf /dnsmasq.apk usr/sbin/dnsmasq

# Stage 1: The actual produced image
FROM ${DOCKER_PREFIX}/alpine:latest
LABEL maintainer="Toni Corvera <outlyer@gmail.com>"
ARG ARCHITECTURE
# import webproc binary from previous stage
COPY --from=0 /webproc /usr/local/bin/
# fetch dnsmasq
#RUN apk update && apk --no-cache add dnsmasq
# FIXME: ugly hack part 2
COPY --from=0 /usr/sbin/dnsmasq /usr/local/sbin/
# configure dnsmasq
COPY --from=0 /dnsmasq.default /etc/default/dnsmasq
COPY dnsmasq.conf /etc/dnsmasq.conf

# TODO: 5353/udp?
EXPOSE 80/tcp 67/udp 53/tcp 53/udp

# run!
ENTRYPOINT ["webproc","--port","80","--config","/etc/dnsmasq.conf","--","dnsmasq","--no-daemon"]
