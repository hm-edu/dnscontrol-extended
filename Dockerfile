FROM golang:1.25.7-alpine@sha256:f6751d823c26342f9506c03797d2527668d095b0a15f1862cddb4d927a7a4ced
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.34.0@sha256:f0bd9ea14f58b735d1b159da46a73db740787e533b0bd11464b469254bce34ba
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
