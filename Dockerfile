FROM crystallang/crystal:0.34.0

RUN mkdir -p /usr/local/Axentro
RUN mkdir -p /usr/local/bin

WORKDIR /usr/local/Axentro

RUN apt-get update
RUN apt-get install curl libsqlite3-dev -y

COPY . .

RUN shards build

RUN ln -s /usr/local/Axentro/bin/axen /usr/local/bin/axen
RUN ln -s /usr/local/Axentro/bin/axem /usr/local/bin/axem
RUN ln -s /usr/local/Axentro/bin/axe  /usr/local/bin/axe

EXPOSE 3000 3443
