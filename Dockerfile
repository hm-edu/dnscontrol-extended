FROM golang:1.24.4-alpine@sha256:68932fa6d4d4059845c8f40ad7e654e626f3ebd3706eef7846f319293ab5cb7a
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.21.0@sha256:e4bab292bca914ee5abd379ffb1ad305505e28a2756568df128c091b4434efc3
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
