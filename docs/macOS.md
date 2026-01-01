# macOS States

These states handle macOS level

---

## Dock

Sets the dock settings by editing the key value pair in the users `com.apple.dock` plist.

The `dock.sls` state contains multipule states which uses salt's `cmd` module with the `run` function to run commands to pass key value pairs using Apple's `default write` command. 

The states will first check to see if the setting they are applying is already present. If not then run the `defaults write` command.

Lets look at an example:

```
# Magnification
dock_magnification:
  macdefaults.write:
    - name: magnification
    - domain: com.apple.dock
    - value: True
    - user: {{ user }}
    - vtype: bool
```

The above example shows a state to set magnification in the dock. 

In this example we are using Salt's [macdefaults](https://docs.saltproject.io/en/latest/ref/modules/all/salt.modules.macdefaults.html) module.

The `user` argument is a variable by using the `user.sls` pillar file. To use this we need to declare the pillar at the start of the state file which you can see is set to:

```
{% set user = pillar['user']['primary_user'] %}
```

The last state will restart the dock by killing the running process but only if states have been run. Salt will know whats been run with the `watch` requisite.

---

## Dark Mode

This state will set dark mode on macOS for the user by editing a plist. Just like the dock state we are using Salt's macdefaults module:

```
enable_dark_mode:
  macdefaults.write:
    - name: AppleInterfaceStyle
    - domain: NSGlobalDomain
    - value: Dark
    - user: {{ user }}
    - vtype: string
```

---

## Rosetta

State installs rosetta on Apple Silicon Macs. Nice and simple :D 

---

## Shell

I've put this one in incase anyone is like me and likes to use bash over zsh with the later being the default shell in macOS. 
