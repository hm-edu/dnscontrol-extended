FROM golang:1.23.4-alpine@sha256:04ec5618ca64098b8325e064aa1de2d3efbbd022a3ac5554d49d5ece99d41ad5
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.21.2@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
