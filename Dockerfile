FROM golang:1.23.1-alpine@sha256:ac67716dd016429be8d4c2c53a248d7bcdf06d34127d3dc451bda6aa5a87bc06
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.20.3@sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
