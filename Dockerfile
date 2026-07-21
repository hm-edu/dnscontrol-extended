FROM golang:1.26.5-alpine@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.43.3@sha256:a5531c79d61c9b461e446f3793c8abb3237bc85bd11f285a014fca08978eec0d
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
