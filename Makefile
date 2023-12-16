.PHONY: build

build: radare2-amd64.qcow2 # radare2-arm64.qcow2

files/debian-amd64.qcow2:
	mkdir -p files
	wget -O files/debian-amd64.qcow2 https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

files/debian-arm64.qcow2:
	mkdir -p files
	wget -O files/debian-arm64.qcow2 https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-arm64.qcow2

files/cloudinit.iso: cloudinit/user-data cloudinit/meta-data cloudinit/network-config
	mkdir -p files
	cd cloudinit && genisoimage \
		-output ../files/cloudinit.iso \
		-volid cidata -rational-rock -joliet \
		user-data meta-data network-config

radare2-amd64.qcow2: files/cloudinit.iso files/debian-amd64.qcow2
	cp -v files/debian-amd64.qcow2 files/radare2-build-amd64.qcow2
	qemu-system-x86_64 -machine microvm,accel=kvm:hvf:whpx:nvmm:tcg \
		-nographic -m 512m -device virtio-scsi-device \
		-netdev user,id=net -device virtio-net-device,netdev=net \
		-drive id=boot,file=files/radare2-build-amd64.qcow2,format=qcow2,discard=unmap,if=none \
		-device scsi-hd,drive=boot \
		-drive id=cloudinit,file=files/cloudinit.iso,format=raw,readonly=on,if=none \
		-device scsi-cd,drive=cloudinit
	mv files/radare2-build-amd64.qcow2 radare2-amd64.qcow2

radare2-arm64.qcow2: files/cloudinit.iso files/debian-arm64.qcow2
	cp -v files/debian-arm64.qcow2 files/radare2-build-arm64.qcow2
	qemu-system-aarch64 -machine virt,accel=kvm:hvf:whpx:nvmm:tcg \
		-nographic -m 512m -device virtio-scsi-device \
		-netdev user,id=net -device virtio-net-device,netdev=net \
		-drive id=boot,file=files/radare2-build-arm64.qcow2,format=qcow2,discard=unmap,if=none \
		-device scsi-hd,drive=boot \
		-drive id=cloudinit,file=files/cloudinit.iso,format=raw,readonly=on,if=none \
		-device scsi-cd,drive=cloudinit
	mv files/radare2-build-arm64.qcow2 radare2-arm64.qcow2

