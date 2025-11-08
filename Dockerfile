FROM golang:1.25-alpine AS builder

ARG CMD_PATH=./cmd/
ENV CGO_ENABLED=0

WORKDIR /app

COPY . .

RUN go mod download
RUN go build -o binary ${CMD_PATH}

RUN apk add -U --no-cache ca-certificates

FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/binary /

EXPOSE 8080
ENTRYPOINT ["/binary"]