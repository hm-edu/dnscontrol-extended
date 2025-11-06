FROM golang:1.25.4-alpine@sha256:d3f0cf7723f3429e3f9ed846243970b20a2de7bae6a5b66fc5914e228d831bbb
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.27.1@sha256:cc719a3434d61bfcffc24ed93154cd9682c8f4861a47385a073aaf0ac83aad2e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
