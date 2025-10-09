FROM golang:1.25.2-alpine@sha256:a86c313035ea07727c53a9037366a63c2216f3c5690c613179f37ee33ea71301
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.25.0@sha256:02bce10d07e1bb8c34619c9fadb9d864325a7c8966eee4d3d3919e43bb18baf9
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
