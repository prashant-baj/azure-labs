#!/usr/bin/env node
// Posts AI review findings to a GitLab merge request - one resolvable thread per finding.
// Session 11, layer 3. Runs in the pipeline, or from a laptop for groups without a CI token.
//
// In the pipeline it reads GitLab's own variables. From a laptop, set:
//   GITLAB_URL=https://gitlab.stackroute.in  PROJECT=<project id or group/project>  MR_IID=<number>
//   GITLAB_REVIEW_TOKEN=<a token with api scope>
// Usage:  node ci/post-review.mjs ai-review.json
//
// It never approves or merges. A finding already posted on this merge request is not posted again.

import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";

const file = process.argv[2] || "ai-review.json";
const api = process.env.CI_API_V4_URL || `${(process.env.GITLAB_URL || "").replace(/\/$/, "")}/api/v4`;
const project = encodeURIComponent(process.env.CI_PROJECT_ID || process.env.PROJECT || "");
const mr = process.env.CI_MERGE_REQUEST_IID || process.env.MR_IID;
const token = process.env.GITLAB_REVIEW_TOKEN;

function fail(message) { console.error(`post-review: ${message}`); process.exit(1); }
if (!project || !mr || !token || api === "/api/v4") fail("missing GitLab URL, project, merge request or token");

let findings;
try { findings = JSON.parse(readFileSync(file, "utf8")); } catch (e) { fail(`cannot read ${file}: ${e.message}`); }
if (!Array.isArray(findings)) fail(`${file} is not a JSON array`);

const base = `${api}/projects/${project}/merge_requests/${mr}`;
const headers = { "PRIVATE-TOKEN": token, "Content-Type": "application/json" };

async function call(method, path, body) {
  const res = await fetch(`${base}${path}`, { method, headers, body: body && JSON.stringify(body) });
  if (!res.ok) fail(`${method} ${path} -> ${res.status} ${await res.text()}`);
  return { data: await res.json(), next: res.headers.get("x-next-page") };
}

async function alreadyPosted() {
  const seen = new Set();
  for (let page = "1"; page; ) {
    const { data, next } = await call("GET", `/discussions?per_page=100&page=${page}`);
    for (const d of data) for (const n of d.notes || [])
      for (const m of (n.body || "").matchAll(/<!-- ai-review:([0-9a-f]{12}) -->/g)) seen.add(m[1]);
    page = next;
  }
  return seen;
}

const fingerprint = f => createHash("sha256").update(`${f.rule}|${f.where}|${f.finding}`).digest("hex").slice(0, 12);
const seen = await alreadyPosted();
let posted = 0;
for (const f of findings.slice(0, 15)) {
  const id = fingerprint(f);
  if (seen.has(id)) continue;
  const body = [
    `**AI review · ${f.severity || "?"} · ${f.rule || "no rule"}** · ${f.lens || ""}`,
    `\`${f.where || "?"}\``, "", f.finding || "", "", `*Suggested:* ${f.suggestion || "-"}`, "",
    "_Your group decides: **fix**, **debt** (with a TD- number) or **overruled** (with a reason). Reply, then resolve this thread._",
    `<!-- ai-review:${id} -->`,
  ].join("\n");
  await call("POST", "/discussions", { body });
  posted++;
}
const summary = `**AI review** — ${findings.length} finding(s), ${posted} new thread(s). ` +
  "The full report is in the job's artifacts (`ai-review.md`). The assistant reviews; people decide.";
if (posted > 0) await call("POST", "/notes", { body: summary });   // no new findings, no new noise
console.log(`post-review: ${findings.length} finding(s), ${posted} new thread(s) posted`);
