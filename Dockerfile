FROM golang:1.27.3-alpine@sha256:fa4881266890ef051f0ce63afdfaccb69bbe8186084387f4fafd60d7ecbabc71
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/dnscontrol/dnscontrol:5.7.2@sha256:5193ee23c345e07c3cd4d7c95c262db83763c18262f2d59503583e96eac97102
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
