FROM golang:1.26.5-alpine@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.45.0@sha256:6c13cf8d8da04f8a3d3f006b848bbb42dddf79902cc6d717959d03270b8bc948
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
