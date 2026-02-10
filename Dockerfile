FROM golang:1.26.0-alpine@sha256:d4c4845f5d60c6a974c6000ce58ae079328d03ab7f721a0734277e69905473e5
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.34.0@sha256:f0bd9ea14f58b735d1b159da46a73db740787e533b0bd11464b469254bce34ba
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
