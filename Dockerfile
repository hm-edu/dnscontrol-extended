FROM golang:1.25.3-alpine@sha256:aee43c3ccbf24fdffb7295693b6e33b21e01baec1b2a55acc351fde345e9ec34
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.27.1@sha256:cc719a3434d61bfcffc24ed93154cd9682c8f4861a47385a073aaf0ac83aad2e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
