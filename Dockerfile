FROM golang:1.23.1-alpine@sha256:086ba4ead3a350230464f4cd8142f954e6b128ec8b59c1c924cba1e3a14106ae
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.20.2@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
