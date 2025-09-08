FROM golang:1.25.1-alpine@sha256:b6ed3fd0452c0e9bcdef5597f29cc1418f61672e9d3a2f55bf02e7222c014abd
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.24.0@sha256:d36bacfc948bb37b1d09a465cd5c5127458cf9aa4e8226e9cbeefeb60ac40a12
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
