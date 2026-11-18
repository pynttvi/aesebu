# AES3 perfboard workshop

From the project root, run:

```sh
node viewer/serve.mjs
```

Open [the local workshop](http://127.0.0.1:4173/). The workshop opens on the combined assembly. Choose an individual module to see its build guide and interactive model side by side. The page reads the original Markdown and SCAD files, so refresh it after editing those files. The project plan is available from the top navigation.

The server binds to loopback. To use a different port, run `PORT=4180 node viewer/serve.mjs`.

The local build of [OpenSCAD Playground](https://github.com/openscad/openscad-playground) is installed under `playground/` at upstream commit `d4552def6a9b047b016b321f31cdcdcb7e6cfd5b`. The wrapper passes the selected source through the Playground's embedded-view URL. The browser runs the OpenSCAD engine locally. The Markdown renderer is Marked 15.0.12, with its license in `marked.LICENSE`.

## GitHub Pages

The GitHub Actions workflow builds the viewer on every push. Pushes to `main` also deploy to the public Pages site. In the repository’s Pages settings, choose **GitHub Actions** as the publishing source.

To build the same static files locally, run `sh viewer/build-pages.sh` from the project root. The result is in `_site/`.
