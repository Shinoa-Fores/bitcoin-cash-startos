# From https://github.com/ruimarinho/docker-bitcoin-cash

# Build stage for Bitcoin Cash Node (using precompiled binaries)
FROM alpine:3.21 AS bitcoin-cash

RUN sed -i 's/http:\\/\\/dl-cdn.alpinelinux.org/https:\\/\\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
        curl \
        tar

ARG ARCH
ARG PLATFORM

# Download and extract precompiled binaries
RUN if [ "$ARCH" = "x86_64" ]; then \
        curl -L https://github.com/bitcoin-cash-node/bitcoin-cash-node/releases/download/v28.0.1/bitcoin-cash-node-28.0.1-x86_64-linux-gnu.tar.gz -o bitcoin-cash-node.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        curl -L https://github.com/bitcoin-cash-node/bitcoin-cash-node/releases/download/v28.0.1/bitcoin-cash-node-28.0.1-aarch64-linux-gnu.tar.gz -o bitcoin-cash-node.tar.gz; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi

RUN tar -xzf bitcoin-cash-node.tar.gz && \
    rm bitcoin-cash-node.tar.gz

ENV BITCOIN_PREFIX=/opt/bitcoin

# Move binaries to the expected location
RUN mkdir -p ${BITCOIN_PREFIX}/bin && \
    mv bitcoin-cash-node-*/bin/* ${BITCOIN_PREFIX}/bin/ && \
    rmdir bitcoin-cash-node-*/bin && \
    rmdir bitcoin-cash-node-* && \
    strip ${BITCOIN_PREFIX}/bin/*

# Build stage for compiled artifacts
FROM alpine:3.21

LABEL maintainer.0="João Fonseca (@joaopaulofonseca)" \
  maintainer.1="Pedro Branco (@pedrobranco)" \
  maintainer.2="Rui Marinho (@ruimarinho)" \
  maintainer.3="Aiden McClelland (@dr-bonez)"

RUN sed -i 's/http:\/\/dl-cdn.alpinelinux.org/https:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
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
