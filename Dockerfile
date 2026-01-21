FROM golang:1.25.6-alpine@sha256:d9b2e14101f27ec8d09674cd01186798d227bb0daec90e032aeb1cd22ac0f029
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.31.1@sha256:e56eb8fc42706a0a6164f56092d71b0ef8cc97277a88cccc2b7552b8823cc919
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
