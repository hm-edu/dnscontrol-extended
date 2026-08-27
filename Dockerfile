FROM golang:1.27.0-alpine@sha256:4c9fe60190a2a3350ddc51de80d0224b8a6698d12bdfc999fee45ea9d6c46dbc
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.0.0@sha256:08d40a1942ebf5f405198875bcaa3227a67454d5b48e1f922b745158aeb7fae9
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
