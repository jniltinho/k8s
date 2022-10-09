FROM docker:20.10

ENV TZ America/Sao_Paulo
ENV SHELL /bin/bash
ENV PY_COLORS 1
ENV FORCE_COLOR 1
ENV PATH $PATH:/opt/google-cloud-sdk/bin
ENV LANG en_US.UTF-8
ARG GCLOUD_VERSION=371.0.0


RUN apk add --no-cache e2fsprogs e2fsprogs-extra iptables openssl shadow-uidmap xfsprogs xz pigz \
    curl sshpass ca-certificates openssh-client bash bash-completion git unzip python3 docker-compose jq rsync

# TODO aufs-tools
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN addgroup -S dockremap; adduser -S -G dockremap dockremap; echo 'dockremap:165536:65536' >> /etc/subuid; echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 42b1175eda071c0e9121e1d64345928384a93df1

RUN curl -#kL -o /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; chmod +x /usr/local/bin/dind


## https://stackoverflow.com/questions/54099218/how-can-i-install-docker-inside-an-alpine-container
# Ignore to update version here, it is controlled by .travis.yml and build.sh
# docker build --no-cache --build-arg KUBECTL_VERSION=${tag} --build-arg HELM_VERSION=${helm} -t ${image}:${tag} .
ARG HELM_VERSION=3.5.4
ARG KUBECTL_VERSION=1.23.5

ARG YQ_URL=https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64
ARG KATAFYGIO_URL=https://github.com/bpineau/katafygio/releases/download/v0.8.3/katafygio_0.8.3_linux_amd64


RUN curl -#kL -o /usr/local/bin/yq ${YQ_URL} \
    && curl -#kL -o /usr/local/bin/katafygio ${KATAFYGIO_URL} \
    && chmod +x /usr/local/bin/yq /usr/local/bin/katafygio

RUN curl -sLO https://downloads.dockerslim.com/releases/1.36.4/dist_linux.tar.gz \
    && tar -xvf dist_linux.tar.gz; chmod +x dist_linux/docker-slim* \
    && mv dist_linux/docker-slim* /usr/local/bin/; rm -rf dist_linux*


# Install kubectl (same version of aws esk)
RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl /usr/bin/kubectl; chmod +x /usr/bin/kubectl


# Install awscli
RUN python3 -m ensurepip; pip3 install --upgrade pip; pip3 install awscli; pip3 cache purge

## Install Gcloud
RUN addgroup -g 1000 -S cloudsdk && adduser -u 1000 -S cloudsdk -G cloudsdk
RUN apk --no-cache add py3-crcmod py3-openssl libc6-compat gnupg
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
RUN set -x \
    && apk add --no-cache gzip tar zip python3 libffi openssh tzdata \
    && apk add --no-cache whois gnupg unzip libc6-compat \
    && apk add --no-cache --virtual .build-deps python3-dev ruby-dev musl-dev gcc libffi-dev openssl-dev make \
    && pip3 install fabric3; pip3 cache purge; rm -rf /root/.cache /tmp/* /src; apk del .build-deps; rm -rf /var/cache/apk/*


COPY dockerd-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []
