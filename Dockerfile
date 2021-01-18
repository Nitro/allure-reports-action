FROM openjdk:8-jre-buster

ARG RELEASE=2.13.8
ARG ALLURE_REPO=https://repo.maven.apache.org/maven2/io/qameta/allure/allure-commandline

LABEL org.opencontainers.image.authors="systems@gonitro.com"
LABEL org.opencontainers.image.description="Allure CLI + AWS CLI"
LABEL org.opencontainers.image.title="allure-reports-action"

ENV ROOT=/app
ENV PATH=$PATH:/allure-$RELEASE/bin
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    software-properties-common \
        curl \
        wget \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

RUN wget --no-verbose -O /tmp/allure-$RELEASE.zip $ALLURE_REPO/$RELEASE/allure-commandline-$RELEASE.zip \
  && unzip /tmp/allure-$RELEASE.zip -d / \
  && rm -rf /tmp/*

RUN chmod -R +x /allure-$RELEASE/bin

RUN mkdir -p $ROOT

WORKDIR $ROOT
COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]