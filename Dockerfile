FROM golang:1.25.2-alpine@sha256:8280f72610be84e514284bc04de455365d698128e0aaea4e12e06c9b320b58ec
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.25.0@sha256:02bce10d07e1bb8c34619c9fadb9d864325a7c8966eee4d3d3919e43bb18baf9
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
