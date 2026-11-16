FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.8.2@sha256:38b47d8e611e047ae7c057585ebf57987b3e2d2561bccadefc2f4202a09e4766
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
