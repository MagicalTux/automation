# syntax=docker/dockerfile:experimental
FROM ubuntu:18.04

# install base packages
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && apt-get clean

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libcurl4-openssl-dev libicu-dev build-essential uuid-dev libbz2-dev libc-client2007e-dev libexif-dev libgmp-dev libgraphicsmagick1-dev libgraphviz-dev libmemcached-dev libssh2-1-dev libmcrypt-dev libtidy-dev libxslt-dev libkrb5-dev libyaml-dev libzip-dev libhttp-parser-dev autoconf autoconf2.13 poppler-utils libargon2-0-dev libdjvulibre-dev libfreetype6-dev libjpeg-dev liblcms2-dev liblqr-1-0-dev libltdl-dev libopenexr-dev libpng-dev librsvg2-dev libtiff-dev libwmf-dev libxml2-dev zlib1g-dev libde265-dev libheif-dev libraw-dev liblqr-1-0-dev libdjvulibre-dev libopenexr-dev xfonts-base xfonts-75dpi fonts-takao xvfb memcached nginx postfix ntp git subversion cmake sox libsox-fmt-base libsox-fmt-mp3 faad modplug-tools gnash poppler-utils ufraw ffmpeg libsqlite3-dev libonig-dev && apt-get clean
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl crudini rsync zip jq && apt-get clean

# remove ubuntu crap
RUN echo 'APT::Periodic::Enable "0";' > /etc/apt/apt.conf.d/10cloudinit-disable
RUN DEBIAN_FRONTEND=noninteractive apt-get -y purge update-notifier-common ubuntu-release-upgrader-core landscape-common unattended-upgrades

# fix imagick & gmp
#RUN sed -i -r 's/<(.*rights="none".*)>/<!--\1-->/' /etc/ImageMagick-6/policy.xml
RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

WORKDIR /usr/src

# install wkhtmltopdf
RUN --mount=type=tmpfs,target=/usr/src wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb && dpkg -i wkhtmltox_0.12.6-1.bionic_amd64.deb

# get imagick
RUN --mount=type=tmpfs,target=/usr/src wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.0.11-6.tar.gz -O ImageMagick.tar.gz && tar xzf ImageMagick.tar.gz && cd ImageMagick-7* && ./configure --prefix=/usr --with-rsvg=yes && make && make install

# get PHP (docker will fork the cache if get_php.sh is updated)
RUN --mount=type=tmpfs,target=/usr/src wget https://raw.githubusercontent.com/MagicalTux/automation/master/get_php.sh && chmod +x get_php.sh && ./get_php.sh

WORKDIR /
CMD ["/bin/bash"]
