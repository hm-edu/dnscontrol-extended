FROM golang:1.27.1-alpine@sha256:cf6fca6641884b8433441b2b0652976f975e1d0fdd26d177eaaf8596087f3125
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.1.0@sha256:f7332480bea11d4223863b96415eb94b52b4a989fbfb9220f5ad8af331fe3302
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
