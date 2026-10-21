FROM golang:1.27.3-alpine@sha256:f2c872bcee949b7be9c490efd02b48a8a2fbf947cdf533f1c58525ec9d8170fd
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.5.0@sha256:4218442fe20e98350aec597ba2d48e21491e6c6508664c6c79f0a9985f2af428
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
