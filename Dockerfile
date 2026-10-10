FROM golang:1.27.2-alpine@sha256:f92b6ef800e499660581efdabdf25d9d817a9d124eaf900924f0504e7e27e12d
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.4.0@sha256:d8c0b2b6582012a49365fd55b626909100f7dc2785a620d7bac24120239bbcca
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
