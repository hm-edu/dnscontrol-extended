FROM golang:1.27.1-alpine@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.2.0@sha256:79136f01a2d3bc998a65a6ebf3a4f23cef593a03b8757de28ea49bbcd2d977f0
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
