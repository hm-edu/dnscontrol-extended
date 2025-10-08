FROM golang:1.25.2-alpine@sha256:6104e2bbe9f6a07a009159692fe0df1a97b77f5b7409ad804b17d6916c635ae5
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.25.0@sha256:02bce10d07e1bb8c34619c9fadb9d864325a7c8966eee4d3d3919e43bb18baf9
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
