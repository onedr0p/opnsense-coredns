FROM docker.io/golang:1.17.5-alpine as build
# TODO: Renovate CoreDNS version
ENV COREDNS_VERSION=v1.8.6
# TODO: Renovate k8s_gateway version
ENV K8S_GATEWAY_VERSION=v0.1.8
ENV CGO_ENABLED=0 \
    GOPATH=/go \
    GOBIN=/go/bin \
    GO111MODULE=on
WORKDIR /go/src/coredns
RUN \
    apk --no-cache --no-progress add ca-certificates git \
    && update-ca-certificates
RUN \
    git clone https://github.com/coredns/coredns.git --branch "v1.8.6" --depth 1 --single-branch . \
    && sed -i '/^kubernetes:kubernetes/a k8s_gateway:github.com/ori-edge/k8s_gateway' plugin.cfg
RUN \
    go get github.com/ori-edge/k8s_gateway@${K8S_GATEWAY_VERSION} \
    && go generate \
    && go mod tidy
ENV GOOS=freebsd \
    GOARCH=amd64
RUN \
    go build -ldflags "-s -w -X github.com/coredns/coredns/coremain.GitCommit=$(git describe --always)" -o coredns

FROM scratch
COPY --from=build /go/src/coredns/coredns /coredns
ENTRYPOINT ["/coredns"]
