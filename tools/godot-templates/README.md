# Godot web export template (threads off)

`web_nothreads_release.zip` — taken from the official Godot **4.7.2-stable** release
(`Godot_v4.7.2-stable_export_templates.tpz`) and committed here so CI does not have to
download the 1.2 GB archive on every run.

- SHA-256: `D3EE2F08CEF0CF3CF6678A6355A92A8DB48CCDD35CBD2E8BFD5F0E8A0B4032A0`
- Size: 10,245,903 bytes
- Used because `khotwa/export_presets.cfg` sets `variant/thread_support=false`, which is what
  lets the game run on iOS Safari without cross-origin isolation headers.

To replace it after a Godot upgrade: export once locally, then copy
`%APPDATA%\Godot\export_templates\<version>.stable\web_nothreads_release.zip` here and update
`GODOT_VERSION` in `.github/workflows/web-build.yml`.
