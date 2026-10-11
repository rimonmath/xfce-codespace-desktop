FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xfce4 \
        xfce4-terminal \
        tigervnc-standalone-server \
        tigervnc-common \
        novnc \
        websockify \
        dbus-x11 \
        xauth \
        procps \
        iproute2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
