import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { createServer } from "node:http";
import { dirname, extname, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const directory = dirname(fileURLToPath(import.meta.url));
const playground = resolve(directory, "playground");
const projectFiles = new Set([
  "00_project_assembly",
  "01_power_module", "02_line_shifter", "03_cs8406_transmitter",
  "04_aes3_output", "05_xmos_interconnect", "xu316_cs8406_usb_aesebu_plan",
]);
const routes = new Map([
  ["/", "index.html"], ["/workshop.css", "workshop.css"],
  ["/workshop.mjs", "workshop.mjs"], ["/lib/marked.esm.js", "lib/marked.esm.js"],
]);
const types = {
  ".html": "text/html; charset=utf-8", ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8", ".mjs": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm", ".json": "application/json",
  ".md": "text/plain; charset=utf-8", ".scad": "text/plain; charset=utf-8",
  ".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg",
  ".ico": "image/x-icon", ".woff2": "font/woff2", ".glb": "model/gltf-binary",
};

function fileFor(path) {
  if (routes.has(path)) return resolve(directory, routes.get(path));
  if (path.startsWith("/playground/")) {
    const file = resolve(playground, path.slice("/playground/".length) || "index.html");
    if (file.startsWith(playground + sep)) return file;
  }
  const model = /^\/docs\/([\w-]+)\.(?:md|scad)$/.exec(path);
  if (model && projectFiles.has(model[1])) return resolve(directory, "..", path.slice(6));
}

const port = Number(process.env.PORT ?? 4173);
createServer(async (request, response) => {
  if (request.method !== "GET" && request.method !== "HEAD") {
    response.writeHead(405, { Allow: "GET, HEAD" }).end();
    return;
  }

  let file;
  let info;
  try {
    const path = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
    file = fileFor(path);
    if (file) info = await stat(file);
  } catch (error) {
    if (!(error instanceof URIError) && error.code !== "ENOENT" && error.code !== "ENOTDIR") {
      response.writeHead(500).end("Unable to read the requested file.");
      return;
    }
  }

  if (!info?.isFile()) {
    response.writeHead(404).end("File not found.");
    return;
  }

  response.writeHead(200, {
    "Content-Type": types[extname(file)] ?? "application/octet-stream",
    "Content-Length": info.size,
  });
  if (request.method === "HEAD") {
    response.end();
  } else {
    const stream = createReadStream(file);
    stream.on("error", () => response.destroy());
    stream.pipe(response);
  }
}).listen(port, "127.0.0.1", () => {
  console.log(`AES3 perfboard workshop: http://127.0.0.1:${port}/`);
});
