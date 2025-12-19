FROM golang:1.25.5-alpine@sha256:ac09a5f469f307e5da71e766b0bd59c9c49ea460a528cc3e6686513d64a6f1fb
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.29.0@sha256:16948fa90f22386534190cf269dd38507109f25bbc18ad2ca146b8bed360713e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
