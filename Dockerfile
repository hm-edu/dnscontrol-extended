FROM golang:1.24.5-alpine@sha256:daae04ebad0c21149979cd8e9db38f565ecefd8547cf4a591240dc1972cf1399
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . ./

RUN CGO_ENABLED=0 GOOS=linux go build -o dnscontrol-extended

FROM ghcr.io/stackexchange/dnscontrol:4.23.0@sha256:198e3e3d0d082bf4912951b6981a62276eba41bf521b36ce43a481c2f62b73aa
COPY --from=0 /app/dnscontrol-extended /usr/local/bin/dnscontrol-extended
