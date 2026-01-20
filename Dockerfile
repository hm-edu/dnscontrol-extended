FROM golang:1.25.6-alpine@sha256:d9b2e14101f27ec8d09674cd01186798d227bb0daec90e032aeb1cd22ac0f029
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.31.0@sha256:81a2becaca042e672124ed6275d73c5049937724b6c9bf1d8f70e819811166fb
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
