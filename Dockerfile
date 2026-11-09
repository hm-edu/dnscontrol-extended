FROM golang:1.27.3-alpine@sha256:fa3d596898d9f126af7c01d14ee7597bab3f39cccf392ef36b69fe77cd681f18
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.8.0@sha256:3f2f34eabd12559ecf4a02a9eed5d4b9e62876779bb8b109a2f8abff5d89a35c
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
