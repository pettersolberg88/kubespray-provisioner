FROM alpine:3.8
MAINTAINER Johannes Kanavin

# Adding basic stuff
RUN apk add --update python python-dev py-pip build-base && \
    apk add libffi-dev libressl-dev openssl openssh-client && \
    apk add git openssh nmap nmap-scripts curl tcpdump bind-tools && \
    apk add jq nmap-ncat && \
    apk add python3 python3-dev python

# Adding fish shell
RUN apk add fish

# Adding nano and vim
RUN apk add vim nano

##### From https://github.com/hashicorp/docker-vault
# This is the release of Vault to pull in.
ENV VAULT_VERSION=1.0.1

# Create a vault user and group first so the IDs get set the same way,
# even as the rest of this may change over time.
RUN addgroup vault && \
    adduser -S -G vault vault
# Set up certificates, our base tools, and Vault.
RUN set -eux; \
    apk add --no-cache ca-certificates gnupg openssl libcap su-exec dumb-init tzdata && \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        armhf) ARCH='arm' ;; \
        aarch64) ARCH='arm64' ;; \
        x86_64) ARCH='amd64' ;; \
        x86) ARCH='386' ;; \ 
        *) echo >&2 "error: unsupported architecture: $apkArch"; exit 1 ;; \
    esac && \
    VAULT_GPGKEY=91A6E7F85D05C65630BEF18951852D87348FFC4C; \
    found=''; \
    for server in \
        hkp://p80.pool.sks-keyservers.net:80 \
        hkp://keyserver.ubuntu.com:80 \
        hkp://pgp.mit.edu:80 \
    ; do \
        echo "Fetching GPG key $VAULT_GPGKEY from $server"; \
        gpg --batch --keyserver "$server" --recv-keys "$VAULT_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $VAULT_GPGKEY" && exit 1; \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify vault_${VAULT_VERSION}_SHA256SUMS.sig vault_${VAULT_VERSION}_SHA256SUMS && \
    grep vault_${VAULT_VERSION}_linux_${ARCH}.zip vault_${VAULT_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /bin vault_${VAULT_VERSION}_linux_${ARCH}.zip && \
    cd /tmp && \
    rm -rf /tmp/build && \
    gpgconf --kill dirmngr && \
    gpgconf --kill gpg-agent && \
    apk del gnupg openssl && \
    rm -rf /root/.gnupg
    
##### Adding Terraform (with plugins)

RUN apk add terraform

ENV VSPHERE_VERSION=1.9.1
ADD https://releases.hashicorp.com/terraform-provider-vsphere/${VSPHERE_VERSION}/terraform-provider-vsphere_${VSPHERE_VERSION}_linux_amd64.zip ./
ADD https://releases.hashicorp.com/terraform-provider-vsphere/${VSPHERE_VERSION}/terraform-provider-vsphere_${VSPHERE_VERSION}_SHA256SUMS ./

RUN sed -i '/.*linux_amd64.zip/!d' terraform-provider-vsphere_${VSPHERE_VERSION}_SHA256SUMS
RUN sha256sum -cs terraform-provider-vsphere_${VSPHERE_VERSION}_SHA256SUMS

RUN unzip terraform-provider-vsphere_${VSPHERE_VERSION}_linux_amd64.zip -d /usr/bin
RUN rm -f terraform-provider-vsphere_${VSPHERE_VERSION}_linux_amd64.zip

##### Adding Packer


ENV PACKER_VERSION=1.3.3
ENV PACKER_SHA256SUM=efa311336db17c0709d5069509c34c35f0d59c63dfb05f61d4572c5a26b563ea

RUN apk add --update git bash wget openssl

ADD https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip ./
ADD https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS ./

RUN sed -i '/.*linux_amd64.zip/!d' packer_${PACKER_VERSION}_SHA256SUMS
RUN sha256sum -cs packer_${PACKER_VERSION}_SHA256SUMS
RUN unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /bin
RUN rm -f packer_${PACKER_VERSION}_linux_amd64.zip

#### Adding kubectl
RUN curl -L -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.13.1/bin/linux/amd64/kubectl && \
  chmod +x /usr/bin/kubectl


#### Trying pip install for acc-provision and ansible
RUN pip install --upgrade pip
RUN pip install acc_provision==4.1.1.2
RUN pip install ansible netaddr pbr hvac ansible-modules-hashivault
RUN pip install openshift PyYAML

#### AWS CLI for eazy S3 management
RUN pip install awscli

#### Run as vault for fun and games
USER vault
