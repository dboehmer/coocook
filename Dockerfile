FROM alpine
MAINTAINER Mose Schmiedel <mose.schmiedel@web.de>

RUN apk update && \
      apk add \
      pkgconf \
      musl \
      make \
      g++ \
      wget \
      perl \
      perl-dev \
      perl-app-cpanminus \
      gd-dev \
      expat-dev \
      graphviz \
      readline-dev \
      krb5-dev \
      openssl \
      openssl-dev \
      zlib-dev \
      && true

COPY ./cpanfile /usr/src/coocook/

WORKDIR /usr/src/coocook

RUN cpanm --notest --installdeps --with-recommends --with-suggests --with-develop .
