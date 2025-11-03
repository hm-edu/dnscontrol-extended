FROM golang:1.25.3-alpine@sha256:aee43c3ccbf24fdffb7295693b6e33b21e01baec1b2a55acc351fde345e9ec34
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.27.0@sha256:9c2ed1ca9c1bfa6372c81ac11f815fa83f1a02c0cab90c45c8c541c47eb34170
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
