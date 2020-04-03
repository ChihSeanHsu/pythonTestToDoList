FROM python:3.7-alpine
LABEL maintainer="s8901489@gmail.com"

WORKDIR /root

COPY requirments.txt /tmp/

RUN apk update && apk add \
    libuuid \
    pcre \
    mailcap \
    gcc \
    libc-dev \
    linux-headers \
    pcre-dev \
    curl \
    bash \
    && pip install --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirments.txt \
    && apk del \
    gcc \
    libc-dev \
    linux-headers \
    && rm -rf /tmp/*

RUN mkdir -p /var/log/app \
    && chmod 777 -R /var/log/app

COPY src /root