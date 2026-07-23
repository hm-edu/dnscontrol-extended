FROM golang:1.26.5-alpine@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.44.1@sha256:af53ac517f7398f7474a101912ab9333f2aa2d6e4989a89da4a1deb29128acce
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
