# -*- mode: ruby -*-
# vi: set ft=ruby :
# =============================================================================
# KISA Linux Hardening — Ubuntu 22 / 24 Vagrant Test Environment
# =============================================================================

Vagrant.configure("2") do |config|
  # SSH 공통 설정: 새 키 교체 방지 (vagrant 기본 키 유지)
  config.ssh.insert_key = false
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # VirtualBox Provider 기본 설정
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "1024"
    vb.cpus = 1
  end

  # 호스트 사용자의 SSH 공개키가 존재하면 VM에도 자동 등록
  host_pubkeys = [
    File.expand_path("~/.ssh/id_ed25519.pub"),
    File.expand_path("~/.ssh/id_rsa.pub")
  ].select { |p| File.exist?(p) }.map { |p| File.read(p).strip }.join("\n")

  # Libvirt Provider (QEMU/KVM) 기본 설정 (지원 시)
  config.vm.provider "libvirt" do |lv|
    lv.memory = 1024
    lv.cpus = 1
  end

  # ---------------------------------------------------------------------------
  # Ubuntu 22.04 LTS (Jammy Jellyfish)
  # ---------------------------------------------------------------------------
  config.vm.define "ubuntu22" do |u22|
    u22.vm.box = "bento/ubuntu-22.04"
    u22.vm.hostname = "kisa-ubuntu22"
    u22.vm.network "private_network", ip: "192.168.56.22"
    u22.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh", auto_correct: true

    u22.vm.provision "shell", inline: <<-SHELL
      set -e
      export DEBIAN_FRONTEND=noninteractive
      # ubuntu 사용자 및 sudo 설정
      id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo ubuntu
      echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
      chmod 0440 /etc/sudoers.d/ubuntu
      # vagrant ssh 키를 ubuntu 계정에도 배포
      mkdir -p /home/ubuntu/.ssh
      if [ -f /home/vagrant/.ssh/authorized_keys ]; then
        cp -f /home/vagrant/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
      fi
      if [ -n "#{host_pubkeys}" ]; then
        echo "#{host_pubkeys}" >> /home/vagrant/.ssh/authorized_keys
        echo "#{host_pubkeys}" >> /home/ubuntu/.ssh/authorized_keys
        sort -u /home/vagrant/.ssh/authorized_keys -o /home/vagrant/.ssh/authorized_keys
        sort -u /home/ubuntu/.ssh/authorized_keys -o /home/ubuntu/.ssh/authorized_keys
      fi
      chown -R ubuntu:ubuntu /home/ubuntu/.ssh
      chmod 700 /home/ubuntu/.ssh
      chmod 600 /home/ubuntu/.ssh/authorized_keys 2>/dev/null || true
    SHELL
  end

  # ---------------------------------------------------------------------------
  # Ubuntu 24.04 LTS (Noble Numbat)
  # ---------------------------------------------------------------------------
  config.vm.define "ubuntu24" do |u24|
    u24.vm.box = "bento/ubuntu-24.04"
    u24.vm.hostname = "kisa-ubuntu24"
    u24.vm.network "private_network", ip: "192.168.56.24"
    u24.vm.network "forwarded_port", guest: 22, host: 2224, id: "ssh", auto_correct: true

    u24.vm.provision "shell", inline: <<-SHELL
      set -e
      export DEBIAN_FRONTEND=noninteractive
      # ubuntu 사용자 및 sudo 설정
      id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo ubuntu
      echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
      chmod 0440 /etc/sudoers.d/ubuntu
      # vagrant ssh 키를 ubuntu 계정에도 배포
      mkdir -p /home/ubuntu/.ssh
      if [ -f /home/vagrant/.ssh/authorized_keys ]; then
        cp -f /home/vagrant/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
      fi
      if [ -n "#{host_pubkeys}" ]; then
        echo "#{host_pubkeys}" >> /home/vagrant/.ssh/authorized_keys
        echo "#{host_pubkeys}" >> /home/ubuntu/.ssh/authorized_keys
        sort -u /home/vagrant/.ssh/authorized_keys -o /home/vagrant/.ssh/authorized_keys
        sort -u /home/ubuntu/.ssh/authorized_keys -o /home/ubuntu/.ssh/authorized_keys
      fi
      chown -R ubuntu:ubuntu /home/ubuntu/.ssh
      chmod 700 /home/ubuntu/.ssh
      chmod 600 /home/ubuntu/.ssh/authorized_keys 2>/dev/null || true
    SHELL
  end
end
