import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export type NiriBind = {
  keys: string;
  title: string;
  action: string;
  fromTitle: boolean;
};

const CONFIG_PATH =
  process.env.NIRI_CONFIG ?? join(homedir(), ".config/niri/config.kdl");

// extract the top-level `binds { ... }` block by brace-counting from its opening
function extractBindsBlock(text: string): string | null {
  const start = text.search(/^\s*binds\s*\{/m);
  if (start === -1) return null;

  let depth = 0;
  let i = text.indexOf("{", start);
  const bodyStart = i + 1;

  for (; i < text.length; i++) {
    if (text[i] === "{") depth++;
    else if (text[i] === "}") {
      depth--;
      if (depth === 0) return text.slice(bodyStart, i);
    }
  }
  return null;
}

// turn a raw action like move-window-to-workspace 1 into a readable label
function prettyAction(body: string): string {
  const cleaned = body.replace(/;/g, " ").replace(/\s+/g, " ").trim();
  const spawn = cleaned.match(/^spawn\s+(.*)$/);
  if (spawn) {
    const args = [...spawn[1].matchAll(/"([^"]*)"/g)].map((m) => m[1]);
    const last = args[args.length - 1] ?? "";
    const base = last.includes("/") ? last.split("/").pop()! : last;
    return base ? `spawn ${base}` : "spawn";
  }
  return cleaned.replace(/^(\S+)/, (verb) => verb.replace(/-/g, " "));
}

export function getNiriKeybinds(): NiriBind[] {
  if (!existsSync(CONFIG_PATH)) {
    throw new Error(`niri config not found at ${CONFIG_PATH}`);
  }

  const text = readFileSync(CONFIG_PATH, "utf8");
  const block = extractBindsBlock(text);
  if (!block) throw new Error("no binds { } block found in config.kdl");

  const binds: NiriBind[] = [];

  // niri-flake emits each bind on its own line, so a line scan is safe
  for (const raw of block.split("\n")) {
    const line = raw.trim();
    if (!line || line.startsWith("//") || line.startsWith("/*")) continue;

    const m = line.match(/^(\S+)\s+(.*?)\{\s*(.*?)\s*\}\s*$/);
    if (!m) continue;

    const [, keys, attrs, actionBody] = m;
    const titleMatch = attrs.match(/hotkey-overlay-title="([^"]*)"/);
    const action = prettyAction(actionBody);

    binds.push({
      keys,
      title: titleMatch ? titleMatch[1] : action,
      action,
      fromTitle: Boolean(titleMatch),
    });
  }

  return binds.sort((a, b) => {
    if (a.fromTitle !== b.fromTitle) return a.fromTitle ? -1 : 1;
    return a.keys.localeCompare(b.keys);
  });
}
