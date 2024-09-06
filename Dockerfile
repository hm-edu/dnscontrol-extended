FROM golang:1.23.1-alpine@sha256:d6e18ebe13069f99c831d1024803779bee93277d586048652de9f8f017a44693
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.20.2@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
