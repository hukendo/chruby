# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Base Box
  # --------------------
  config.vm.box = "debian/jessie64"
  config.vm.hostname = "debchrubyng.local"

  # Optional (Remove if desired)
  # --------------------
  config.vm.provider :virtualbox do |vb|
    vb.customize [
      "modifyvm", :id,
      "--memory", 512,             # How much RAM to give the VM (in MB)
      "--cpus", 1                  # Muli-core in the VM
    ]
  end


  # Provisioning Scripts
  # --------------------
  #config.vm.provision "shell", path: "/bin/bash"
  config.vm.provision :shell, inline: "sudo apt-get update -y;"
  config.vm.provision :shell, inline: "sudo apt-get upgrade -y;"
  config.vm.provision :shell, inline: "sudo apt-get install -y shunit2;"
end
