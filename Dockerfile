FROM golang:1.27.1-alpine@sha256:cf6fca6641884b8433441b2b0652976f975e1d0fdd26d177eaaf8596087f3125
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.0.3@sha256:d8a79dc1f6fe0c9503a198d48bc3e379695dd18866b46361a56b37eb304eecb4
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
