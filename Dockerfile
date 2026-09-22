FROM golang:1.27.1-alpine@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.1.0@sha256:f7332480bea11d4223863b96415eb94b52b4a989fbfb9220f5ad8af331fe3302
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
