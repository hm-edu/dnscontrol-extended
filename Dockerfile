FROM golang:1.26.3-alpine@sha256:91eda9776261207ea25fd06b5b7fed8d397dd2c0a283e77f2ab6e91bfa71079d
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.40.0@sha256:0e6acd492b2c08a4823ea7d8db1ceab0bf78b9c0bb1529ce65baa4322bbec8a9
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
