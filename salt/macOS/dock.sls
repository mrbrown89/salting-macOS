{% set user = pillar['user']['primary_user'] %}

# -----------------------------
# Dock Preferences (idempotent)
# -----------------------------

# Autohide
dock_autohide:
  cmd.run:
    - name: defaults write com.apple.dock autohide -bool false
    - runas: {{ user }}
    - unless: defaults read com.apple.dock autohide | grep -q '^0$'

# Magnification
dock_magnification:
  cmd.run:
    - name: defaults write com.apple.dock magnification -bool true
    - runas: {{ user }}
    - unless: defaults read com.apple.dock magnification | grep -q '^1$'

# Large size for magnified icons
dock_largesize:
  cmd.run:
    - name: defaults write com.apple.dock largesize -int 128
    - runas: {{ user }}
    - unless: defaults read com.apple.dock largesize | grep -q '^128$'

# Standard tile size
dock_tilesize:
  cmd.run:
    - name: defaults write com.apple.dock tilesize -int 49
    - runas: {{ user }}
    - unless: defaults read com.apple.dock tilesize | grep -q '^49$'

# Show recents
dock_show_recents:
  cmd.run:
    - name: defaults write com.apple.dock show-recents -bool false
    - runas: {{ user }}
    - unless: defaults read com.apple.dock show-recents | grep -q '^0$'

# Hot corner bottom-right modifier
dock_wvous_br_modifier:
  cmd.run:
    - name: defaults write com.apple.dock wvous-br-modifier -int 0
    - runas: {{ user }}
    - unless: defaults read com.apple.dock wvous-br-modifier | grep -q '^0$'

# Restart Dock if any settings changed
restart_dock:
  cmd.run:
    - name: killall Dock
    - watch:
      - cmd: dock_autohide
      - cmd: dock_magnification
      - cmd: dock_largesize
      - cmd: dock_tilesize
      - cmd: dock_show_recents
      - cmd: dock_wvous_br_modifier
