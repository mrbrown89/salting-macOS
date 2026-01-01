# salting-macOS

Welcome to my salting macOS repo!

I've created this repo to offer some templates and guidance on using [SaltStack](https://saltproject.io/) to manage macOS. 

Wait... salt? But people like to talk about using Ansible to manage macOS! Yup fair point and you'll notice there is an Ansible playbook in the CI part of this repo (but only used for cloning this repo to a mac VM for testing :D)

There are already [repos](https://github.com/geerlingguy/mac-dev-playbook) showing you how to use Ansible to build out a mac so I thought I'd make something different using Salt.

Using Salt, we are able to build a mac and continue to mange the mac using Salt states. Normally with Salt you'd have a Salt master server and install the minion program on your machines that you want to manage with salt. In this case though I want to use Salt to mange my personal mac and any macs I play with. I don't want to have a Salt Master server at home to manage things so we use Salt in the masterless mode.

Professional I use Jamf to manage macs but I can't and don't want to pay for Jamf to manage my personal mac and any VMs I want to tinker with! But I do use Salt professional to manage ~60 Windows machines in an animation studio as well as Linux systems including a ZFS based NAS.

---

## Quickstart

1. Set up your mac as normal with a user account and what not. At this stage I also install xcode from the app store.
2. Grant full disk access to terminal.
3. Clone this repo to your mac.
4. Edit the username and home directory set in `/salting-macOS/pillar/user.sls` to your user. I've left my name in as an example.
5. In terminal `cd` to the `bootStrap.sh` script. Make it executable with `chmod +x bootStrap.sh` and then run it with `./bootStrap.sh`. The script will install:
    - xcode tools
    - home brew
    - salt
    - run a salt call to build out salt states
    
---
    
## CI

I have included a continuous integration section in this repo which will allow you to test states in a VM first. Please refer to the CI document in the docs directory for detailed instructions on how to use Packer with Ansible and Parallels to build a test VM and test your states.

---

## Documentation

Further detailed documentation can be found in the `/docs` directory.
