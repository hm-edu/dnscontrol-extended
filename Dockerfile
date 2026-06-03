FROM golang:1.26.4-alpine@sha256:f23e8b227fb4493eabe03bede4d5a32d04092da71962f1fb79b5f7d1e6c2a17f
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.41.0@sha256:8c52ff393fea1d3471268cfbd2c6fdd1bd310eb9df9a6a78dfb22a0b28d90b57
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
