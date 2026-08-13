FROM golang:1.26.6-alpine@sha256:af8d6740070b8906d12eae1c3e3ea0957fb63f492051ea05e354c38ef9fe88df
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.46.0@sha256:0523a71981a34a14d263b893b91a447397e44188b55a98ddedd06555150bb957
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
