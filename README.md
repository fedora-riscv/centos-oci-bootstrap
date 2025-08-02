# CentOS OCI Bootstrap

Using centos image and dnf to bootstrap an OCI image for rpm-based distribution.

## Usage

```
make [OPTIONS] dnf-based-oci-image
```

Example for CentOS riscv64 with Open Koji repo from PLCT Lab:

```
make \
    dnf_bootstrap_repo?=http://openkoji.iscas.ac.cn/pub/centos-riscv/10-stream/BaseOS/riscv64/os/ \
    dnf_bootstrap_releasever?=10 \
    arch?=riscv64 \
    oci_reference?=your-new-image \
    dnf-based-oci-image
```

Calling `make dnf-based-oci-image` without any options will create a riscv64 image for CentOS Stream 10.
