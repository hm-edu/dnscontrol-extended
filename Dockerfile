FROM golang:1.25.7-alpine@sha256:81d49e1de26fa223b9ae0b4d5a4065ff8176a7d80aa5ef0bd9f2eee430afe4d7
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.33.1@sha256:a37be9904cc6871e2ed57753361a61dc65936d2aa26b1fb0e155343c006f33ba
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
