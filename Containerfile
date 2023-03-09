FROM quay.io/zknt/alpine:3.13

# this is explicitly needed because yq v4.x only exists in this repo.
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

RUN set -x \
    && apk update \
    && apk add --no-cache \
        bash \
        git \
        git-lfs \
        jq \
        openssh \
        sed \
        yq

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
