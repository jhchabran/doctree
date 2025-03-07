
###############################
# Build the doctree Go binary #
###############################
FROM docker.io/library/golang:1.18 as builder

COPY . /doctree
ENV GOBIN /out
RUN cd /doctree && CGO_ENABLED=0 go install ./cmd/doctree

# Dockerfile based on guidelines at https://github.com/hexops/dockerfile
FROM alpine:3.15

# Non-root user for security purposes.
#
# UIDs below 10,000 are a security risk, as a container breakout could result
# in the container being ran as a more privileged user on the host kernel with
# the same UID.
#
# Static GID/UID is also useful for chown'ing files outside the container where
# such a user does not exist.
RUN addgroup --gid 10001 --system nonroot \
    && adduser  --uid 10000 --system --ingroup nonroot --home /home/nonroot nonroot

# Copy Go binary from builder image
COPY --from=builder /out/ /sbin

# Create data volume.
RUN mkdir -p /home/nonroot/data
VOLUME /home/nonroot/data

# Tini allows us to avoid several Docker edge cases, see https://github.com/krallin/tini.
# NOTE: See https://github.com/hexops/dockerfile#is-tini-still-required-in-2020-i-thought-docker-added-it-natively
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--", "doctree"]

# bind-tools is needed for DNS resolution to work in *some* Docker networks, but not all.
# This applies to nslookup, Go binaries, etc. If you want your Docker image to work even
# in more obscure Docker environments, use this.
RUN apk add --no-cache bind-tools

# Use the non-root user to run our application
USER nonroot

# Default arguments for your app (remove if you have none):
EXPOSE 8080
CMD ["serve"]

