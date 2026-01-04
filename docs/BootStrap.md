# Boot Strap

## Brew install

Homebrew installed via the official installer is only added to the user’s shell environment, which prevents Salt’s macOS pkg module from detecting brew in non-interactive su shells; adding /opt/homebrew/bin to /etc/paths.d makes Homebrew visible system-wide and allows Salt to function correctly. This is done with:

```
  sudo install -d -o "${USER_NAME}" -g wheel -m 0755 "${BREW_PREFIX}"
  sudo install -d -o root -g wheel -m 0755 /etc/paths.d
  echo "${BREW_PREFIX}/bin" | sudo tee /etc/paths.d/homebrew >/dev/null
  sudo chmod a+r /etc/paths.d/homebrew
```



