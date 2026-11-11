FROM golang:1.27.4-alpine@sha256:0a5f7fe796599ff487605987432e7619ae45beeb2fba4c2ce0b907879932aebf
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.8.1@sha256:95125480ee7487393edc33b13985460e46c3a81ab3002c1098cb31399d104b4c
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
