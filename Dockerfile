FROM golang:1.27.2-alpine@sha256:f92b6ef800e499660581efdabdf25d9d817a9d124eaf900924f0504e7e27e12d
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.5.0@sha256:4218442fe20e98350aec597ba2d48e21491e6c6508664c6c79f0a9985f2af428
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
