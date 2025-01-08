FROM golang:1.23.4-alpine@sha256:13aaa4b92fd4dc81683816b4b62041442e9f685deeb848897ce78c5e2fb03af7
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.21.1@sha256:b97e2a89d0b9e4011bb88c02ddf01c544b8c781acf1f4d559e7c8f12f1047ac3
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
