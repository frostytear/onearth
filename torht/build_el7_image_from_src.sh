#!/bin/sh

set -e

SCRIPT_NAME=$(basename "$0")
TAG="$1"

if [ -z "$TAG" ]; then
  echo "Usage: ${SCRIPT_NAME} TAG" >&2
  exit 1
fi

rm -rf tmp && mkdir -p tmp

#DOCKER_UID=$(id -u)
#DOCKER_GID=$(id -g)

cat > tmp/Dockerfile <<EOS
FROM centos:7

RUN yum groupinstall -y "Development Tools"

RUN yum install -y epel-release lua-devel jansson-devel httpd-devel libpng-devel libjpeg-devel pcre-devel

RUN yum install -y luarocks redis libcurl-devel mod_proxy mod_ssl wget

RUN mkdir -p /home/oe2
RUN mkdir -p /var/www

# Clone OnEarth repo
WORKDIR /home/oe2
RUN git clone https://github.com/nasa-gibs/onearth.git
WORKDIR /home/oe2/onearth
RUN git checkout test2.0

#chown -R root:root /home/oe2

# Install mod_proxy patch
WORKDIR /tmp
RUN wget https://archive.apache.org/dist/httpd/httpd-2.4.6.tar.gz
RUN tar xf httpd-2.4.6.tar.gz
WORKDIR /tmp/httpd-2.4.6
RUN patch -p0 < /home/oe2/onearth/torht/mod_proxy_http.patch
RUN ./configure --prefix=/tmp/httpd --enable-proxy=shared --enable-proxy-balancer=shared
RUN make && make install

# Install APR patch
WORKDIR /tmp
RUN wget http://apache.osuosl.org//apr/apr-1.6.3.tar.gz
RUN tar xf apr-1.6.3.tar.gz
WORKDIR /tmp/apr-1.6.3
RUN patch  -p2 < /home/oe2/onearth/src/modules/mod_mrf/apr_FOPEN_RANDOM.patch
RUN ./configure --prefix=/lib64
RUN make && make install
# libtoolT error (rm: no such file or directory)

# Install dependencies
WORKDIR /home/oe2/onearth
RUN git submodule update --init --recursive
RUN yum-builddep -y torht/onearth.spec
RUN make download
EOS

docker build \
  --no-cache \
  --tag "$TAG" \
  tmp

rm tmp/Dockerfile
