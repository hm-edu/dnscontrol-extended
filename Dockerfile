FROM golang:1.23.5-alpine@sha256:47d337594bd9e667d35514b241569f95fb6d95727c24b19468813d596d5ae596
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.21.2@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
