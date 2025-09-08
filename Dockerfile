FROM golang:1.25.1-alpine@sha256:b6ed3fd0452c0e9bcdef5597f29cc1418f61672e9d3a2f55bf02e7222c014abd
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.23.0@sha256:198e3e3d0d082bf4912951b6981a62276eba41bf521b36ce43a481c2f62b73aa
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
