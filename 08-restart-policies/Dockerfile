FROM busybox:1.36.0-glibc

WORKDIR /app

COPY failure.sh .

RUN chmod +x failure.sh

CMD ["./failure.sh"]