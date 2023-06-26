FROM docker:latest

RUN apk update && apk add --no-cache go make git

COPY /release.mk /
RUN GO=go make --makefile=/release.mk install-goreleaser \
    && rm -rf /root/go/pkg
ENV PATH /root/go/bin:$PATH

COPY release.sh /

CMD ["/release.sh"]
