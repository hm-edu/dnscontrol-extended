FROM golang:1.27.1-alpine@sha256:cf6fca6641884b8433441b2b0652976f975e1d0fdd26d177eaaf8596087f3125
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.0.2@sha256:9c19d15b895c79e83f47ce94fd931ada3060d22dff9498122dd44c086fa0a7ad
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
