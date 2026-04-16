FROM golang:1.26.2-alpine@sha256:f85330846cde1e57ca9ec309382da3b8e6ae3ab943d2739500e08c86393a21b1
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.36.1@sha256:6863844d713b1ead915d02aedf04d0ea16cdbdc1b09d48982bdee777526f9be1
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
