FROM golang:1.25.5-alpine@sha256:26111811bc967321e7b6f852e914d14bede324cd1accb7f81811929a6a57fea9
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.28.2@sha256:8732023ce83498fbc1b1863eb1908d3e7cbf807d438d97f5b9317b1e1f38b0f2
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
