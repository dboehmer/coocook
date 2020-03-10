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
      sqlite \
      perl-dbd-sqlite \
      perl-dbd-sqlite-dev \
      git \
      && true

WORKDIR /usr/src

RUN git clone https://github.com/dboehmer/coocook.git

WORKDIR /usr/src/coocook

RUN cpanm --notest --installdeps --with-recommends --with-suggests --with-develop .

EXPOSE 3000

RUN ./script/coocook_deploy.pl install

CMD ./script/coocook_server.pl --debug -r
