# Aqua Probe Rebrand Summary

## Files Renamed
- `aqua-warden.sh` -> `aqua-probe.sh`
- `misc/aqua-warden-demo.gif` -> `misc/aqua-probe-demo.gif`
- `misc/aqua-warden-advanced-commands.png` -> `misc/aqua-probe-advanced-commands.png`
- `misc/aqua_warden_1x1.png` -> `misc/aqua_probe_1x1.png`
- `misc/aqua_warden_1920x1080.png` -> `misc/aqua_probe_1920x1080.png`
- `user-guide/Aqua-Warden_Userguide.pdf` -> `user-guide/Aqua-Probe_Userguide.pdf`

## Variables Renamed
- `AQUA_WARDEN_IMAGE` -> `AQUA_PROBE_IMAGE`
- `AQUA_WARDEN_NAMESPACE` -> `AQUA_PROBE_NAMESPACE`
- `AQUA_WARDEN_DAEMONSET` -> `AQUA_PROBE_DAEMONSET`
- `AQUA_WARDEN_SKIP_INSTRUCTIONS` -> `AQUA_PROBE_SKIP_INSTRUCTIONS`

## Image References Updated
- `stanhoe/aqua-warden:latest` -> `ericgomes56/aqua-probe:1.0`
- Default `--image` help text and runtime default now use `ericgomes56/aqua-probe:1.0`
- README image examples now use `ericgomes56/aqua-probe:1.0`

## Documentation Changes Made
- Project name updated to `Aqua Probe`
- Script usage updated to `./aqua-probe.sh`
- README media references updated to renamed Aqua Probe assets
- Renamed PDF user guide and patched the embedded source repository URL
- Author attribution updated to `Tool developed by Eric Gomes, Senior DevSecOps Architect @ Aqua Security`
- Installation, usage, requirements, and command examples updated for the new naming

## Manual Review Items
- `user-guide/Aqua-Probe_Userguide.pdf` was searched for extractable legacy text and the old source URL was patched. If the PDF contains screenshots with previous branding, regenerate the source document and export a refreshed PDF.
- The external container image `ericgomes56/aqua-probe:1.0` should be published before users run the default examples.
