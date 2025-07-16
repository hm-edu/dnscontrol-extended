FROM golang:1.24.4-alpine@sha256:68932fa6d4d4059845c8f40ad7e654e626f3ebd3706eef7846f319293ab5cb7a
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.22.0@sha256:005fae8a4eae2bf370385d618a169f9d9fcdf1baf9e523f0a13582d4cbcfd273
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
