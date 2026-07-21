FROM golang:1.26.5-alpine@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.43.2@sha256:401a8f8d5b18b25c202c32a0e23a28e562b69b5cab286ff134b2b335eaee2c7b
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
