FROM golang:1.24.3-alpine@sha256:b4f875e650466fa0fe62c6fd3f02517a392123eea85f1d7e69d85f780e4db1c1
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.21.0@sha256:e4bab292bca914ee5abd379ffb1ad305505e28a2756568df128c091b4434efc3
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
