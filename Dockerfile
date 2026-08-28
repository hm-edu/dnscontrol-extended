FROM golang:1.27.0-alpine@sha256:4c9fe60190a2a3350ddc51de80d0224b8a6698d12bdfc999fee45ea9d6c46dbc
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.0.2@sha256:9c19d15b895c79e83f47ce94fd931ada3060d22dff9498122dd44c086fa0a7ad
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
