# Official and semi-official architectures: https://github.com/docker-library/official-images#architectures-other-than-amd64
# Webproc for linux is available for amd64, i386 and arm
ARCHITECTURES=amd64 armhf i386
IMAGE_NAME=outlyernet/dnsmasq-multiarch
# Dockerfile.in: Dockerfile template
DOCKERFILE_IN=Dockerfile.in

DOCKERFILES=$(addsuffix .Dockerfile,$(ARCHITECTURES))
# The colon confuses make, leave it for later
IMAGES_TARGET=$(addprefix $(IMAGE_NAME).latest-,$(ARCHITECTURES))
IMAGES=$(addprefix $(IMAGE_NAME):latest-,$(ARCHITECTURES))

RELEASE=$(shell sed -e '/ENV WEBPROC_VERSION/!d' -e 's/^[^"]*//' -e 's/"//g' Dockerfile.in)
VERSIONED_IMAGES=$(addprefix $(IMAGE_NAME):$(RELEASE)-,$(ARCHITECTURES))

# Download URLs take the form:
# https://github.com/jpillora/webproc/releases/download/$RELEASE/webproc_linux_$ARCH.gz
# e.g.
# https://github.com/jpillora/webproc/releases/download/0.2.2/webproc_linux_amd64.gz

# Translate the architecture names (resolution delayed to the actual rules)
# Docker Hub prefix:
# amd64 => amd64
# armhf => arm32v7 (XXX: Or is it arm32v5?)
# i386 => i386
#DOCKER_PREFIX=$(shell echo $* | sed -e 's/armhf/arm32v7/' -e 's/armle/arm32v5/')
DOCKER_PREFIX=$(subst armhf,arm32v7,$*)
# Webproc's architecture name:
# amd64 => amd64
# armhf => arm
# i386 => 386
WEBPROC_ARCH=$(subst armhf,arm,$(subst i386,386,$*))

all: $(DOCKERFILES) $(IMAGES_TARGET)

%.Dockerfile: $(DOCKERFILE_IN)
	sed -e 's#DOCKER_PREFIX=.*$$#DOCKER_PREFIX=$(DOCKER_PREFIX)#' \
		-e 's!ARCHITECTURE=.*$$!ARCHITECTURE=$(WEBPROC_ARCH)!' \
		-e 's/armhf architecture\./$* architecture\./' $< > $@

$(IMAGE_NAME).latest-%: %.Dockerfile
	docker build -t $(subst .,:,$@) -f $< .

# Add versioned tags to the images
tag: $(IMAGES_TARGET)
	for image in $(IMAGES); do \
		docker tag $$image `echo $$image | sed 's/latest/$(RELEASE)/g'`; \
	doneg

# Repository-specific stuff. Can only be used as-is by me

push-images: tag
	for image in $(IMAGES) $(VERSIONED_IMAGES); do \
		docker push $$image ; \
	done

# The manifest doesn't include the EXTRA images
manifest: push-images
	env DOCKER_CLI_EXPERIMENTAL=enabled \
		docker manifest create $(IMAGE_NAME):latest \
			$(IMAGES)
	env DOCKER_CLI_EXPERIMENTAL=enabled \
		docker manifest create $(IMAGE_NAME):$(RELEASE) \
			$(VERSIONED_IMAGES)	

# Forceful, but gets rid of trouble
# <https://github.com/docker/cli/issues/954>
push-manifest: manifest
	env DOCKER_CLI_EXPERIMENTAL=enabled \
		docker manifest push --purge $(IMAGE_NAME):latest
	env DOCKER_CLI_EXPERIMENTAL=enabled \
		docker manifest push --purge $(IMAGE_NAME):$(RELEASE)

push: push-manifest

distclean:
	$(RM) $(DOCKERFILES)

.PHONY: all distclean