FROM golang:1.25.3-alpine@sha256:aee43c3ccbf24fdffb7295693b6e33b21e01baec1b2a55acc351fde345e9ec34
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.26.0@sha256:b81d7569256e5988a0ae9af48e2584a6c506b0f6605fc6c1f23bacb8fd8293b3
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
