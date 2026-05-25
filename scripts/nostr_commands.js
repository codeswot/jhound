#!/usr/bin/env node
'use strict';

const { spawn } = require('child_process');
const { NostrNotifier, fmt } = require('./nostr_notifier');

const DB_PY = '/home/node/scripts/db.py';
const N8N_BASE = process.env.N8N_INTERNAL_URL || 'http://localhost:5678';

const HELP_TEXT = [
    '🤖 jHound — commands',
    '',
    '📊 Reports',
    '  • daily / status / today  — today + week stats',
    '  • weekly / digest         — full weekly summary',
    '  • <keyword> jobs          — filter (e.g. "flutter jobs", "bitcoin")',
    '',
    '🚀 Actions',
    '  • discover / find / hunt  — start a discovery run now',
    '  • applied <n>             — mark queued job N as applied',
    '  • skip <n>                — skip queued job N',
    '',
    '🛠 Other',
    '  • ping                    — health check (replies pong)',
    '  • help / commands         — this message',
].join('\n');

function dbQuery(name, args) {
    const payload = JSON.stringify({ name, args: args || {} });
    return new Promise((resolve, reject) => {
        const proc = spawn('python3', [DB_PY, 'query']);
        let stdout = '', stderr = '';
        proc.stdout.on('data', (d) => (stdout += d));
        proc.stderr.on('data', (d) => (stderr += d));
        proc.stdin.write(payload);
        proc.stdin.end();
        proc.on('close', (code) => {
            if (code !== 0) return reject(new Error(stderr || `db.py exit ${code}`));
            try { resolve(JSON.parse(stdout)); } catch (e) { reject(new Error(`db.py bad json: ${e.message}`)); }
        });
    });
}

function parseIntent(text) {
    const t = (text || '').trim().toLowerCase().replace(/[?.!,]+$/, '');
    if (!t) return { command: 'unknown' };
    if (/^(ping|test|hi|hello)$/.test(t)) return { command: 'ping' };
    if (/^(help|commands|menu|\?|what can you do)/.test(t)) return { command: 'help' };
    if (/(weekly|week summary|week digest|digest|sunday)/.test(t)) return { command: 'weekly' };
    if (/(discover|find new|hunt|scrape|new jobs|search jobs|run discovery|go hunting)/.test(t)) return { command: 'discover' };
    if (/(daily|today|status|summary|update|stats)/.test(t)) return { command: 'daily' };
    let m;
    if ((m = t.match(/^applied\s+(\d+)/))) return { command: 'applied', arg: Number(m[1]) };
    if ((m = t.match(/^skip\s+(\d+)/))) return { command: 'skip', arg: Number(m[1]) };
    if ((m = t.match(/^(?:show me |give me |find |list |get )?(.+?)\s+jobs?$/))) return { command: 'keyword', arg: m[1].trim() };
    if ((m = t.match(/^jobs?\s+(?:about|matching|in|with|for|on)\s+(.+)$/))) return { command: 'keyword', arg: m[1].trim() };
    if (/^[\w+#.-]{2,30}$/.test(t)) return { command: 'keyword', arg: t };
    return { command: 'unknown', arg: t };
}

async function sendChunked(notifier, text, headPrefix) {
    const MAX = 3500;
    if (text.length <= MAX) { await notifier.send(headPrefix ? `${headPrefix}\n\n${text}` : text); return; }
    const parts = [];
    let buf = '';
    for (const block of text.split('\n\n')) {
        if ((buf + '\n\n' + block).length > MAX) { parts.push(buf); buf = block; }
        else { buf = buf ? buf + '\n\n' + block : block; }
    }
    if (buf) parts.push(buf);
    for (let i = 0; i < parts.length; i++) {
        const head = headPrefix && i === 0 ? `${headPrefix}\n\n` : '';
        await notifier.send(`(${i + 1}/${parts.length})\n${head}${parts[i]}`);
        await new Promise((r) => setTimeout(r, 800));
    }
}

async function handleDaily(notifier) {
    const res = await dbQuery('today_stats');
    const row = (res.rows && res.rows[0]) || {};
    let hunter = null;
    try {
        const q = await new Promise((resolve, reject) => {
            const proc = spawn('python3', ['/home/node/scripts/email_finder.py', '--quota']);
            let out = '';
            proc.stdout.on('data', (d) => (out += d));
            proc.on('close', () => { try { resolve(JSON.parse(out)); } catch { resolve(null); } });
            proc.on('error', reject);
        });
        hunter = q && q.hunter ? q.hunter : null;
    } catch {}
    await notifier.send(fmt.dailySummary({ ...row, hunter }));
}

async function handleWeekly(notifier) {
    const stats = await dbQuery('weekly_digest');
    const totals = stats.rows?.[0]?.totals || {};
    const summary = [
        '📊 jHound Weekly Summary',
        '',
        `Total: ${totals.total ?? 0}`,
        `Tier 1: ${totals.tier1 ?? 0}  •  Tier 2: ${totals.tier2 ?? 0}`,
        `Email Sent: ${totals.email_sent ?? 0}`,
        `Easy Apply: ${totals.easy_apply ?? 0}`,
        `Manual: ${totals.manual ?? 0}`,
        `Responses: ${totals.responses ?? 0}`,
    ].join('\n');
    await notifier.send(summary);
    const jobs = await dbQuery('weekly_jobs');
    const jobsArr = jobs.rows || [];
    if (jobsArr.length) await sendChunked(notifier, fmt.weeklyJobsBatch(jobsArr));
}

async function handleKeyword(notifier, keyword) {
    const pat = `%${keyword.toLowerCase()}%`;
    const res = await dbQuery('jobs_by_keyword', { pat });
    const rows = res.rows || [];
    if (!rows.length) { await notifier.send(`🔍 No matches for "${keyword}".`); return; }
    const text = fmt.weeklyJobsBatch(rows);
    await sendChunked(notifier, text, `🔍 "${keyword}" — ${rows.length} match${rows.length === 1 ? '' : 'es'}`);
}

async function handleDiscover(notifier) {
    await notifier.send('🔎 Discovering the latest opportunities. I will let you know when it\'s ready.');
    try {
        const res = await fetch(`${N8N_BASE}/webhook/jhound-discover`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ source: 'nostr', triggered_at: new Date().toISOString() }),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
    } catch (err) {
        await notifier.send(`⚠️ Could not start discovery: ${err.message}`);
    }
}

async function handleApplied(notifier, n) {
    await notifier.send(`✅ Noted: job #${n} marked applied. (manual-queue wiring pending)`);
}

async function handleSkip(notifier, n) {
    await notifier.send(`⏭ Noted: job #${n} skipped. (manual-queue wiring pending)`);
}

async function main() {
    let raw = '';
    for await (const chunk of process.stdin) raw += chunk;
    const payload = JSON.parse(raw || '{}');
    const body = payload.body || payload;
    const text = body.text || body.message || '';

    const notifier = new NostrNotifier();
    const intent = parseIntent(text);
    console.log(JSON.stringify({ intent, text }));

    try {
        switch (intent.command) {
            case 'ping': await notifier.send('🏓 pong'); break;
            case 'help': await notifier.send(HELP_TEXT); break;
            case 'daily': await handleDaily(notifier); break;
            case 'weekly': await handleWeekly(notifier); break;
            case 'discover': await handleDiscover(notifier); break;
            case 'keyword': await handleKeyword(notifier, intent.arg); break;
            case 'applied': await handleApplied(notifier, intent.arg); break;
            case 'skip': await handleSkip(notifier, intent.arg); break;
            default:
                await notifier.send(`🤔 Didn't understand: "${text.slice(0, 80)}"\n\nReply *help* to see what I can do.`);
                break;
        }
        await notifier.drainQueue();
    } catch (err) {
        console.error('command handler error:', err.message);
        try { await notifier.send(`⚠️ Command failed: ${err.message.slice(0, 200)}`); } catch {}
        process.exit(1);
    }
}

if (require.main === module) main();

module.exports = { parseIntent };
