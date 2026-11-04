# laninfo server: small static Go binary.
# Build once while online (Go modules are downloaded), then it runs offline.
FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/laninfo .

FROM alpine:3.22
RUN apk add --no-cache tzdata && adduser -D -H -u 10001 laninfo
COPY --from=build /out/laninfo /usr/local/bin/laninfo
USER laninfo
ENV LANINFO_ADDR=:8080 \
    LANINFO_CONTENT=/data/content \
    LANINFO_DOWNLOADS=/data/downloads
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s CMD ["laninfo", "-healthcheck"]
ENTRYPOINT ["laninfo"]
