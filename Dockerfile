FROM golang:1.25.6-alpine@sha256:d9b2e14101f27ec8d09674cd01186798d227bb0daec90e032aeb1cd22ac0f029
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.32.0@sha256:099af0a3a7ff30ea82f389873ec44a03f0bbe5eb3c250b37a780f53d78f21651
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
