FROM golang:1.26.4-alpine@sha256:3ad57304ad93bbec8548a0437ad9e06a455660655d9af011d58b993f6f615648
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.42.0@sha256:abe1d1d57d0f83f4e651a6eb4430b64e7bfd1433918aa7f4bca7bfa4be92d62e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
