FROM golang:1.25.6-alpine@sha256:bc2596742c7a01aa8c520a075515c7fee21024b05bfaa18bd674fe82c100a05d
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.30.0@sha256:4b786e7475591b1acc71d5ed69519c458c908d3f99ed1872fe54fc2d53a3db1d
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
