FROM golang:1.25.5-alpine@sha256:72567335df90b4ed71c01bf91fb5f8cc09fc4d5f6f21e183a085bafc7ae1bec8
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.29.0@sha256:16948fa90f22386534190cf269dd38507109f25bbc18ad2ca146b8bed360713e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
