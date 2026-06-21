# Build stage
FROM golang:1.24.6-bullseye AS builder

# EXPOSE 3000

WORKDIR /app

COPY app.go .

RUN go mod init main && CGO_ENABLED=0 go build -o main .

# CMD ["./main"]

# Final stage
FROM scratch

EXPOSE 3000

COPY --from=builder /app/main /go/main

CMD ["/go/main"]
