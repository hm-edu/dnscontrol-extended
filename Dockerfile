FROM golang:1.27.1-alpine@sha256:cf6fca6641884b8433441b2b0652976f975e1d0fdd26d177eaaf8596087f3125
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.0.4@sha256:774b0b1cb479c5e46433f0126b852cc6e55b5d987359f978759bfbf4f415c1fe
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
