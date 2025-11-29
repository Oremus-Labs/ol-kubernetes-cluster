# syntax=docker/dockerfile:1.7

ARG GO_VERSION=1.24

FROM golang:${GO_VERSION}-bookworm AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /workspace/filesystem-mcp-gateway ./...

FROM gcr.io/distroless/base-nossl:latest
WORKDIR /app
COPY --from=builder /workspace/filesystem-mcp-gateway /usr/local/bin/filesystem-mcp-gateway
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/filesystem-mcp-gateway"]
