FROM golang:1.27.2-alpine@sha256:85dc1069ac644ea3c527b177303a406eb3358192816cd7f9e5848eb658851673
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.3.1@sha256:12914ba7b93f2d34c3e93244f4e24581ed98484d372f76ff5df4337c0199f4e8
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
