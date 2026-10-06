# -*- mode: ruby -*-
# vi: set ft=ruby :
# =============================================================================
# KISA Linux Hardening — Vagrant Wrapper (Delegates to vagrant/Vagrantfile)
# =============================================================================

vagrantfile_path = File.expand_path("vagrant/Vagrantfile", __dir__)
if File.exist?(vagrantfile_path)
  load vagrantfile_path
else
  raise "vagrant/Vagrantfile not found at #{vagrantfile_path}"
end
