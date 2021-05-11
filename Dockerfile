FROM docker:19.03

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#runtime-dependencies
RUN set -eux; \
       apk add --no-cache btrfs-progs e2fsprogs e2fsprogs-extra iptables openssl shadow-uidmap xfsprogs xz pigz \
       curl sshpass ca-certificates bash git python3 docker-compose jq \
	; \
	if zfs="$(apk info --no-cache --quiet zfs)" && [ -n "$zfs" ]; then \
		apk add --no-cache zfs; \
	fi

# TODO aufs-tools

# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN set -eux; \
	addgroup -S dockremap; adduser -S -G dockremap dockremap; \
	echo 'dockremap:165536:65536' >> /etc/subuid; echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 42b1175eda071c0e9121e1d64345928384a93df1

RUN set -eux; \
	wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
	chmod +x /usr/local/bin/dind


## https://stackoverflow.com/questions/54099218/how-can-i-install-docker-inside-an-alpine-container
# Ignore to update version here, it is controlled by .travis.yml and build.sh
# docker build --no-cache --build-arg KUBECTL_VERSION=${tag} --build-arg HELM_VERSION=${helm} --build-arg KUSTOMIZE_VERSION=${kustomize_version} -t ${image}:${tag} .
ARG KUBECTL_VERSION=1.18.5

# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
ARG AWS_IAM_AUTH_VERSION_URL=https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator

RUN curl -#kL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.8.0/yq_linux_amd64 \
    && curl -#kL -o /usr/local/bin/katafygio https://github.com/bpineau/katafygio/releases/download/v0.8.3/katafygio_0.8.3_linux_amd64 \
    && curl -LO https://github.com/tdewolff/minify/releases/download/v2.9.10/minify_linux_amd64.tar.gz \
    && mkdir minify_ && tar -xf minify_linux_amd64.tar.gz -C minify_ \
    && mv minify_/minify /usr/local/bin/ && rm -rf *.tar.gz minify_ \
    && chmod +x /usr/local/bin/yq /usr/local/bin/katafygio

# Install kubectl (same version of aws esk)
RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl /usr/bin/kubectl; chmod +x /usr/bin/kubectl


# Install aws-iam-authenticator (latest version)
RUN curl -sLO ${AWS_IAM_AUTH_VERSION_URL}; mv aws-iam-authenticator /usr/bin/aws-iam-authenticator; chmod +x /usr/bin/aws-iam-authenticator

# Install awscli
RUN python3 -m ensurepip; pip3 install --upgrade pip; pip3 install awscli; pip3 cache purge

# Install fabric3
RUN set -x \
    && apk add --no-cache gzip tar zip python3 libffi openssh tzdata \
    && apk add --no-cache whois gnupg unzip libc6-compat \
    && apk add --no-cache --virtual .build-deps python3-dev musl-dev gcc libffi-dev openssl-dev make \
    && pip3 install fabric3; pip3 cache purge; rm -rf /root/.cache /tmp/* /src; apk del .build-deps; rm -rf /var/cache/apk/*


COPY dockerd-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []
