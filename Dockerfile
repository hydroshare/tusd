FROM golang:1.17.6-bullseye AS builder
WORKDIR /go/src/github.com/tus/tusd

# Add gcc and libc-dev early so it is cached
RUN set -xe \
	&& apt-get install -y gcc libc-dev

# Install dependencies earlier so they are cached between builds
COPY go.mod go.sum ./
RUN set -xe \
	&& go mod download

# Copy the source code, because directories are special, there are separate layers
COPY cmd/ ./cmd/
COPY internal/ ./internal/
COPY pkg/ ./pkg/

# Get the version name and git commit as a build argument
ARG GIT_VERSION
ARG GIT_COMMIT

RUN set -xe \
	&& GOOS=linux GOARCH=amd64 go build \
        -ldflags="-X github.com/tus/tusd/cmd/tusd/cli.VersionName=${GIT_VERSION} -X github.com/tus/tusd/cmd/tusd/cli.GitCommit=${GIT_COMMIT} -X 'github.com/tus/tusd/cmd/tusd/cli.BuildDate=$(date --utc)'" \
        -o /go/bin/tusd ./cmd/tusd/main.go

# start a new stage that copies in the binary built in the previous stage
FROM debian:bullseye-slim

WORKDIR /srv/tusd-data

RUN apt-get update \
    && apt-get install -y ca-certificates jq
RUN addgroup --gid 1000 tusd
RUN adduser --uid 1000 --ingroup tusd --shell /bin/sh --disabled-password --no-create-home --gecos 'tus user' tusd 
RUN mkdir -p /srv/tusd-hooks \
    && chown tusd:tusd /srv/tusd-data

COPY --from=builder /go/bin/tusd /usr/local/bin/tusd

EXPOSE 1080
USER tusd

ENTRYPOINT ["tusd"]
CMD [ "--hooks-dir", "/srv/tusd-hooks" ]
