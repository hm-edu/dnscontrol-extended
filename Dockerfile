FROM golang:1.27.1-alpine@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.3.1@sha256:12914ba7b93f2d34c3e93244f4e24581ed98484d372f76ff5df4337c0199f4e8
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
