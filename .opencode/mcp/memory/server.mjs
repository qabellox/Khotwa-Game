#!/usr/bin/env node
/**
 * Memory MCP - persistent project memory for the Khotwa agent ecosystem.
 *
 * Transport: MCP stdio (JSON-RPC 2.0, one message per line).
 * Storage  : a single JSON file (default <project>/.opencode/memory/store.json).
 *
 * Tools (exposed by OpenCode as memory_*):
 *   remember          store or update a decision / finding / plan / note
 *   recall            search by keyword, tags, kind, importance and recency
 *   get_boot_context  compact markdown block for an agent's first step
 *   status            store path and counts
 *
 * No API key, no network access, no external service. Recall is lexical +
 * tag + importance + recency scoring; it does not call an embedding model.
 */

import { createInterface } from 'node:readline';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(HERE, '..', '..', '..');
const STORE_PATH = path.resolve(
  process.env.MEMORY_DB || path.join(PROJECT_ROOT, '.opencode', 'memory', 'store.json'),
);
const MAX_ENTRIES = 500;
const SERVER_VERSION = '1.0.0';
const KINDS = ['decision', 'finding', 'plan', 'task', 'note', 'asset', 'test'];

let stdinClosed = false;
let store = { version: 1, entries: [] };

function log(...args) {
  process.stderr.write(`[memory] ${args.join(' ')}\n`);
}

function send(message) {
  if (stdinClosed) return;
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function ok(id, result) {
  send({ jsonrpc: '2.0', id, result });
}

function fail(id, code, message) {
  send({ jsonrpc: '2.0', id, error: { code, message } });
}

async function loadStore() {
  try {
    const raw = await fs.readFile(STORE_PATH, 'utf8');
    const parsed = JSON.parse(raw);
    if (!parsed || !Array.isArray(parsed.entries)) throw new Error('invalid store shape');
    store = { version: 1, entries: parsed.entries.filter((entry) => entry && typeof entry.text === 'string') };
  } catch (error) {
    if (error.code !== 'ENOENT') log(`could not read store (${error.message}); starting empty`);
    store = { version: 1, entries: [] };
  }
}

async function saveStore() {
  await fs.mkdir(path.dirname(STORE_PATH), { recursive: true });
  prune();
  const temporary = `${STORE_PATH}.tmp`;
  await fs.writeFile(temporary, `${JSON.stringify(store, null, 2)}\n`, 'utf8');
  await fs.rm(STORE_PATH, { force: true });
  await fs.rename(temporary, STORE_PATH);
}

function prune() {
  if (store.entries.length <= MAX_ENTRIES) return;
  store.entries.sort((a, b) => {
    if (b.importance !== a.importance) return b.importance - a.importance;
    return String(b.updated_at).localeCompare(String(a.updated_at));
  });
  store.entries = store.entries.slice(0, MAX_ENTRIES);
}

function normalize(text) {
  return String(text).toLowerCase().replace(/\s+/g, ' ').trim();
}

function tokenize(text) {
  const matches = String(text).toLowerCase().match(/[\p{L}\p{N}]+/gu) || [];
  return [...new Set(matches.filter((token) => token.length > 1))];
}

function clampInt(value, fallback, min, max, label) {
  if (value === undefined || value === null || value === '') return fallback;
  const number = Number(value);
  if (!Number.isFinite(number) || Math.round(number) !== number) throw new Error(`${label} must be an integer`);
  if (number < min || number > max) throw new Error(`${label} must be between ${min} and ${max}`);
  return number;
}

function sanitizeTags(tags) {
  if (tags === undefined) return [];
  if (!Array.isArray(tags)) throw new Error('tags must be an array of strings');
  return [...new Set(tags.map((tag) => String(tag).trim().toLowerCase()).filter(Boolean))]
    .map((tag) => tag.slice(0, 32))
    .slice(0, 12);
}

function makeId() {
  return `mem_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
}

function validateKind(kind, fallback = 'note') {
  if (kind === undefined || kind === null || kind === '') return fallback;
  const value = String(kind).toLowerCase();
  if (!KINDS.includes(value)) throw new Error(`kind must be one of: ${KINDS.join(', ')}`);
  return value;
}

async function remember(args = {}) {
  const text = String(args.text || '').trim();
  if (!text) throw new Error('text is required');
  if (text.length > 4000) throw new Error('text must be 4000 characters or fewer');
  const kind = validateKind(args.kind, 'note');
  const tags = sanitizeTags(args.tags);
  const importance = clampInt(args.importance, 3, 1, 5, 'importance');
  const source = String(args.source || '').slice(0, 80);
  const now = new Date().toISOString();
  const normalized = normalize(text);
  const existing = store.entries.find((entry) => normalize(entry.text) === normalized);
  if (existing) {
    existing.updated_at = now;
    existing.importance = Math.max(existing.importance, importance);
    existing.tags = [...new Set([...(existing.tags || []), ...tags])].slice(0, 12);
    if (args.kind) existing.kind = kind;
    if (source) existing.source = source;
    await saveStore();
    return { ok: true, id: existing.id, deduped: true, updated_at: existing.updated_at };
  }
  const entry = {
    id: makeId(),
    text,
    kind,
    tags,
    importance,
    source,
    created_at: now,
    updated_at: now,
  };
  store.entries.push(entry);
  await saveStore();
  return { ok: true, id: entry.id, deduped: false, created_at: entry.created_at };
}

function daysSince(iso) {
  const time = Date.parse(iso);
  if (!Number.isFinite(time)) return 3650;
  return Math.max(0, (Date.now() - time) / 86400000);
}

function scoreEntry(entry, queryTokens, queryLower, kind) {
  const textLower = entry.text.toLowerCase();
  const textTokens = new Set(tokenize(entry.text));
  const tags = new Set((entry.tags || []).map((tag) => tag.toLowerCase()));
  let score = 0;
  if (queryLower && textLower.includes(queryLower)) score += 6;
  for (const token of queryTokens) {
    if (textTokens.has(token)) score += 2;
    if ([...tags].some((tag) => tag.includes(token))) score += 1.5;
  }
  if (kind && entry.kind === kind) score += 1;
  score += (entry.importance || 3) * 0.3;
  score += 1 / (1 + daysSince(entry.updated_at) / 30);
  return score;
}

async function recall(args = {}) {
  const query = String(args.query || '').trim();
  if (!query) throw new Error('query is required');
  const limit = clampInt(args.limit, 5, 1, 20, 'limit');
  const kind = args.kind ? validateKind(args.kind) : null;
  const queryLower = query.toLowerCase();
  const queryTokens = tokenize(query);
  const scored = store.entries
    .filter((entry) => !kind || entry.kind === kind)
    .map((entry) => ({ entry, score: scoreEntry(entry, queryTokens, queryLower, kind) }))
    .filter((item) => item.score > 1)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ entry, score }) => ({ ...entry, score: Math.round(score * 100) / 100 }));
  return { ok: true, query, count: scored.length, results: scored };
}

async function getBootContext(args = {}) {
  const limit = clampInt(args.limit, 8, 1, 30, 'limit');
  const entries = [...store.entries]
    .sort((a, b) => {
      if (b.importance !== a.importance) return b.importance - a.importance;
      return String(b.updated_at).localeCompare(String(a.updated_at));
    })
    .slice(0, limit);
  const counts = {};
  for (const entry of store.entries) counts[entry.kind] = (counts[entry.kind] || 0) + 1;
  if (!entries.length) {
    return {
      ok: true,
      count: 0,
      store: STORE_PATH,
      markdown: 'No project memory stored yet. Use memory_remember to record decisions as work proceeds.',
    };
  }
  const lines = [
    '# Project memory boot context',
    '',
    `Store: ${STORE_PATH}`,
    `Entries: ${store.entries.length} (${Object.entries(counts).map(([key, value]) => `${key}: ${value}`).join(', ')})`,
    `Generated: ${new Date().toISOString()}`,
    '',
  ];
  const grouped = new Map();
  for (const entry of entries) {
    if (!grouped.has(entry.kind)) grouped.set(entry.kind, []);
    grouped.get(entry.kind).push(entry);
  }
  for (const [kind, items] of grouped) {
    lines.push(`## ${kind.charAt(0).toUpperCase()}${kind.slice(1)}`);
    for (const entry of items) {
      const tags = (entry.tags || []).length ? ` #${entry.tags.join(' #')}` : '';
      lines.push(`- [${entry.id}] (${entry.updated_at.slice(0, 10)}, importance ${entry.importance}) ${entry.text}${tags}`);
    }
    lines.push('');
  }
  return { ok: true, count: entries.length, store: STORE_PATH, markdown: lines.join('\n').trim() };
}

async function status() {
  const counts = {};
  for (const entry of store.entries) counts[entry.kind] = (counts[entry.kind] || 0) + 1;
  let bytes = 0;
  try {
    bytes = (await fs.stat(STORE_PATH)).size;
  } catch {
    bytes = 0;
  }
  return {
    ok: true,
    server: 'memory',
    version: SERVER_VERSION,
    store: STORE_PATH,
    entries: store.entries.length,
    bytes,
    kinds: counts,
    semantic_embeddings: false,
    recall_strategy: 'lexical + tags + importance + recency',
  };
}

const TOOLS = [
  {
    name: 'remember',
    description:
      'Store a durable project memory: a decision, finding, plan, task, note, asset fact, or test result. Identical text updates the existing entry instead of duplicating it.',
    inputSchema: {
      type: 'object',
      properties: {
        text: { type: 'string', description: 'The fact or decision to remember, self-contained and specific.' },
        kind: { type: 'string', enum: KINDS, default: 'note' },
        tags: { type: 'array', items: { type: 'string' }, description: 'Short searchable tags.' },
        importance: { type: 'integer', minimum: 1, maximum: 5, default: 3 },
        source: { type: 'string', description: 'Who recorded it, e.g. orchestrator or thinker.' },
      },
      required: ['text'],
      additionalProperties: false,
    },
  },
  {
    name: 'recall',
    description:
      'Search stored memory by keyword, tags, kind, importance and recency. Returns the best matching entries with scores.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'What to search for.' },
        limit: { type: 'integer', minimum: 1, maximum: 20, default: 5 },
        kind: { type: 'string', enum: KINDS },
      },
      required: ['query'],
      additionalProperties: false,
    },
  },
  {
    name: 'get_boot_context',
    description:
      'Return a compact markdown block of the most important recent memories. Call this at the start of a task before planning.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'integer', minimum: 1, maximum: 30, default: 8 },
      },
      additionalProperties: false,
    },
  },
  {
    name: 'status',
    description: 'Report the memory store path, entry count and per-kind counts.',
    inputSchema: { type: 'object', properties: {}, additionalProperties: false },
  },
];

let queue = Promise.resolve();
function enqueue(task) {
  const run = queue.then(task, task);
  queue = run.then(() => undefined, () => undefined);
  return run;
}

async function callTool(name, args = {}) {
  switch (name) {
    case 'remember':
      return remember(args);
    case 'recall':
      return recall(args);
    case 'get_boot_context':
      return getBootContext(args);
    case 'status':
      return status();
    default:
      throw new Error(`unknown tool "${name}"`);
  }
}

async function handle(message) {
  const { id, method, params } = message;
  const isNotification = id === undefined || id === null;
  try {
    if (method === 'initialize') {
      ok(id, {
        protocolVersion: params?.protocolVersion || '2025-06-18',
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: 'memory', version: SERVER_VERSION },
        instructions:
          'Persistent project memory for the Khotwa agent ecosystem. At the start of a task call memory_get_boot_context. ' +
          'Record durable decisions, findings and plans with memory_remember, and look them up with memory_recall. ' +
          `Storage: ${STORE_PATH}. No network access and no embeddings.`,
      });
      return;
    }
    if (isNotification) return;
    switch (method) {
      case 'ping':
        ok(id, {});
        return;
      case 'tools/list':
        ok(id, { tools: TOOLS });
        return;
      case 'tools/call': {
        const toolName = params?.name;
        try {
          const result = await enqueue(() => callTool(toolName, params?.arguments || {}));
          ok(id, { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] });
        } catch (error) {
          log(`tool ${toolName} failed: ${error.message}`);
          ok(id, {
            content: [{ type: 'text', text: `Memory error: ${error.message}` }],
            isError: true,
          });
        }
        return;
      }
      case 'resources/list':
        ok(id, { resources: [] });
        return;
      case 'resources/templates/list':
        ok(id, { resourceTemplates: [] });
        return;
      case 'prompts/list':
        ok(id, { prompts: [] });
        return;
      default:
        fail(id, -32601, `method not found: ${method}`);
    }
  } catch (error) {
    if (!isNotification) fail(id, -32603, `internal error: ${error.message}`);
  }
}

await loadStore();
log(`ready; store=${STORE_PATH}; entries=${store.entries.length}`);

const rl = createInterface({ input: process.stdin, crlfDelay: Infinity });
rl.on('line', (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;
  let message;
  try {
    message = JSON.parse(trimmed);
  } catch {
    send({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'parse error' } });
    return;
  }
  void handle(message);
});

rl.on('close', () => {
  stdinClosed = true;
  process.stdout.write('', () => process.exit(0));
});
