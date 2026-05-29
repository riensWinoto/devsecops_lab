FROM riens/ubi-builder:10.1-1774-go.1.26.1 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o bootstrap cmd/main.go

FROM riens/ubi-base-micro:10.1-1773
ARG CODENAME="rwinoto"
WORKDIR /app
COPY --from=builder /app/bootstrap /app/bootstrap
RUN useradd -s /bin/bash $CODENAME && chown -R $CODENAME:$CODENAME *
USER $CODENAME
ENV TZ=Asia/Jakarta
CMD ["/app/bootstrap"]