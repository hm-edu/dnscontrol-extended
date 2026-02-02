FROM golang:1.25.6-alpine@sha256:98e6cffc31ccc44c7c15d83df1d69891efee8115a5bb7ede2bf30a38af3e3c92
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.33.0@sha256:080c935eb42f76d15dc9f67958cd63ad02dc53a33c853d30a962bb15bc390c59
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
