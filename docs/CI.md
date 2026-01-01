# Continuous Integration (CI)

This repo is designed to be tested before it ever touches a real Mac.

Salt states can be deceptively dangerous on macOS — a bad `defaults write`, a broken `cmd.run`, or a misplaced `sudo` can leave a machine in a right mess. CI exists here to catch that before anything runs on a daily driver or production machine.

Also, CI in a VM using Packer is fun!

The goal is simple. If it passes CI, I’m confident applying it for real. Famous last words, right?

---

## What CI Means

CI means:
- building a throwaway macOS VM
- applying Salt states inside that VM
- verifying they converge cleanly and idempotently
- then throwing the VM away

No state is trusted unless it survives this process.

---

## The Golden Image

CI starts from a golden macOS VM

Shopping list:
- Parallels Pro
- Packer
- Ansible

This VM:
- is manually created and kept intentionally minimal
- has Parallels tools installed
- has SSH enabled
- xcode tools installed
- Home Brew is installed

The idea is to create this golden image and never change it. Instead we use Packer to clone it each time we want to run a build test. That being said when Parallels releases a new version with updated Parallels tools I do reimport the VM, update the tools and then unregister the VM.

---

## Packer

[Packer](https://www.packer.io/) is used to automate VM creation and testing.

The Packer workflow looks like this:

1. Clone the golden macOS VM
2. Boot the cloned VM
3. Connect over SSH
4. Run provisioning steps using Ansible. In this case just to clone this repo to the VM
5. Shut the VM down
6. Register it in Parallels

All Packer configuration lives in the repo so anyone can spin up the same test VM locally.

---

## Why a VM and Not Containers?

macOS configuration:
- relies heavily on user sessions
- uses per-user plists
- expects launch services, Dock, Finder, etc.

Containers simply don’t model this well.

A real macOS VM behaves like:
- a real user account
- a real Dock
- a real login session

Which makes failures meaningful instead of theoretical.

---

## How States Are Tested

In short the same way we would on a fresh mac! The beauty of using Packer and a Golden VM means we have a mac already in a good state i.e. repo is cloned, home brew and xcode tools are installed. 

So all we need to do now it run the `bootStrap.sh` script which will install salt and run a salt call. Normally the script will also handle installing xcode command line tools and Home Brew but to avoid having to wait on that we pre bake that into our Golden VM. 
