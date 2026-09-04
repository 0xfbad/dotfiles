{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage (finalAttrs: {
  pname = "canvas-lms-mcp";
  version = "1.27.8";

  src = fetchurl {
    url = "https://registry.npmjs.org/canvas-lms-mcp/-/canvas-lms-mcp-${finalAttrs.version}.tgz";
    hash = "sha256-uU49i8cptL2bPtGMora7R2osrYGUcAm6jIuS+cVG4jw=";
  };

  # no lockfile upstream, npm install --package-lock-only --omit=dev on bump
  postPatch = ''
    cp ${./canvas-lms-mcp-package-lock.json} package-lock.json
    npm pkg delete devDependencies
  '';

  npmDepsHash = "sha256-2vsMRagoGF887wAVMBB4BZgbCs30sg22zQidbjbv4/k=";
  dontNpmBuild = true;

  meta = {
    description = "Canvas LMS MCP server";
    homepage = "https://github.com/bruchris/canvas-lms-mcp";
    license = lib.licenses.mit;
    mainProgram = "canvas-lms-mcp";
  };
})
