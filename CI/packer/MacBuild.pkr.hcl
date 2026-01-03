packer {
  required_plugins {
    parallels = {
      source  = "github.com/Parallels/parallels"
      version = ">= 1.2.0"
    }
  }
}

# -------- Variables (top-level only) --------
variable "username" {
  type    = string
  default = "Matt"
}

variable "local_user" {
  type    = string
  default = "Matt"
}

# -------- Source --------
source "parallels-macvm" "tahoe" {
  source_path      = "/Users/${var.username}/Parallels/GoldenImages/tahoe-base-26.2.macvm"
  vm_name          = "macBuildTest"
  output_directory = "/Users/${var.username}/Parallels/macBuildTest.macvm"

  communicator = "ssh"
  ssh_username = "Matt"
  ssh_password = "Matt"
  ssh_timeout  = "30m"

  shutdown_command = "echo Matt | sudo -S shutdown -h now"
  shutdown_timeout = "10m"
}

# -------- Build --------
build {
  name    = "macBuildTest"
  sources = ["source.parallels-macvm.tahoe"]

#   Clone Repo
  provisioner "ansible" {
    playbook_file = "../ansible/cloneRepo.yml"
    user          = "Matt"

    extra_arguments = [
      "--extra-vars", "ansible_become_pass=admin"
    ]
  }

  # Register in Parallels Control Center
  post-processor "shell-local" {
    inline = [
      "echo 'Registering VM with Parallels...'",
      "BASE='/Users/${var.username}/Parallels/macBuildTest.macvm'",
      "INNER=\"$BASE/$(basename \"$BASE\")\"",
      "if prlctl list -a | grep -Fq 'macBuildTest'; then echo 'Already registered'; exit 0; fi",
      "(prlctl register \"$BASE\" || prlctl register \"$INNER\") || { echo 'WARN: register failed for both paths'; exit 0; }",
      "(prlctl set macBuildTest --device-set net0 --type shared || prlctl set macBuildTest --device-add net --type shared) || true",
      "prlctl list -a | grep -F 'macBuildTest' || true",
      "echo \"Registered VM: macBuildTest → $(prlctl list -a | awk '/macBuildTest/ {print $4}')\"",
      "open -a 'Parallels Desktop' || true"
    ]
  }
}
