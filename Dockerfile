FROM golang:1.27.3-alpine@sha256:b8c9b82affbbb82a020bbcf998dad2ba9516944ac7e883524642a481a9505e9c
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.7.0@sha256:3e9a437215d088a35ff128d1616d1b3ee0c3c1303aff21d0ea32d3e8505ca82a
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
