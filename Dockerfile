FROM golang:1.27.1-alpine@sha256:3f6d04dc61331ee3c2fbbaad62d54412a84680f6a041d269a20a5270a078515b
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.0.2@sha256:9c19d15b895c79e83f47ce94fd931ada3060d22dff9498122dd44c086fa0a7ad
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
