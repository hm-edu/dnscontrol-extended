FROM golang:1.24.3-alpine@sha256:ef18ee7117463ac1055f5a370ed18b8750f01589f13ea0b48642f5792b234044
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.20.0@sha256:3159c6928b387f8c3457c623bf8056fa895bb37ff516344ad8f3df61c5126a79
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
