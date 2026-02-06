FROM golang:1.25.7-alpine@sha256:f6751d823c26342f9506c03797d2527668d095b0a15f1862cddb4d927a7a4ced
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.33.1@sha256:a37be9904cc6871e2ed57753361a61dc65936d2aa26b1fb0e155343c006f33ba
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
