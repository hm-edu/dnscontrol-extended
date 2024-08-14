FROM golang:1.23.0-alpine@sha256:44a2d64f00857d544048dd31d8e1fbd885bb90306819f4313d7bc85b87ca04b0
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.18.0@sha256:c0669ef34cdc14332c0f1ab0c2c01acb91d96014b172f1a76f3a39e63d1f0bda
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
