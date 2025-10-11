FROM golang:1.25.2-alpine@sha256:06cdd34bd531b810650e47762c01e025eb9b1c7eadd191553b91c9f2d549fae8
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.26.0@sha256:b81d7569256e5988a0ae9af48e2584a6c506b0f6605fc6c1f23bacb8fd8293b3
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
