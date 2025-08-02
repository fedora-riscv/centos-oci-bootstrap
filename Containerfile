FROM quay.io/centos/centos:10 AS builder

ARG dnf_bootstrap_releasever=10
ARG dnf_bootstrap_repo=https://openkoji.iscas.ac.cn/pub/centos-riscv/${dnf_bootstrap_releasever}-stream/BaseOS/riscv64/os/
ARG dnf_bootstrap_norvv_repo=https://openkoji.iscas.ac.cn/pub/centos-riscv/${dnf_bootstrap_releasever}-stream/BaseOS/riscv64/os-norvv/
ARG arch=riscv64
ARG norvv=0

RUN dnf install -y 'dnf-command(config-manager)'

RUN if [ "${norvv}" -eq 1 ]; then \
        norvv_repo_arg="--repofrompath=norvv-repo,${dnf_bootstrap_norvv_repo}"; \
    fi; \
    dnf --installroot=/rootfs --disablerepo '*' --releasever=${dnf_bootstrap_releasever} \
    --setopt=install_weak_deps=False --nodocs --forcearch=${arch} --nogpgcheck \
    ${norvv_repo_arg} \
    --repofrompath=bootstrap-repo,${dnf_bootstrap_repo} -x systemd -x dbus -x polkit \
    install -y dnf vim-minimal && \
    dnf clean all --installroot=/rootfs

# Will be removed later
RUN dnf --installroot=/rootfs config-manager --set-disabled "*"

RUN cat > /bootstrap.repo << EOF
[bootstrap-repo]
name=Bootstrap Repo
baseurl=${dnf_bootstrap_repo}
enabled=1
gpgcheck=0
EOF

RUN cat > /norvv.repo << EOF
[norvv-repo]
name=Norvv Repo
baseurl=${dnf_bootstrap_norvv_repo}
enabled=1
gpgcheck=0
EOF

RUN dnf --installroot=/rootfs config-manager --add-repo /bootstrap.repo && \
    dnf --installroot=/rootfs config-manager --set-enabled bootstrap-repo

RUN if [ "${norvv}" -eq 1 ]; then \
        dnf --installroot=/rootfs config-manager --add-repo /norvv.repo && \
        dnf --installroot=/rootfs config-manager --set-enabled norvv-repo;
    fi

FROM --platform=linux/riscv64 scratch AS final

COPY --from=builder /rootfs/ /

CMD ["/bin/bash"]