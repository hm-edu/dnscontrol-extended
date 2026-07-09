FROM golang:1.26.5-alpine@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.42.0@sha256:abe1d1d57d0f83f4e651a6eb4430b64e7bfd1433918aa7f4bca7bfa4be92d62e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
