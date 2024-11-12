FROM golang:1.23.3-alpine@sha256:9f68de83bef9e75cda99597d51778f4f5776ab8d9374e1094a3cd724401094c3
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM alpine:3.20.3@sha256:1e42bbe2508154c9126d48c2b8a75420c3544343bf86fd041fb7527e017a4b4a
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
