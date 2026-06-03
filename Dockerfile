FROM golang:1.26.4-alpine@sha256:162b257ae1156df92d48e2de5abe69f657fc4961f0ea0e5376837a9ffed8160b
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.41.0@sha256:8c52ff393fea1d3471268cfbd2c6fdd1bd310eb9df9a6a78dfb22a0b28d90b57
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
