FROM golang:1.27.3-alpine@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.7.1@sha256:fc673c0b06334a5d83a5ce39064fc44bd69df4c02c95f4841fed61dc37afcb7d
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
