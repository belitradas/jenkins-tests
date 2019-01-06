FROM golang:1.11.2-alpine3.8 as builder

RUN apk add --update --no-cache git make gcc

ADD . /go/src/github.com/belitradas/jenkins-tests

WORKDIR /go/src/github.com/belitradas/jenkins-tests

RUN make build

FROM alpine:3.8

COPY --from=builder /go/src/github.com/belitradas/jenkins-tests/bin/mytests /usr/bin/mytests

EXPOSE 8080

CMD /usr/bin/mytests
