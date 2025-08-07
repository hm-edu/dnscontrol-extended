FROM golang:1.24.6-alpine@sha256:c8c5f95d64aa79b6547f3b626eb84b16a7ce18a139e3e9ca19a8c078b85ba80d
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.22.0@sha256:005fae8a4eae2bf370385d618a169f9d9fcdf1baf9e523f0a13582d4cbcfd273
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
