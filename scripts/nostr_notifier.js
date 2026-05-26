#!/usr/bin/env node
'use strict';

const fs = require('fs');

const RELAYS = (process.env.NOSTR_RELAYS || 'wss://relay.damus.io,wss://relay.primal.net,wss://nos.lol').split(',').map(s => s.trim()).filter(Boolean);

const CONFIG = {
    nsec: process.env.NOSTR_NSEC || '',
    targetNpub: process.env.NOSTR_TARGET_NPUB || '',
    queuePath: process.env.WA_QUEUE_PATH || '/tmp/jhound_wa_queue.json',
    briefBatchPath: process.env.WA_BRIEF_BATCH_PATH || '/tmp/jhound_wa_brief_batch.json',
};

function _checkConfig() {
    if (!CONFIG.nsec) throw new Error('NOSTR_NSEC env var is required');
}

async function sendMessage(text) {
    const { Relay, getPublicKey, nip19 } = require('nostr-tools');
    const { getConversationKey, encrypt: nip44Encrypt } = require('nostr-tools/nip44');
    const { createGiftWrap } = require('nostr-tools/nip59');

    _checkConfig();

    const sk = nip19.decode(CONFIG.nsec).data;
    const pk = getPublicKey(sk);
    const targetPub = CONFIG.targetNpub ? nip19.decode(CONFIG.targetNpub).data : pk;

    const convKey = getConversationKey(sk, targetPub);
    const encrypted = nip44Encrypt(text, convKey);

    const rumor = {
        kind: 14,
        created_at: Math.floor(Date.now() / 1000),
        tags: [['p', targetPub]],
        content: encrypted,
    };

    const giftWrap = await createGiftWrap(rumor, targetPub);

    const results = [];
    for (const url of RELAYS) {
        let relay = null;
        try {
            relay = await Relay.connect(url);
            await relay.publish(giftWrap);
            results.push({ url, ok: true });
        } catch (err) {
            results.push({ url, ok: false, error: err.message });
        } finally {
            try { relay && relay.close(); } catch {}
        }
    }
    return results;
}

class NostrNotifier {
    constructor() {
        this.queue = this._loadQueue();
    }

    _loadQueue() {
        try { return JSON.parse(fs.readFileSync(CONFIG.queuePath, 'utf8')); } catch { return []; }
    }

    _saveQueue() {
        fs.writeFileSync(CONFIG.queuePath, JSON.stringify(this.queue, null, 2));
    }

    async send(text) {
        if (!text) return { status: 'skipped', reason: 'empty_message' };
        try {
            const results = await sendMessage(text);
            const ok = results.filter(r => r.ok).length;
            return { status: ok > 0 ? 'sent' : 'failed', relays: results };
        } catch (err) {
            this.queue.push({ text, ts: new Date().toISOString(), attempts: 0 });
            this._saveQueue();
            throw err;
        }
    }

    async drainQueue() {
        while (this.queue.length) {
            const item = this.queue.shift();
            try { await this.send(item.text); } catch (err) {
                if (item.attempts < 3) { item.attempts += 1; this.queue.push(item); }
            }
            this._saveQueue();
            await new Promise(r => setTimeout(r, 1500));
        }
    }
}

const fmt = {
    dailySummary(s) {
        const companies = (s.companies || []).slice(0, 6).map((c) => `   • ${c}`).join('\n');
        const lines = [
            '🎯 jHound Update',
            '',
            `✅ Today: ${s.total_today ?? 0}`,
            `   • Easy Apply: ${s.easy_apply_count ?? 0}`,
            `   • Email Sent: ${s.email_count ?? 0}`,
            `   • Manual (no email): ${s.manual_count ?? 0}`,
            `   • Tier 1: ${s.tier1_count ?? 0}  •  Tier 2: ${s.tier2_count ?? 0}`,
            '',
            '🏢 Today\'s Companies:',
            companies || '   • (none)',
            '',
            `📊 This Week: ${s.week_total ?? 0}`,
            `   • Easy Apply: ${s.week_easy_apply ?? 0}`,
            `   • Email Sent: ${s.week_email ?? 0}`,
            `   • Manual (no email): ${s.week_manual ?? 0}`,
            `   • Tier 1: ${s.week_tier1 ?? 0}  •  Tier 2: ${s.week_tier2 ?? 0}`,
            `   • Responses: ${s.week_responses ?? 0}`,
            '',
            `📈 Response Rate (all-time): ${s.response_rate ?? 0}%`,
        ];
        const h = s.hunter;
        if (h && typeof h === 'object') {
            lines.push(
                '',
                '🎯 Hunter.io budget',
                `   • This week: ${h.week_used}/${h.week_limit} verifications`,
                `   • This month: ${h.month_used}/${h.month_limit}  (${h.month_credits_used}/${(h.month_limit * 0.5).toFixed(0)} credits used)`,
                `   • Remaining: ${h.month_credits_remaining} credits this month`,
            );
        }
        return lines.join('\n');
    },
    jobAlert(payload) {
        const j = payload?.job ?? payload ?? {};
        const r = payload?.research ?? null;
        const hasResearch = r && typeof r === 'object' && Object.keys(r).length > 0;
        const lines = ['🔔 New Application', '', `${j.job_title} — ${j.company}`,
            `Method: ${j.application_method}  |  Tier: ${j.ai_priority_tier ?? '-'}  |  Score: ${j.ai_job_match_score ?? '-'}`];
        if (hasResearch) {
            if (r.one_liner) lines.push('', `What they do: ${r.one_liner}`);
            const meta = [];
            if (r.industry) meta.push(r.industry);
            if (r.size_hint) meta.push(r.size_hint);
            if (r.hq_location) meta.push(r.hq_location);
            if (meta.length) lines.push(meta.join('  •  '));
            if (r.tech_stack?.length) lines.push(`🛠 ${r.tech_stack.slice(0, 6).join(', ')}`);
        } else {
            lines.push('', '⚠️ No research available');
        }
        lines.push('', j.job_url || '');
        return lines.join('\n');
    },
    companyBrief(payload) {
        const { job = {}, research = {} } = payload;
        const lines = [`🏢 Applied: ${job.company || research.company || '—'}`, `${job.job_title || ''}`, ''];
        if (research.one_liner) lines.push(`What they do: ${research.one_liner}`);
        if (research.summary) lines.push('', research.summary);
        const meta = [];
        if (research.industry) meta.push(`Industry: ${research.industry}`);
        if (research.size_hint) meta.push(`Size: ${research.size_hint}`);
        if (research.funding_hint && research.funding_hint !== 'unknown') meta.push(`Stage: ${research.funding_hint}`);
        if (research.hq_location) meta.push(`HQ: ${research.hq_location}`);
        if (meta.length) lines.push('', meta.join('  •  '));
        if (research.tech_stack?.length) lines.push('', `🛠 ${research.tech_stack.slice(0, 6).join(', ')}`);
        const links = [];
        if (research.website) links.push(`🌐 ${research.website}`);
        if (research.linkedin) links.push(`💼 ${research.linkedin}`);
        if (research.github) links.push(`🐙 ${research.github}`);
        if (research.twitter) links.push(`🐦 ${research.twitter}`);
        if (links.length) lines.push('', links.join('\n'));
        if (job.job_url) lines.push('', `📄 Job: ${job.job_url}`);
        return lines.join('\n');
    },
    responseAlert(r) {
        const emoji = { rejection: '❌', interview: '🎯', offer: '🏆', recruiter: '👀', generic: '📨' }[r.classification] || '📨';
        return [`${emoji} Reply received: ${r.classification}`, '', `${r.company} — ${r.job_title || ''}`,
            `From: ${r.from_email}`, `Subject: ${r.subject || '(no subject)'}`, '', (r.snippet || '').slice(0, 400)].join('\n');
    },
    fastApplyLink(payload) {
        const j = payload?.job ?? payload ?? {};
        const r = payload?.research ?? {};
        const tier = j.ai_priority_tier ?? '-';
        const score = j.ai_job_match_score ?? '-';
        const lines = ['⚡ Fast-apply (Easy Apply detected)', '', `${j.job_title} — ${j.company}`,
            `Tier ${tier}  •  Score ${score}/100  •  ${j.source_board || ''}`];
        if (r.one_liner) lines.push('', `${r.one_liner}`);
        if (r.industry || r.tech_stack?.length) {
            const meta = [];
            if (r.industry) meta.push(r.industry);
            if (r.tech_stack?.length) meta.push(r.tech_stack.slice(0, 5).join(', '));
            lines.push(meta.join('  •  '));
        }
        lines.push('', `One-click apply: ${j.job_url}`, '', 'Open, click Easy Apply, answer screening Qs.');
        return lines.join('\n');
    },
    manualDigest(jobs) {
        if (!jobs?.length) return '✅ Manual queue: empty';
        const head = `📋 Manual review needed (${jobs.length})\n`;
        const body = jobs.slice(0, 10).map((j, i) =>
            `${i + 1}. ${j.job_title} — ${j.company}  (T${j.ai_priority_tier ?? '-'}/${j.ai_job_match_score ?? '-'})\n   ${j.status}  ${j.job_url}`,
        ).join('\n\n');
        return head + '\n' + body;
    },
    weeklyJobsBatch(jobs) {
        if (!jobs?.length) return '📭 No jobs this week.';
        const groups = { 1: [], 2: [], other: [] };
        for (const j of jobs) (groups[j.ai_priority_tier] || groups.other).push(j);
        const formatOne = (j, idx) => {
            const tier = j.ai_priority_tier ?? '-';
            const score = j.ai_job_match_score ?? '-';
            const lines = [`${idx + 1}. [T${tier} • ${score}] ${j.job_title} — ${j.company}`];
            if (j.one_liner) lines.push(`   ${j.one_liner.slice(0, 140)}`);
            const meta = [];
            if (j.industry) meta.push(j.industry);
            if (j.hq_location) meta.push(j.hq_location);
            if (j.tech_stack?.length) meta.push(j.tech_stack.slice(0, 4).join(', '));
            if (meta.length) lines.push(`   ${meta.join(' • ')}`);
            const status = `${j.application_method}${j.status ? ` • ${j.status}` : ''}`;
            lines.push(`   ${status}`);
            if (j.hiring_manager_email) lines.push(`   ✉  ${j.hiring_manager_name ? j.hiring_manager_name + ' — ' : ''}${j.hiring_manager_email}`);
            if (j.website) lines.push(`   🌐 ${j.website}`);
            if (j.job_url) lines.push(`   📄 ${j.job_url}`);
            return lines.join('\n');
        };
        const sections = [];
        const head = `📦 jHound Weekly Jobs (${jobs.length})`;
        if (groups[1].length) sections.push(`\n— Tier 1 (${groups[1].length}) —\n` + groups[1].map(formatOne).join('\n\n'));
        if (groups[2].length) sections.push(`\n— Tier 2 (${groups[2].length}) —\n` + groups[2].map(formatOne).join('\n\n'));
        if (groups.other.length) sections.push(`\n— Untagged (${groups.other.length}) —\n` + groups.other.map(formatOne).join('\n\n'));
        return `${head}\n${sections.join('\n')}`;
    },
    batchedTier2(briefs) {
        if (!briefs?.length) return '📭 No tier-2 applications today.';
        const head = `📦 Tier-2 Applications Today (${briefs.length})\nBundled to keep the spam down.`;
        const items = briefs.map((b, i) => {
            const j = b.job || {};
            const r = b.research || {};
            const tag = r.one_liner ? `${r.one_liner.slice(0, 80)}` : '';
            return `${i + 1}. ${j.company || r.company || '—'} — ${j.job_title || ''}\n   ${tag}\n   ${r.website || j.job_url || ''}`;
        }).join('\n\n');
        return `${head}\n\n${items}`;
    },
    errorAlert(e) {
        const wf = e.workflow_name || e.workflow || '(unknown workflow)';
        const node = e.failed_node || e.node || '(unknown node)';
        const msg = (e.error_message || e.message || '').slice(0, 400);
        const execId = e.execution_id ? `\nexec: ${e.execution_id}` : '';
        return ['🚨 jHound workflow error', '', `Workflow: ${wf}`, `Node: ${node}`, '', msg || '(no message)', execId].join('\n');
    },
};

async function readStdin() {
    let raw = '';
    for await (const chunk of process.stdin) raw += chunk;
    return raw || '{}';
}

function appendTier2Batch(payload) {
    let batch = [];
    try { batch = JSON.parse(fs.readFileSync(CONFIG.briefBatchPath, 'utf8')); } catch {}
    batch.push({ ts: new Date().toISOString(), ...payload });
    fs.writeFileSync(CONFIG.briefBatchPath, JSON.stringify(batch, null, 2));
    return batch.length;
}

function popTier2Batch() {
    let batch = [];
    try { batch = JSON.parse(fs.readFileSync(CONFIG.briefBatchPath, 'utf8')); } catch { return []; }
    try { fs.unlinkSync(CONFIG.briefBatchPath); } catch {}
    return batch;
}

async function main() {
    const [, , cmd, ...rest] = process.argv;
    let notifier = null;
    const getNotifier = () => {
        if (!notifier) notifier = new NostrNotifier();
        return notifier;
    };

    try {
        switch (cmd) {
            case 'keygen': {
                const { generateSecretKey, getPublicKey, nip19 } = require('nostr-tools');
                const sk = generateSecretKey();
                const pk = getPublicKey(sk);
                console.log(JSON.stringify({ nsec: nip19.nsecEncode(sk), npub: nip19.npubEncode(pk) }));
                break;
            }
            case 'send': {
                let text = rest.join(' ').trim();
                if (!text || text === '-') text = (await readStdin()).trim();
                await getNotifier().send(text);
                await getNotifier().drainQueue();
                break;
            }
            case 'daily-summary':
                await getNotifier().send(fmt.dailySummary(JSON.parse(rest[0] || '{}')));
                await getNotifier().drainQueue();
                break;
            case 'job-alert':
                await getNotifier().send(fmt.jobAlert(JSON.parse(rest[0] || '{}')));
                await getNotifier().drainQueue();
                break;
            case 'fast-apply-link': {
                const payload = rest[0] ? JSON.parse(rest[0]) : JSON.parse(await readStdin());
                await getNotifier().send(fmt.fastApplyLink(payload));
                await getNotifier().drainQueue();
                break;
            }
            case 'company-brief': {
                const payload = rest[0] ? JSON.parse(rest[0]) : JSON.parse(await readStdin());
                await getNotifier().send(fmt.companyBrief(payload));
                await getNotifier().drainQueue();
                break;
            }
            case 'company-brief-auto': {
                const payload = rest[0] ? JSON.parse(rest[0]) : JSON.parse(await readStdin());
                const tier = payload?.job?.ai_priority_tier ?? payload?.research?.tier ?? 2;
                if (Number(tier) === 1) {
                    await getNotifier().send(fmt.companyBrief(payload));
                    await getNotifier().drainQueue();
                    console.log(JSON.stringify({ status: 'sent', tier: 1 }));
                } else {
                    const queued = appendTier2Batch(payload);
                    console.log(JSON.stringify({ status: 'batched', tier: Number(tier), queued }));
                }
                break;
            }
            case 'weekly-jobs': {
                const payload = rest[0] ? JSON.parse(rest[0]) : JSON.parse(await readStdin());
                const jobs = Array.isArray(payload) ? payload : (payload.rows || payload.jobs || []);
                const text = fmt.weeklyJobsBatch(jobs);
                const MAX = 3500;
                if (text.length <= MAX) {
                    await getNotifier().send(text);
                } else {
                    const parts = [];
                    let buf = '';
                    for (const block of text.split('\n\n')) {
                        if ((buf + '\n\n' + block).length > MAX) { parts.push(buf); buf = block; }
                        else { buf = buf ? buf + '\n\n' + block : block; }
                    }
                    if (buf) parts.push(buf);
                    for (let i = 0; i < parts.length; i++) {
                        await getNotifier().send(`(${i + 1}/${parts.length})\n${parts[i]}`);
                        await new Promise(r => setTimeout(r, 800));
                    }
                }
                await getNotifier().drainQueue();
                console.log(JSON.stringify({ status: 'sent', jobs: jobs.length }));
                break;
            }
            case 'flush-tier2-batch': {
                const batch = popTier2Batch();
                if (!batch.length) { console.log(JSON.stringify({ status: 'empty' })); break; }
                await getNotifier().send(fmt.batchedTier2(batch));
                await getNotifier().drainQueue();
                console.log(JSON.stringify({ status: 'sent', count: batch.length }));
                break;
            }
            case 'response-alert':
                await getNotifier().send(fmt.responseAlert(JSON.parse(rest[0] || '{}')));
                await getNotifier().drainQueue();
                break;
            case 'error-alert': {
                const payload = rest[0] ? JSON.parse(rest[0]) : JSON.parse(await readStdin());
                await getNotifier().send(fmt.errorAlert(payload));
                await getNotifier().drainQueue();
                break;
            }
            case 'manual-digest': {
                const payload = rest[0] ? JSON.parse(rest[0]) : JSON.parse(await readStdin());
                await getNotifier().send(fmt.manualDigest(payload));
                await getNotifier().drainQueue();
                break;
            }
            case 'listen':
                await listenForDMs(rest[0] || '');
                break;
            default:
                console.log('Usage: keygen | send | listen | daily-summary | job-alert | fast-apply-link | company-brief | company-brief-auto | flush-tier2-batch | response-alert | error-alert | manual-digest');
                process.exit(1);
        }
    } catch (err) {
        console.error(err.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

async function listenForDMs(webhookUrl) {
    const { Relay, getPublicKey, nip19, nip04 } = require('nostr-tools');
    const { getConversationKey, decrypt: nip44Decrypt } = require('nostr-tools/nip44');

    _checkConfig();
    const sk = nip19.decode(CONFIG.nsec).data;
    const ownPk = getPublicKey(sk);
    const senderPub = CONFIG.targetNpub ? nip19.decode(CONFIG.targetNpub).data : ownPk;
    const baseUrl = webhookUrl ? webhookUrl.replace(/\/webhook\/.*$/, '') : (process.env.N8N_INTERNAL_URL || 'http://localhost:5678');
    const hookUrl = webhookUrl && webhookUrl.includes('/webhook/') ? webhookUrl : `${baseUrl}/webhook/jhound-nostr-inbound`;

    const convKey = getConversationKey(sk, senderPub);
    const LOOKBACK_SEC = 600;
    const seen = new Set();
    let sinceFloor = Math.floor(Date.now() / 1000) - LOOKBACK_SEC;

    console.log(`[nostr-inbound] listening for DMs to ${ownPk} from ${senderPub}`);
    console.log(`[nostr-inbound] webhook target: ${hookUrl}`);

    async function postWebhook(payload, attempt = 1) {
        try {
            const res = await fetch(hookUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload),
            });
            console.log(`[nostr-inbound] posted ${res.status} ${res.statusText}`);
            return true;
        } catch (err) {
            if (attempt >= 6) {
                console.error(`[nostr-inbound] webhook gave up after ${attempt} tries: ${err.message}`);
                return false;
            }
            const wait = Math.min(1000 * 2 ** (attempt - 1), 15000);
            console.error(`[nostr-inbound] webhook retry ${attempt} in ${wait}ms: ${err.message}`);
            await new Promise(r => setTimeout(r, wait));
            return postWebhook(payload, attempt + 1);
        }
    }

    async function handleEvent(event) {
        if (seen.has(event.id)) return;
        seen.add(event.id);
        if (event.created_at > sinceFloor) sinceFloor = event.created_at;
        if (seen.size > 5000) {
            const keep = Array.from(seen).slice(-2500);
            seen.clear();
            for (const id of keep) seen.add(id);
        }
        try {
            let text;
            let fromPub = event.pubkey;

            if (event.kind === 1059) {
                const ephemKey = getConversationKey(sk, event.pubkey);
                const sealedJson = nip44Decrypt(event.content, ephemKey).trim();
                const rumor = JSON.parse(sealedJson);
                fromPub = rumor.pubkey || event.pubkey;
                text = nip44Decrypt(rumor.content, getConversationKey(sk, fromPub)).trim();
            } else if (event.kind === 14) {
                text = nip44Decrypt(event.content, convKey).trim();
            } else if (event.kind === 4) {
                text = (await nip04.decrypt(sk, event.pubkey, event.content)).trim();
            } else {
                return;
            }
            if (!text) return;
            console.log(`[nostr-inbound] DM kind=${event.kind}: ${text.slice(0, 200)}`);
            await postWebhook({ from: fromPub, text, id: event.id });
        } catch (err) {
            console.error(`[nostr-inbound] decrypt error (kind=${event.kind}): ${err.message}`);
        }
    }

    async function connectAndListen(url) {
        let backoff = 1000;
        for (;;) {
            try {
                const relay = await Relay.connect(url);
                console.log(`[nostr-inbound] connected ${url}`);
                backoff = 1000;
                await new Promise((resolve) => {
                    const sub = relay.subscribe(
                        [{ kinds: [4, 14, 1059], '#p': [ownPk], since: sinceFloor - LOOKBACK_SEC }],
                        {
                            onevent: handleEvent,
                            oneose: () => console.log(`[nostr-inbound] ${url} eose`),
                            onclose: () => { console.log(`[nostr-inbound] ${url} sub closed`); resolve(); },
                        },
                    );
                    relay._on?.('disconnect', resolve);
                    relay.onclose = () => { console.log(`[nostr-inbound] ${url} relay closed`); try { sub.close(); } catch {} resolve(); };
                });
            } catch (err) {
                console.error(`[nostr-inbound] ${url} error: ${err.message}`);
            }
            await new Promise(r => setTimeout(r, backoff));
            backoff = Math.min(backoff * 2, 30000);
            console.log(`[nostr-inbound] reconnecting ${url}`);
        }
    }

    for (const url of RELAYS) connectAndListen(url).catch(e => console.error(`[nostr-inbound] ${url} fatal: ${e.message}`));
    await new Promise(() => {});
}

module.exports = { NostrNotifier, fmt, listenForDMs };
