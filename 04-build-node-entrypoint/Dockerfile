FROM node:22.23-alpine3.24

LABEL maintainer="Frederico Santos"

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
CMD ["node", "app.js"]
