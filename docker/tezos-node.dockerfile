ARG IMAGE=tezos/tezos
ARG TAG=latest-release

FROM ${IMAGE}:${TAG} as build
WORKDIR /home/tezos
RUN mkdir lib && \
  cp -P --parents /usr/lib/libev* /usr/lib/libgmp* /usr/lib/libffi* /usr/lib/libgcc* /lib/ld-musl* lib/

FROM gcr.io/distroless/static as final
WORKDIR /home/tezos
COPY --from=build --chown=root:root /home/tezos/lib /
COPY --from=build --chown=root:root /usr/share/zcash-params/* /usr/share/zcash-params/
COPY --from=build --chmod=0755 --chown=root:root /usr/local/bin/tezos-node /usr/local/bin/
COPY --chmod=0755 --chown=root:root ./probes/nodecheck/nodecheck /usr/local/bin/
USER 42792 
ENTRYPOINT ["tezos-node"]
