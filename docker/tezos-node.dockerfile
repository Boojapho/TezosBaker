ARG IMAGE=tezos/tezos
ARG TAG=latest-release

# Gather libraries needed to run Tezos
FROM ${IMAGE}:${TAG} as build
WORKDIR /home/tezos
RUN mkdir lib && \
  cp -P --parents /usr/lib/libev* /usr/lib/libgmp* /usr/lib/libffi* /usr/lib/libgcc* /lib/ld-musl* lib/

# Build liveness probe
FROM golang:alpine as probe
WORKDIR /nodecheck
COPY ./probes/nodecheck/app.go .
RUN CGO_ENABLED=0 go build

# Pull only necessary files into final container
FROM gcr.io/distroless/static as final
WORKDIR /home/tezos
ENV HOME=/home/tezos
COPY --from=build --chown=root:root /home/tezos/lib /
COPY --from=build --chown=root:root /usr/share/zcash-params/* /usr/share/zcash-params/
COPY --from=build --chmod=0755 --chown=root:root /usr/local/bin/tezos-node /usr/local/bin/
COPY --from=probe --chmod=0755 --chown=root:root /nodecheck/nodecheck /usr/local/bin/
USER 42792:42792 
ENTRYPOINT ["tezos-node", "run", "--rpc-addr", "0.0.0.0:8732", "--history-mode", "experimental-rolling"]
