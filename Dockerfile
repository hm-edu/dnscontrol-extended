FROM golang:1.25.5-alpine@sha256:26111811bc967321e7b6f852e914d14bede324cd1accb7f81811929a6a57fea9
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.28.1@sha256:7dbc253dea8027587536957f6f4412564541402dfc6ee1ad5185f0bb597eb267
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
