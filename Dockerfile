FROM golang:1.25.5-alpine@sha256:3587db7cc96576822c606d119729370dbf581931c5f43ac6d3fa03ab4ed85a10
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.27.1@sha256:cc719a3434d61bfcffc24ed93154cd9682c8f4861a47385a073aaf0ac83aad2e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
