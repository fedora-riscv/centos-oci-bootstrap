dnf_bootstrap_image?=registry.fedoraproject.org/fedora:41
dnf_bootstrap_releasever?=10
oci_reference?=docker.io/centosriscv/base:$(dnf_bootstrap_releasever)
dnf_bootstrap_repo?=https://openkoji.iscas.ac.cn/pub/centos-riscv/$(dnf_bootstrap_releasever)-stream/BaseOS/riscv64/os/
container_toolkit?=podman
arch?=riscv64
norvv?=0
dnf_bootstrap_repo_norvv?=https://openkoji.iscas.ac.cn/pub/centos-riscv/$(dnf_bootstrap_releasever)-stream/BaseOS/riscv64/os-norvv/


hello:
	@echo "Hello, World! Run make plct-centos-10-rv64 to build an oci image."

make-temp:
	-mkdir ./temp

dnf-container-bootstrap:
	$(MAKE) script-dnf-rootfs
	$(MAKE) script-repo
	$(MAKE) script-end
	$(container_toolkit) run --rm -i --tty -v ./temp:/mnt/temp:z $(dnf_bootstrap_image) /bin/bash /mnt/temp/bootstrap.sh

script-dnf-rootfs: make-temp
	# Dnf Install Rootfs
	@echo dnf --installroot /mnt/temp/rootfs \\ >> ./temp/bootstrap.sh
ifeq ($(norvv), 1)
    @echo --repofrompath norvv-repo,$(dnf_bootstrap_repo_norvv) --repo norvv-repo \\ >> ./temp/bootstrap.sh
endif
	@echo --repofrompath bootstrap-repo,$(dnf_bootstrap_repo) --repo bootstrap-repo \\ >> ./temp/bootstrap.sh
	@echo --nodocs --setopt=install_weak_deps=False -x systemd -x dbus -x polkit \\ >> ./temp/bootstrap.sh
	@echo --forcearch $(arch) --nogpgcheck --releasever $(dnf_bootstrap_releasever) \\  >> ./temp/bootstrap.sh
	@echo -y \\  >> ./temp/bootstrap.sh
	@echo install dnf4 vim-minimal >> ./temp/bootstrap.sh

script-repo: make-temp
	# Change default repo
	@echo dnf4 install \'dnf-command\(config-manager\)\' -y >> ./temp/bootstrap.sh
	@echo dnf4 --installroot /mnt/temp/rootfs config-manager --set-disabled \"\*\" >> ./temp/bootstrap.sh
	@echo dnf4 --installroot /mnt/temp/rootfs config-manager  --add-repo /mnt/temp/bootstrap.repo >> ./temp/bootstrap.sh
	@echo [c$(dnf_bootstrap_releasever)s] > ./temp/bootstrap.repo
	@echo name=CentOS Stream 10 Repo >> ./temp/bootstrap.repo
	@echo baseurl=$(dnf_bootstrap_repo) >> ./temp/bootstrap.repo
	@echo gpgcheck=0 >> ./temp/bootstrap.repo
ifeq ($(norvv), 1)
    @echo dnf --installroot /mnt/temp/rootfs config-manager  --add-repo /mnt/temp/norvv.repo >> ./temp/bootstrap.sh
	@echo [c$(dnf_bootstrap_releasever)s-norvv] > ./temp/norvv.repo
	@echo name=CentOS Stream $(dnf_bootstrap_releasever) NoRVV Repo >> ./temp/norvv.repo
	@echo baseurl=$(dnf_bootstrap_repo) >> ./temp/norvv.repo
	@echo gpgcheck=0 >> ./temp/norvv.repo
endif
	
script-end: make-temp
	# Packup
	@echo tar czf /mnt/temp/rootfs.tar.gz --directory=/mnt/temp/rootfs . >> ./temp/bootstrap.sh

container-import:
ifeq ($(strip $(rootfs_archive)),)
	@echo "rootfs_archive is empty, image will not be built"
	exit 1
endif
ifeq ($(container_toolkit), podman)
	$(container_toolkit) import --change 'CMD ["/bin/bash"]' --arch=$(arch) $(rootfs_archive) $(oci_reference)
else ifeq ($(container_toolkit), docker)
	$(container_toolkit) import --change 'CMD ["/bin/bash"]' --platform=$(arch) $(rootfs_archive) $(oci_reference)
else
	@echo "Unknown container toolkit: $(container_toolkit)"
	exit 1
endif

dnf-based-oci-image:
	$(MAKE) dnf-container-bootstrap
	$(MAKE) rootfs_archive=./temp/rootfs.tar.gz container-import

plct-centos-10-rv64:
	$(MAKE) dnf-based-oci-image

clean:
	-$(container_toolkit) run --rm -i --tty -v ./temp:/mnt/temp:z $(dnf_bootstrap_image) /bin/rm -rf /mnt/temp
	rm -rf ./temp

