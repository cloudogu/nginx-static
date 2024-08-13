FROM registry.cloudogu.com/official/base:3.15.8-1 as builder

# dockerfile is based on https://github.com/dockerfile/nginx and https://github.com/bellycard/docker-loadbalancer
ENV NGINX_VERSION 1.23.1
ENV NGINX_TAR_SHA256="5eee1bd1c23e3b9477a45532f1f36ae6178b43d571a9607e6953cef26d5df1e2"

COPY nginx-build /
RUN set -x -o errexit \
    && set -o nounset \
    && set -o pipefail \
    && apk update \
    && apk upgrade \
    && apk --update add openssl-dev pcre-dev zlib-dev wget build-base \
    && mkdir /build \
    && cd /build \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && echo "${NGINX_TAR_SHA256} *nginx-${NGINX_VERSION}.tar.gz" | sha256sum -c - \
    && tar -zxvf nginx-${NGINX_VERSION}.tar.gz \
    && cd /build/nginx-${NGINX_VERSION} \
    && /build.sh \
    && rm -rf /var/cache/apk/* /build

FROM registry.cloudogu.com/official/base:3.15.8-1
LABEL maintainer="hello@cloudogu.com" \
      NAME="nginx-static" \
      VERSION="1.23.1-8"

ENV WARP_MENU_VERSION=1.7.3 \
    WARP_MENU_TAR_SHA256="b3ed4b50b1b9a739a4430d88975b5e3030c5e542c0739ed6b72d7eb8fd9a7b18" \
    CES_ABOUT_VERSION=0.2.2 \
    CES_ABOUT_TAR_SHA256="9926649be62d8d4667b2e7e6d1e3a00ebec1c4bbc5b80a0e830f7be21219d496" \
    CES_THEME_VERSION=v0.7.1 \
    CES_THEME_TAR_SHA256="201013e417aad19572df5c5f6f9fb7053323cadb0d555da55541b1d27c2ef699" \
    SERVICE_TAGS="webapp" \
    SERVICE_LOCATION="/" \
    SERVICE_PASS="/"

# Install required packages
RUN apk upgrade \
    && apk --update add \
        openssl \
        pcre \
        libcrypto1.1 \
        libssl1.1 \
        musl \
        zlib

 # add nginx user
RUN adduser nginx -D

# prepare folders
RUN set -x \
 && mkdir -p /var/www/html \
 && mkdir -p /var/www/html/customhtml \
 && mkdir -p /var/log/nginx

# install ces-about page
RUN wget https://github.com/cloudogu/ces-about/releases/download/v${CES_ABOUT_VERSION}/ces-about-v${CES_ABOUT_VERSION}.tar.gz -q -O ces-about-v${CES_ABOUT_VERSION}.tar.gz \
 && echo "${CES_ABOUT_TAR_SHA256} *ces-about-v${CES_ABOUT_VERSION}.tar.gz" | sha256sum -c - \
 && tar -xzvf ces-about-v${CES_ABOUT_VERSION}.tar.gz -C /var/www/html \
 && sed -i 's@base href=".*"@base href="/info/"@' /var/www/html/info/index.html

# install warp menu
RUN wget https://github.com/cloudogu/warp-menu/releases/download/v${WARP_MENU_VERSION}/warp-v${WARP_MENU_VERSION}.zip -q -O /tmp/warp.zip \
 && echo "${WARP_MENU_TAR_SHA256} */tmp/warp.zip" | sha256sum -c - \
 && unzip /tmp/warp.zip -d /var/www/html

 # install custom error pages
RUN wget https://github.com/cloudogu/ces-theme/archive/${CES_THEME_VERSION}.zip -q -O /tmp/theme.zip \
 && echo "${CES_THEME_TAR_SHA256} */tmp/theme.zip" | sha256sum -c - \
 && mkdir /var/www/html/errors \
 && unzip /tmp/theme.zip -d /tmp/theme \
 && mv /tmp/theme/ces-theme-*/dist/errors/* /var/www/html/errors \
 && rm -rf /tmp/theme.zip /tmp/theme

 # redirect logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# cleanup apk cache
RUN rm -rf /var/cache/apk/*

# copy files
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

# copy files
COPY resources /

# Volumes are used to avoid writing to containers writable layer https://docs.docker.com/storage/
# Compared to the bind mounted volumes we declare in the dogu.json,
# the volumes declared here are not mounted to the dogu if the container is destroyed/recreated,
# e.g. after a dogu upgrade
VOLUME ["/etc/nginx/app.conf.d", "/var/www/html"]

# Define working directory.
WORKDIR /etc/nginx

# Expose ports.
EXPOSE 80

# Define default command.
ENTRYPOINT ["/startup.sh"]
