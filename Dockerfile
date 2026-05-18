FROM golang:1.26.3-alpine@sha256:91eda9776261207ea25fd06b5b7fed8d397dd2c0a283e77f2ab6e91bfa71079d
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.38.0@sha256:111a2a920f1b496ef360c29898d452aef4b18497777e1e12268d53d459ec4e8c
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
