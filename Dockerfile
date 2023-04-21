# syntax=docker/dockerfile:1

FROM golang:1.20
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM scratch
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
