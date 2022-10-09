FROM docker:20.10

ENV TZ America/Sao_Paulo
ENV SHELL /bin/bash
ENV PY_COLORS 1
ENV FORCE_COLOR 1
ENV PATH $PATH:/opt/google-cloud-sdk/bin
ENV LANG en_US.UTF-8

ARG FOLDER_BIN=/usr/local/bin
ARG GCLOUD_VERSION=371.0.0
ARG KUBECTL_VERSION=1.23.5


RUN apk add --no-cache e2fsprogs e2fsprogs-extra iptables openssl shadow-uidmap xfsprogs xz pigz \
    curl sshpass ca-certificates openssh-client bash bash-completion git unzip python3 docker-compose jq rsync \
    py3-crcmod py3-openssl libc6-compat gnupg tar zip libffi openssh tzdata whois gnupg libc6-compat \
    && rm -rf /root/.cache /tmp/* /src; rm -rf /var/cache/apk/*

# TODO aufs-tools
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN addgroup -S dockremap; adduser -S -G dockremap dockremap; echo 'dockremap:165536:65536' >> /etc/subuid; echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 42b1175eda071c0e9121e1d64345928384a93df1
RUN curl -skL -o /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; chmod +x /usr/local/bin/dind


ARG YQ_URL=https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64
ARG KATAFYGIO_URL=https://github.com/bpineau/katafygio/releases/download/v0.8.3/katafygio_0.8.3_linux_amd64


RUN curl -skL -o $FOLDER_BIN/yq ${YQ_URL}; curl -skL -o $FOLDER_BIN/katafygio ${KATAFYGIO_URL}

RUN curl -sLO https://downloads.dockerslim.com/releases/1.36.4/dist_linux.tar.gz \
    && tar -xvf dist_linux.tar.gz; chmod +x dist_linux/docker-slim* \
    && mv dist_linux/docker-slim* $FOLDER_BIN/; rm -rf dist_linux*

curl -skLO https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz
tar -xf upx-*.tar.xz ; mv upx-*/upx $FOLDER_BIN/; rm -rf upx-3.*

curl -skLO https://github.com/cli/cli/releases/download/v2.17.0/gh_2.17.0_linux_amd64.tar.gz
tar -xf gh_*_linux_amd64.tar.gz; mv gh_*_linux_amd64/bin/gh $FOLDER_BIN/ ; rm -rf gh_*_linux_amd64*

curl -skLO https://github.com/ankitpokhrel/jira-cli/releases/download/v1.1.0/jira_1.1.0_linux_x86_64.tar.gz
tar -xf jira_*_linux_x86_64.tar.gz; mv jira_*_linux_x86_64/bin/jira $FOLDER_BIN/ ; rm -rf jira_*_linux_x86_64*

## Install kubectl
curl -skL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o $FOLDER_BIN/kubectl

RUN chmod +x $FOLDER_BIN/*
RUN upx --best --lzma $FOLDER_BIN/{kubectl,gh,katafygio,jira,yq}

## Install Gcloud
RUN addgroup -g 1000 -S cloudsdk && adduser -u 1000 -S cloudsdk -G cloudsdk
RUN curl -sLO https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz \
    && tar -xf google-cloud-*-linux-x86_64.tar.gz \
    && mv google-cloud-sdk /opt/ && rm -f google-cloud-*-linux-x86_64.tar.gz \
    && cp /opt/google-cloud-sdk/completion.bash.inc /etc/bash_completion.d/ \
    && echo 'source /opt/google-cloud-sdk/path.bash.inc' >> /etc/profile \
    && source /opt/google-cloud-sdk/path.bash.inc \
    && gcloud config set core/disable_usage_reporting true \
    && gcloud config set component_manager/disable_update_check true \
    && gcloud --version


# Install fabric3
RUN apk add --no-cache --virtual .build-deps python3-dev ruby-dev musl-dev gcc libffi-dev openssl-dev make \
    && pip3 install fabric3; pip3 cache purge; rm -rf /root/.cache /tmp/* /src; apk del .build-deps; rm -rf /var/cache/apk/*


COPY dockerd-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []
