{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage (finalAttrs: {
  pname = "canvas-lms-mcp";
  version = "2.11.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/canvas-lms-mcp/-/canvas-lms-mcp-${finalAttrs.version}.tgz";
    hash = "sha256-vqM8tC4/GNigzuPSi+Xmshgi5B9xMKifZi2MSoDCIRI=";
  };

  # upstream ships no lockfile, after a version bump regenerate it with npm install --package-lock-only --omit=dev
  postPatch = ''
    cp ${./canvas-lms-mcp-package-lock.json} package-lock.json
  '';

  # the deps fetch inherits the patch phase and has no npm
  postUnpack = ''
    npm pkg delete devDependencies --prefix "$sourceRoot"
  '';

  npmDepsHash = "sha256-bkaV0NWNDlIOfYU0+9QiBuFssQkiLTm9nwMa5VON11E=";
  dontNpmBuild = true;

  meta = {
    description = "Canvas LMS MCP server";
    homepage = "https://github.com/bruchris/canvas-lms-mcp";
    license = lib.licenses.mit;
    mainProgram = "canvas-lms-mcp";
  };
})
