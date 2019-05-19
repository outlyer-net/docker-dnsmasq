ARG DOCKER_PREFIX=arm32v7
ARG ARCHITECTURE=arm
# Stage 0: Preparations. To be run on the build host
FROM alpine:latest
ARG ARCHITECTURE
# webproc release settings
ARG WEBPROC_VERSION=0.2.2
ARG WEBPROC_URL="https://github.com/jpillora/webproc/releases/download/$WEBPROC_VERSION/webproc_linux_${ARCHITECTURE}.gz"
# fetch webproc binary
RUN wget -O - ${WEBPROC_URL} | gzip -d > /webproc \
	&& chmod 0755 /webproc
# dnsmasq configuration
RUN echo -e "ENABLED=1\nIGNORE_RESOLVCONF=yes" > /dnsmasq.default

# Stage 1: The actual produced image
FROM ${DOCKER_PREFIX}/alpine:latest
FROM alpine:edge
LABEL maintainer="Toni Corvera <outlyer@gmail.com>"
ARG ARCHITECTURE
# import webproc binary from previous stage
COPY --from=0 /webproc /usr/local/bin/
# fetch dnsmasq
RUN apk update && apk --no-cache add dnsmasq
# configure dnsmasq
RUN mkdir -p /etc/default/
COPY --from=0 /dnsmasq.default /etc/default/dnsmasq
COPY dnsmasq.conf /etc/dnsmasq.conf

# TODO: 5353/udp?
EXPOSE 80/tcp 67/udp

# run!
ENTRYPOINT ["webproc","--port","80","--config","/etc/dnsmasq.conf","--","dnsmasq","--no-daemon"]
