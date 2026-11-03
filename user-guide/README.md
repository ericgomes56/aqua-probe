# User Guide

[Open the PDF](Aqua-Probe_Userguide.pdf)

The guide covers the repository's current Kubernetes and host workflows as reviewed on November 2, 2026. The script and [control reference](../docs/control-reference.md) remain the source of truth as the project evolves.

## Rebuild

With Python 3 and `reportlab` installed, run from the repository root:

```bash
python3 user-guide/build_guide.py
```

The build replaces `user-guide/Aqua-Probe_Userguide.pdf`. It uses the current project logo and terminal screenshot from `misc/` and the unchanged Aqua logo PNGs in `assets/`. Paragraph, table, and code layout checks fail on page overflow. Render and visually inspect every page before publishing a revision.

## Asset Provenance

`assets/Aquasec-logo-dark.png` and `assets/Aquasec-logo-white.png` come from the user-supplied `Aquasec-logo.zip` (PNG folder). They are used without recoloring or changing their proportions.

The archive's `Drop-Icon/Presentation.pptx` contains a single blank slide with the default Office theme and no artwork. It did not provide a populated presentation template to reproduce. The guide therefore uses a new navy, blue, teal, and white layout with the supplied logos, rather than claiming to reproduce a supplied deck.

Brand assets remain subject to their owners' rights. Their inclusion does not establish official Aqua product support or a project license.
