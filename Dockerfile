FROM node:lts-alpine as templating

ENV WORKDIR=/template \
    # Used in template to invalidate caches - do not remove. The release script will auto update this line
    VERSION="1.26.1-7"

RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

COPY theme-build ${WORKDIR}/
COPY resources ${WORKDIR}/resources

RUN yarn install
RUN node template-colors.js  ${WORKDIR}/resources/var/www/html/styles/default.css.tpl ${WORKDIR}/build/default.css
RUN node template-error-pages.js ${WORKDIR}/resources/var/www/html/errors/error-page.html.tpl ${WORKDIR}/build/errors


FROM registry.cloudogu.com/official/base:3.20.2-1 as builder

# dockerfile is based on https://github.com/dockerfile/nginx and https://github.com/bellycard/docker-loadbalancer
ENV NGINX_VERSION 1.26.1
ENV NGINX_TAR_SHA256="f9187468ff2eb159260bfd53867c25ff8e334726237acf227b9e870e53d3e36b"

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

FROM registry.cloudogu.com/official/base:3.20.2-1
LABEL maintainer="hello@cloudogu.com" \
      NAME="nginx-static" \
      VERSION="1.26.1-7"

ENV WARP_MENU_VERSION=2.0.0 \
    WARP_MENU_TAR_SHA256="51a1010ec0f82b634999e48976d7fec98e6eb574a4401a841cd53f8cd0e14040" \
    CES_ABOUT_VERSION=0.2.2 \
    CES_ABOUT_TAR_SHA256="9926649be62d8d4667b2e7e6d1e3a00ebec1c4bbc5b80a0e830f7be21219d496" \
    SERVICE_TAGS="webapp" \
    SERVICE_LOCATION="/" \
    SERVICE_PASS="/" \
    # Used in template to invalidate caches - do not remove. The release script will auto update this line
    VERSION="1.26.1-7"


# Install required packages
RUN apk upgrade \
    && apk --update add \
        openssl \
        pcre \
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

 # redirect logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# cleanup apk cache
RUN rm -rf /var/cache/apk/*

# copy files
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

# copy files
COPY resources /

# copy templated files
COPY --from=templating /template/build/default.css /var/www/html/styles/default.css
COPY --from=templating /template/build/errors /var/www/html/errors

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
