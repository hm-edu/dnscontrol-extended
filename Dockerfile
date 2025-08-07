FROM golang:1.24.6-alpine@sha256:c8c5f95d64aa79b6547f3b626eb84b16a7ce18a139e3e9ca19a8c078b85ba80d
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.23.0@sha256:198e3e3d0d082bf4912951b6981a62276eba41bf521b36ce43a481c2f62b73aa
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
