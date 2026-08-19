FROM golang:1.27.0-alpine@sha256:7d5cbf6833f7331dafd25a2e8b9673477f559759ff8ed4ca8efabe6795ad08db
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.46.0@sha256:0523a71981a34a14d263b893b91a447397e44188b55a98ddedd06555150bb957
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
