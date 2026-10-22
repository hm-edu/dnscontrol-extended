FROM golang:1.27.3-alpine@sha256:d530cf60723abf1ffae0cd16bb546b379ec0550d2f3815e5b16ed69dbc00fba4
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.5.0@sha256:4218442fe20e98350aec597ba2d48e21491e6c6508664c6c79f0a9985f2af428
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
