FROM golang:1.24.5-alpine@sha256:48ee313931980110b5a91bbe04abdf640b9a67ca5dea3a620f01bacf50593396
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.22.0@sha256:005fae8a4eae2bf370385d618a169f9d9fcdf1baf9e523f0a13582d4cbcfd273
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
