# From https://github.com/ruimarinho/docker-bitcoin-cash

# Build stage for BerkeleyDB
ARG PLATFORM

FROM lncm/berkeleydb:db-4.8.30.NC-${PLATFORM} AS berkeleydb

# Build stage for Bitcoin Core
FROM alpine:3.21 AS bitcoin-cash

COPY --from=berkeleydb /opt /opt

RUN sed -i 's/http\\:\\/\\/dl-cdn.alpinelinux.org/https\\:\\/\\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
        git \
        boost-dev \
        cmake \
        libevent-dev \
        openssl-dev \
        build-base \
        py3-pip \
        db-dev \
        miniupnpc-dev \
        zeromq-dev \
        help2man \
        bash
RUN pip install ninja

ADD ./bitcoin-cash-node /bitcoin

ENV BITCOIN_PREFIX=/opt/bitcoin

WORKDIR /bitcoin

# Create build directory and build using cmake/ninja
RUN mkdir build && \
    cd build && \
    cmake -GNinja .. -DBUILD_BITCOIN_WALLET=OFF -DBUILD_BITCOIN_QT=OFF -DENABLE_UPNP=OFF && \
    ninja && \
    mkdir -p ${BITCOIN_PREFIX}/bin && \
    cp src/bitcoind src/bitcoin-cli src/bitcoin-tx ${BITCOIN_PREFIX}/bin/ && \
    cd .. && \
    rm -rf build

RUN strip ${BITCOIN_PREFIX}/bin/*

# Build stage for compiled artifacts
FROM alpine:3.21

LABEL maintainer.0="João Fonseca (@joaopaulofonseca)" \
  maintainer.1="Pedro Branco (@pedrobranco)" \
  maintainer.2="Rui Marinho (@ruimarinho)" \
  maintainer.3="Aiden McClelland (@dr-bonez)"

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  bash \
  curl \
  libevent \
  libzmq \
  sqlite-dev \
  tini \
  yq
RUN rm -rf /var/cache/apk/*

ARG ARCH

ENV BITCOIN_DATA=/root/.bitcoin
ENV BITCOIN_PREFIX=/opt/bitcoin
ENV PATH=${BITCOIN_PREFIX}/bin:$PATH

COPY --from=bitcoin-cash /opt /opt
COPY ./manager/target/${ARCH}-unknown-linux-musl/release/bitcoind-manager \
     ./docker_entrypoint.sh \
     ./actions/reindex.sh \
     ./actions/reindex_chainstate.sh \
     ./check-rpc.sh \
     ./check-synced.sh \
     /usr/local/bin/

RUN chmod a+x /usr/local/bin/bitcoind-manager \
    /usr/local/bin/*.sh

EXPOSE 8332 8333

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
