FROM golang:1.26.6-alpine@sha256:3889b425f035be855a72fb4755265311293b6d414521f0a519d819df32222d83
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:4.46.0@sha256:0523a71981a34a14d263b893b91a447397e44188b55a98ddedd06555150bb957
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
