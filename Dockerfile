FROM golang:1.23.0-alpine@sha256:d0b31558e6b3e4cc59f6011d79905835108c919143ebecc58f35965bf79948f4
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.18.0@sha256:c0669ef34cdc14332c0f1ab0c2c01acb91d96014b172f1a76f3a39e63d1f0bda
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
