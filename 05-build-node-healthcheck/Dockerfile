FROM node:22.23-alpine3.24

LABEL maintainer="Frederico Santos"

RUN apk add --no-cache wget

VOLUME ["/var/nodeapp"]

RUN adduser -h /var/nodeapp -s /bin/sh -D nodeapp

WORKDIR /var/nodeapp

COPY app.js .
RUN chown -R nodeapp:nodeapp /var/nodeapp

ARG PORT=3000
ENV PORT=${PORT}

EXPOSE ${PORT}

ARG VERSION=1.0.0
ENV VERSION=${VERSION}

USER nodeapp

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider "http://localhost:${PORT}/" || exit 1

ENTRYPOINT ["node"]
CMD ["app.js"]