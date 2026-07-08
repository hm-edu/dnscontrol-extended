FROM golang:1.26.5-alpine@sha256:99e12cfb19b753915f9b9fdc5a99f1869a24a69d3a0955832d5702e7fa68f1be
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.42.0@sha256:abe1d1d57d0f83f4e651a6eb4430b64e7bfd1433918aa7f4bca7bfa4be92d62e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
