FROM node:22.23-alpine3.24

LABEL maintainer="Frederico Santos"

HEALTHCHECK --interval=30s --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT:-3000}/ || exit 1

VOLUME ["/var/nodeapp"]

# RUN mkdir /var/node
RUN adduser -h /var/nodeapp -s /bin/sh -D nodeapp

WORKDIR /var/nodeapp

COPY app.js .
RUN chown -R nodeapp:nodeapp /var/nodeapp

ARG PORT
ENV PORT=${PORT:-3000}

EXPOSE ${PORT}

ARG VERSION
ENV VERSION=${VERSION:-1.0.0}

USER nodeapp

ENTRYPOINT [ "node" ]
CMD ["app.js"]
