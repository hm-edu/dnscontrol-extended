FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.9.0@sha256:403c5a7fd359f3ed11e07ea3117a01855985d4f2f657ed2f8b855f08a2bd4e15
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
