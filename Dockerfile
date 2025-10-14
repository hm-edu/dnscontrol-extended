FROM golang:1.25.3-alpine@sha256:20ee0b674f987514ae3afb295b6a2a4e5fa11de8cc53a289343bbdab59b0df59
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.26.0@sha256:b81d7569256e5988a0ae9af48e2584a6c506b0f6605fc6c1f23bacb8fd8293b3
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
