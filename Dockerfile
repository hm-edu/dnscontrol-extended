FROM golang:1.25.6-alpine@sha256:d9b2e14101f27ec8d09674cd01186798d227bb0daec90e032aeb1cd22ac0f029
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.30.0@sha256:4b786e7475591b1acc71d5ed69519c458c908d3f99ed1872fe54fc2d53a3db1d
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
