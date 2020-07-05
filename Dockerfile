FROM alpine:latest AS devel
MAINTAINER Mose Schmiedel <mose@schmiednet.de>

RUN apk update && apk add \
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
      sqlite \
      perl-dbd-sqlite \
      perl-dbd-sqlite-dev \
      && true

WORKDIR /usr/src/coocook

COPY cpanfile .

RUN cpanm --notest --installdeps --with-recommends --with-suggests --with-develop .

COPY script/coocook_docker.pl script/coocook_docker.pl

ENTRYPOINT [ "script/coocook_docker.pl" ]

EXPOSE 3000

CMD [ "help" ]
