FROM golang:1.27.1-alpine@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.3.0@sha256:4cd79431f882e2a900635f20a83cc400ea85e08a1d8441f4cfba7110887a420b
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
