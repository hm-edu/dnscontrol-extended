FROM golang:1.23.1-alpine@sha256:086ba4ead3a350230464f4cd8142f954e6b128ec8b59c1c924cba1e3a14106ae
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.20.3@sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
