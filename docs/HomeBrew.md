# Homebrew

```
/salting-macOS/salt/brew
```

States in this directory manage brew apps.

## Formulae

Like Ronseal it does what it says on the tin. This state handles brew formulae using salt's `pkg.installed` module.

I've included a bunch of packages as examples. You can swap these out and add others. If the packages you want are casks then add the packages to the `casks.sls` state.

## Casks

This state handles brew casks (GUI based apps). This one is a bit different to the formulae state in that we aren't using a simple list with `pkg.installed`. We are still using `pkg.installed` but you'll notice:

```
    - options:
      - --cask
```

This would be the same as running `brew install --cask <package name>` which is needed to install cask packages.

## Taps

This state is where you'd define any external brew repos you'd like to use. In the example I've given I've set Hashicorp's tap to be added and then install Terraform and Packer.
