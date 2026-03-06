FROM golang:1.26.1-alpine@sha256:2389ebfa5b7f43eeafbd6be0c3700cc46690ef842ad962f6c5bd6be49ed82039
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.35.0@sha256:655bfe622a53d453886613c74a77d5f8d0c3341e3f05dea27f40bf13fde766b4
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
