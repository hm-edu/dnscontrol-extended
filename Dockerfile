FROM golang:1.27.4-alpine@sha256:0a5f7fe796599ff487605987432e7619ae45beeb2fba4c2ce0b907879932aebf
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.8.0@sha256:3f2f34eabd12559ecf4a02a9eed5d4b9e62876779bb8b109a2f8abff5d89a35c
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
