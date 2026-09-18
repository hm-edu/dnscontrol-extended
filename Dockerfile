FROM golang:1.27.1-alpine@sha256:4cb7ac979db5fcc41cae44b2227ba5ab8a51e8807f40d9ba4dee20a0ad960b5b
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.1.0@sha256:f7332480bea11d4223863b96415eb94b52b4a989fbfb9220f5ad8af331fe3302
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
