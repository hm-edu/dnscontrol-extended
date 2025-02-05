FROM golang:1.23.6-alpine@sha256:a2624a1fc0e49583e97482907a5ec035bd722875bf5cf6498474434144ad951f
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.21.2@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
