FROM golang:1.25.5-alpine@sha256:72567335df90b4ed71c01bf91fb5f8cc09fc4d5f6f21e183a085bafc7ae1bec8
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.28.2@sha256:8732023ce83498fbc1b1863eb1908d3e7cbf807d438d97f5b9317b1e1f38b0f2
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
