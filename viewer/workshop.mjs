import { marked } from "./lib/marked.esm.js";

const modules = [
  ["00_project_assembly", "Assembly"],
  ["01_power_module", "01 Power"],
  ["02_line_shifter", "02 I²C level shifter"],
  ["03_cs8406_transmitter", "03 CS8406"],
  ["04_aes3_output", "04 AES3 output"],
  ["05_xmos_interconnect", "05 XMOS"],
];
const plan = ["xu316_cs8406_usb_aesebu_plan", "Project plan"];
const routes = new Map([...modules.map(entry => [entry[0], entry]), ["plan", plan]]);
const requested = new URLSearchParams(location.search).get("guide");
const selected = routes.get(requested) ?? modules[0];
const [name, title] = selected;

function guideUrl(id) {
  return `?guide=${encodeURIComponent(id)}`;
}

for (const [id, label] of modules) {
  const link = document.createElement("a");
  link.href = guideUrl(id);
  link.textContent = label;
  if (id === name) link.setAttribute("aria-current", "page");
  document.querySelector("#modules").append(link);
}
if (selected === plan) document.querySelector("#plan").setAttribute("aria-current", "page");

async function readProjectFile(path) {
  const response = await fetch(path);
  if (!response.ok) throw new Error(`Could not load ${path} (HTTP ${response.status}).`);
  return response.text();
}

async function readModel(path) {
  const source = await readProjectFile(path);
  const includes = [...source.matchAll(/^[ 	]*include <(0[1-5]_\w+\.scad)>[ 	]*$/gm)];
  const files = await Promise.all(includes.map(([, file]) => readProjectFile(`./docs/${file}`)));
  let index = 0;
  // The embedded Playground receives a complete source file through its URL.
  return source.replace(/^[ 	]*include <0[1-5]_\w+\.scad>[ 	]*$/gm, () => files[index++]);
}

const guide = document.querySelector("#guide");
const markdown = `./docs/${name}.md`;
document.querySelector("#markdown").href = markdown;

const tasks = [readProjectFile(markdown).then(source => {
  // Only the fixed, locally maintained project guides are rendered here.
  guide.innerHTML = marked.parse(source);
  for (const link of guide.querySelectorAll("a[href]")) {
    const href = link.getAttribute("href");
    if (modules.some(([id]) => href === `${id}.scad`)) {
      link.href = `./docs/${href}`;
      link.download = "";
      continue;
    }
    const match = /^([\w-]+)\.md(#[\w-]+)?$/.exec(href);
    if (!match) continue;
    const id = match[1] === plan[0] ? "plan" : match[1];
    if (routes.has(id)) link.href = guideUrl(id) + (match[2] ?? "");
  }
  for (const heading of guide.querySelectorAll("h2, h3, h4")) {
    heading.id = heading.textContent.toLowerCase().trim().replace(/[^\w\s-]/g, "").replace(/\s+/g, "-");
  }
  for (const table of guide.querySelectorAll("table")) {
    const wrapper = document.createElement("div");
    wrapper.className = "table-wrap";
    table.before(wrapper);
    wrapper.append(table);
  }
  if (location.hash) document.getElementById(location.hash.slice(1))?.scrollIntoView();
})];

if (selected !== plan) {
  document.querySelector(".model").hidden = false;
  const scad = `./docs/${name}.scad`;
  document.querySelector("#scad").href = scad;
  tasks.push(readModel(scad).then(source => {
    const frame = document.querySelector("#playground");
    frame.title = `OpenSCAD layout for ${title}`;
    frame.src = `./playground/?embed=1#src=${encodeURIComponent(source)}`;
  }));
}
const results = await Promise.allSettled(tasks);
document.querySelector("#status").textContent = results
  .filter(result => result.status === "rejected")
  .map(result => result.reason.message)
  .join(" ");
document.querySelector("main").setAttribute("aria-busy", "false");
