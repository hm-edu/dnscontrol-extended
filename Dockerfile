FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.10.0@sha256:6f97b376a4e4a9312bd43183103a98d9b49f283735fa91179ba67cfafba4150c
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
