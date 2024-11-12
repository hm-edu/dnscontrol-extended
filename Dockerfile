FROM golang:1.23.3-alpine@sha256:87684d2b053f4c6fdf6c47512daef2e28a93daa123a324c85d6146c3d11c40aa
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.20.3@sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
