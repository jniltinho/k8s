FROM python:3.9.14-alpine3.16

ENV TZ America/Sao_Paulo
ENV SHELL /bin/bash
ENV PY_COLORS 1
ENV FORCE_COLOR 1
ENV PATH $PATH:/opt/google-cloud-sdk/bin:/opt/yarn-v1.22.19/bin
ENV LANG en_US.UTF-8

ARG FOLDER_BIN=/usr/local/bin
ARG GCLOUD_VERSION=371.0.0
ARG YQ_URL=https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64
ARG KATAFYGIO_URL=https://github.com/bpineau/katafygio/releases/download/v0.8.3/katafygio_0.8.3_linux_amd64
ARG COMPOSE=https://github.com/docker/compose/releases/download/v2.11.2/docker-compose-linux-x86_64
ARG KUBECTL=https://storage.googleapis.com/kubernetes-release/release/v1.23.5/bin/linux/amd64/kubectl

WORKDIR /usr/src/backend

RUN apk add --no-cache iptables openssl xz pigz git unzip python3 jq rsync \
    curl sshpass ca-certificates openssh-client bash bash-completion \
    py3-crcmod py3-openssl py3-pip gnupg tar zip libffi openssh tzdata libc6-compat \
    && rm -rf /root/.cache /tmp/* /src; rm -rf /var/cache/apk/*

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN curl -skLO https://download.docker.com/linux/static/stable/x86_64/docker-20.10.18.tgz \
    && tar -xf docker-*.tgz; cp docker/docker $FOLDER_BIN/ ; rm -rf docker*

## Install kubectl, docker-compose
RUN curl -skL -o $FOLDER_BIN/kubectl ${KUBECTL}; curl -skL -o $FOLDER_BIN/docker-compose ${COMPOSE}
RUN curl -skL -o $FOLDER_BIN/katafygio ${KATAFYGIO_URL}; curl -skL -o $FOLDER_BIN/yq ${YQ_URL}

RUN curl -sLO https://downloads.dockerslim.com/releases/1.38.0/dist_linux.tar.gz \
    && tar --extract --file dist_linux.tar.gz --strip-components 1 --directory $FOLDER_BIN/ --no-same-owner \
    && rm -f *.gz

RUN curl -skLO https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz \
    && tar -xf upx-*.tar.xz ; mv upx-*/upx $FOLDER_BIN/; rm -rf upx-3.*

RUN curl -skLO https://github.com/cli/cli/releases/download/v2.17.0/gh_2.17.0_linux_amd64.tar.gz \
    && tar --extract --file *.gz --strip-components 2 --directory $FOLDER_BIN/ --no-same-owner --exclude 'man' \
    && rm -f *.gz

RUN curl -skLO https://github.com/ankitpokhrel/jira-cli/releases/download/v1.1.0/jira_1.1.0_linux_x86_64.tar.gz \
   && tar --extract --file *.gz --strip-components 2 --directory $FOLDER_BIN/ --no-same-owner \
   && rm -f *.gz

COPY --from=node:16-alpine3.16 /opt/yarn-v1.22.19 /opt/yarn-v1.22.19
COPY --from=node:16-alpine3.16 /usr/local/bin/node /usr/local/bin/node
COPY --from=node:16-alpine3.16 /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN cd $FOLDER_BIN/; ln -s ../lib/node_modules/npm/bin/npm-cli.js npm; ln -s ../lib/node_modules/npm/bin/npx-cli.js npx

RUN chmod +x $FOLDER_BIN/*
RUN upx --best --lzma $FOLDER_BIN/{node,kubectl,docker,gh,katafygio,jira,yq,docker-compose}

## Install Gcloud
RUN curl -sLO https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz \
    && tar -xf google-cloud-*-linux-x86_64.tar.gz \
    && mv google-cloud-sdk /opt/ && rm -f google-cloud-*-linux-x86_64.tar.gz \
    && echo 'source /opt/google-cloud-sdk/path.bash.inc' >> /etc/profile \
    && source /opt/google-cloud-sdk/path.bash.inc \
    && gcloud config set core/disable_usage_reporting true \
    && gcloud config set component_manager/disable_update_check true \
    && gcloud --version


# Install fabric3
RUN apk add --no-cache --virtual .build-deps python3-dev ruby-dev musl-dev gcc libffi-dev openssl-dev make \
    && python3 -m pip install --upgrade pip wheel setuptools virtualenv termcolor distro nox \
    && pip3 install fabric3; pip3 cache purge; rm -rf /root/.cache /tmp/* /src; apk del .build-deps; rm -rf /var/cache/apk/*

