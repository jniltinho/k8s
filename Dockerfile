FROM docker:20.10

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#runtime-dependencies
RUN apk add --no-cache e2fsprogs e2fsprogs-extra iptables openssl shadow-uidmap xfsprogs xz pigz \
    curl sshpass ca-certificates openssh-client bash git unzip python3 docker-compose jq rsync

# TODO aufs-tools
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN addgroup -S dockremap; adduser -S -G dockremap dockremap; echo 'dockremap:165536:65536' >> /etc/subuid; echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 42b1175eda071c0e9121e1d64345928384a93df1
ENV BOLT_DISABLE_ANALYTICS=true

RUN curl -#kL -o /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; chmod +x /usr/local/bin/dind

## Vault CLI
RUN curl -#kLO https://releases.hashicorp.com/vault/1.9.3/vault_1.9.3_linux_amd64.zip \
    && unzip vault_1.9.3_linux_amd64.zip \
    && mv vault /usr/local/bin/ \
    && rm -f vault_1.9.3_linux_amd64.zip

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
    && tar -xvf dist_linux.tar.gz \
    && chmod +x dist_linux/docker-slim* \
    && mv dist_linux/docker-slim* /usr/local/bin/ \
    && rm -rf dist_linux*


# Install kubectl (same version of aws esk)
RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl /usr/bin/kubectl; chmod +x /usr/bin/kubectl


# Install awscli
RUN python3 -m ensurepip; pip3 install --upgrade pip; pip3 install awscli; pip3 cache purge

ARG CLOUD_SDK_VERSION=379.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV PATH /google-cloud-sdk/bin:$PATH
RUN addgroup -g 1000 -S cloudsdk && adduser -u 1000 -S cloudsdk -G cloudsdk
RUN if [ `uname -m` = 'x86_64' ]; then echo -n "x86_64" > /tmp/arch; else echo -n "arm" > /tmp/arch; fi;
RUN ARCH=`cat /tmp/arch` && apk --no-cache add py3-crcmod py3-openssl libc6-compat gnupg \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz \
    && tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz \
    && rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz \
    && gcloud config set core/disable_usage_reporting true \
    && gcloud config set component_manager/disable_update_check true \
    && gcloud config set metrics/environment github_docker_image && gcloud --version


# Install fabric3
RUN set -x \
    && apk add --no-cache gzip tar zip python3 libffi openssh tzdata \
    && apk add --no-cache whois gnupg unzip libc6-compat \
    && apk add --no-cache --virtual .build-deps python3-dev ruby-dev musl-dev gcc libffi-dev openssl-dev make \
    && pip3 install fabric3; pip3 cache purge; rm -rf /root/.cache /tmp/* /src; apk del .build-deps; rm -rf /var/cache/apk/*

#RUN gem install bolt

COPY dockerd-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []
