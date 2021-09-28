# docker build -t msoap/shell2http .

# build image
FROM golang:alpine as go_builder
RUN apk update
RUN apk add --no-cache git
RUN apk add tar

WORKDIR /builder
RUN git clone https://github.com/msoap/shell2http.git /builder
ENV CGO_ENABLED=0
RUN go install -a -v -ldflags="-w -s" ./...

# final image
FROM alpine

RUN apk add --no-cache libxslt

# Create an 'app' user, so we don't run the install as root. 
# There could potentially be malicious code in the package manager repo
RUN addgroup -g 1000 app \
    && adduser -u 1000 -G app -s /bin/sh -D app

# Create the working folder and change owner
WORKDIR /wrk
RUN chown -R app:app /wrk
USER app

COPY --from=go_builder /go/bin/shell2http /app/shell2http
ENTRYPOINT ["/app/shell2http"]

EXPOSE 8080

CMD ["/flatten", "xsltproc '/wrk/flatten.xsl' '/wrk/target.xml'", "/unpack", "tar -xvf '/wrk/target.tar'"]