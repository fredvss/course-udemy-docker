FROM python:3.12-alpine

LABEL maintainer="Frederico Santos"

RUN apk add --no-cache wget

RUN adduser -h /flaskapp -s /bin/sh -D pythonapp

WORKDIR /flaskapp

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
RUN chown -R pythonapp:pythonapp /flaskapp

ARG PORT=5000
ENV PORT=${PORT}

EXPOSE ${PORT}

ARG VERSION=1.0.0
ENV VERSION=${VERSION}

USER pythonapp

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider "http://localhost:${PORT}/health" || exit 1

ENTRYPOINT ["python3"]
CMD ["app.py"]