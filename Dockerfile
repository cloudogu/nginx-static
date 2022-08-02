FROM nginx:1.23.1

LABEL maintainer="hello@cloudogu.com" \
      NAME="k8s-static-webserver" \
      VERSION="0.0.0"

ENV WARP_MENU_VERSION=1.5.0 \
    WARP_MENU_TAR_SHA256="cfdd504a03aab8e5e4a33135d953b10aeba4816da5f549ddb1eb6ee593399826" \
    CES_ABOUT_VERSION=0.2.2 \
    CES_ABOUT_TAR_SHA256="9926649be62d8d4667b2e7e6d1e3a00ebec1c4bbc5b80a0e830f7be21219d496" \
    CES_THEME_VERSION=v0.7.0 \
    CES_THEME_TAR_SHA256="d3c8ba654cdaccff8fa3202f3958ac0c61156fb25a288d6008354fae75227941"

# Install required packages
RUN apt-get update && apt-get install -y \
  unzip \
  && rm -rf /var/lib/apt/lists/*

# prepare folders
RUN set -x \
 && mkdir -p /usr/share/nginx/html \
 && mkdir -p /usr/share/nginx/customhtml

# install ces-about page
RUN curl -Lsk https://github.com/cloudogu/ces-about/releases/download/v${CES_ABOUT_VERSION}/ces-about-v${CES_ABOUT_VERSION}.tar.gz -o ces-about-v${CES_ABOUT_VERSION}.tar.gz \
 && echo "${CES_ABOUT_TAR_SHA256} *ces-about-v${CES_ABOUT_VERSION}.tar.gz" | sha256sum -c - \
 && tar -xzvf ces-about-v${CES_ABOUT_VERSION}.tar.gz -C /usr/share/nginx/html \
 && sed -i 's@base href=".*"@base href="/info/"@' /usr/share/nginx/html/info/index.html

# install warp menu
RUN curl -Lsk https://github.com/cloudogu/warp-menu/releases/download/v${WARP_MENU_VERSION}/warp-v${WARP_MENU_VERSION}.zip -o /tmp/warp.zip \
 && echo "${WARP_MENU_TAR_SHA256} */tmp/warp.zip" | sha256sum -c - \
 && unzip /tmp/warp.zip -d /usr/share/nginx/html

 # install custom error pages
RUN curl -Lsk https://github.com/cloudogu/ces-theme/archive/${CES_THEME_VERSION}.zip -o /tmp/theme.zip \
 && echo "${CES_THEME_TAR_SHA256} */tmp/theme.zip" | sha256sum -c - \
 && mkdir /usr/share/nginx/html/errors \
 && unzip /tmp/theme.zip -d /tmp/theme \
 && mv /tmp/theme/ces-theme-*/dist/errors/* /usr/share/nginx/html/errors \
 && rm -rf /tmp/theme.zip /tmp/theme

# copy files
COPY resources /

# Volumes are used to avoid writing to containers writable layer https://docs.docker.com/storage/
# Compared to the bind mounted volumes we declare in the dogu.json,
# the volumes declared here are not mounted to the dogu if the container is destroyed/recreated,
# e.g. after a dogu upgrade
VOLUME ["/etc/nginx/app.conf.d"]

# Define working directory.
WORKDIR /etc/nginx

HEALTHCHECK CMD curl -f http://localhost:443 || exit 1

# Expose ports.
EXPOSE 80
EXPOSE 443

# Define default command.
ENTRYPOINT ["/startup.sh"]
