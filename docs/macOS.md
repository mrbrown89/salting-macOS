# macOS States

These states handle macOS level

## Dock

Sets the dock settings by editing the key value pair in the users `com.apple.dock` plist.

The `dock.sls` state contains multipule states which uses salt's `cmd` module with the `run` function to run commands to pass key value pairs using Apple's `default write` command. 

The states will first check to see if the setting they are applying is already present. If not then run the `defaults write` command.

Lets look at an example:

```
# Magnification
dock_magnification:
  cmd.run:
    - name: defaults write com.apple.dock magnification -bool true
    - runas: Matt
    - unless: defaults read com.apple.dock magnification | grep -q '^1$'
```

The above example shows a state to set magnification in the dock. 

We can see the `cmd.run` module.function being called with the command to run being:

```
    defaults write com.apple.dock magnification -bool true
```

Next we see the `runas` argument which tells what user to run the salt command as. Since the dock is under the users preferences in `~/Library/Preferences/`, we need to assign a user.

The last line in our state uses the `unless` requisite to check if our setting is already in place by running `defaults read`. If the setting is already in place then salt won't run the `defaults write` command.

The last state will restart the dock by killing the running process but only if states have been run. Salt will know whats been run with the `watch` requisite.

## Dark Mode

This state will set dark mode on macOS for the user by editing a plist. But its different to our `dock.sls` state:

```
enable_dark_mode:
  cmd.run:
    - name: sudo -u Matt defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    - unless: sudo -u Matt defaults read NSGlobalDomain AppleInterfaceStyle | grep -q '^Dark$'
```

We still have the `unless` requisite in there but we only have the `name` argument. This is because we are writing to the hidden `.NSGlobalDomain` plist. 

## Rosetta

State installs rosetta on Apple Silicon Macs. Nice and simple :D 

## Shell

I've put this one in incase anyone is like me and likes to use bash over zsh with the later being the default shell in macOS. 
