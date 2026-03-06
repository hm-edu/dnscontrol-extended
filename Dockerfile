FROM golang:1.26.1-alpine@sha256:2389ebfa5b7f43eeafbd6be0c3700cc46690ef842ad962f6c5bd6be49ed82039
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.36.0@sha256:6e3af59bbe5402222ec5a8423bfaa49be7d91b5cdebba0bd563cf021f89fad8e
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
