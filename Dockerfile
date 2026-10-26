FROM golang:1.27.3-alpine@sha256:b8c9b82affbbb82a020bbcf998dad2ba9516944ac7e883524642a481a9505e9c
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.7.1@sha256:fc673c0b06334a5d83a5ce39064fc44bd69df4c02c95f4841fed61dc37afcb7d
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
