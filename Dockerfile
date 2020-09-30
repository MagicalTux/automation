FROM ubuntu:18.04

# install base packages
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libcurl4-openssl-dev libicu-dev build-essential uuid-dev libbz2-dev libc-client2007e-dev libexif-dev libgmp-dev libgraphicsmagick1-dev libgraphviz-dev libmemcached-dev libssh2-1-dev libmcrypt-dev libtidy-dev libxslt-dev libkrb5-dev libyaml-dev libzip-dev libhttp-parser-dev autoconf autoconf2.13 poppler-utils libargon2-0-dev libdjvulibre-dev libfreetype6-dev libjpeg-dev liblcms2-dev liblqr-1-0-dev libltdl-dev libopenexr-dev libpng-dev librsvg2-dev libtiff-dev libwmf-dev libxml2-dev zlib1g-dev libde265-dev libheif-dev libraw-dev liblqr-1-0-dev libdjvulibre-dev libopenexr-dev xfonts-base xfonts-75dpi fonts-takao xvfb memcached nginx postfix ntp git subversion cmake sox libsox-fmt-base libsox-fmt-mp3 faad modplug-tools gnash poppler-utils ufraw ffmpeg libsqlite3-dev libonig-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl crudini rsync

# fix imagick & gmp
#RUN sed -i -r 's/<(.*rights="none".*)>/<!--\1-->/' /etc/ImageMagick-6/policy.xml
RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

# install wkhtmltopdf
ADD https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb /usr/src
RUN dpkg -i /usr/src/wkhtmltox_0.12.6-1.bionic_amd64.deb

# get imagick
ADD https://github.com/ImageMagick/ImageMagick/archive/7.0.8-23.tar.gz /usr/src/ImageMagick.tar.gz
RUN cd /usr/src && tar xzf ImageMagick.tar.gz && cd ImageMagick-7* && ./configure --prefix=/usr --with-rsvg=yes && make && make install

# get PHP (docker will fork the cache if get_php.sh is updated)
ADD https://raw.githubusercontent.com/MagicalTux/automation/master/get_php.sh /usr/src/get_php.sh
RUN cd /usr/src && chmod +x get_php.sh && ./get_php.sh

CMD ["/bin/sh"]
