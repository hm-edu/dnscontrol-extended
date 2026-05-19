FROM golang:1.26.3-alpine@sha256:91eda9776261207ea25fd06b5b7fed8d397dd2c0a283e77f2ab6e91bfa71079d
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.39.0@sha256:fadad27d1bb05d1a1d3cfd50a5e31ad3ad28e3dc478bbafa9036c904fb1cde72
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
