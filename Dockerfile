FROM golang:1.25.0-alpine@sha256:f18a072054848d87a8077455f0ac8a25886f2397f88bfdd222d6fafbb5bba440
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.24.0@sha256:d36bacfc948bb37b1d09a465cd5c5127458cf9aa4e8226e9cbeefeb60ac40a12
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
