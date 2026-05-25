#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { Resend } = require('resend');

const RESEND_API_KEY = process.env.RESEND_API_KEY;
const FROM = process.env.USER_EMAIL || 'mubarak@codeswot.me';
const RESOURCES = process.env.RESOURCES_DIR || '/home/node/resources';

if (!RESEND_API_KEY) {
    console.error('RESEND_API_KEY env var is required');
    process.exit(1);
}

const resend = new Resend(RESEND_API_KEY);

function loadAttachments(tier, role) {
    const tier1Cv = path.join(RESOURCES, 'cv_tier1.docx');
    const useTier1 = tier === 1 && fs.existsSync(tier1Cv);
    const isFlutter = /flutter|dart|mobile/i.test(role || '');

    const files = [useTier1 ? 'cv_tier1.docx' : 'cv.docx'];
    if (isFlutter) {
        files.push('recommendation_flutter_plus.pdf');
        files.push('recommendation_flutter.pdf');
    }
    return files
        .map((name) => path.join(RESOURCES, name))
        .filter((p) => fs.existsSync(p))
        .map((p) => ({
            filename: path.basename(p) === 'cv_tier1.docx' ? 'cv.docx' : path.basename(p),
            content: fs.readFileSync(p),
        }));
}

async function readPayload() {
    const idx = process.argv.indexOf('--input');
    if (idx !== -1) {
        return JSON.parse(fs.readFileSync(process.argv[idx + 1], 'utf8'));
    }
    let raw = '';
    for await (const chunk of process.stdin) raw += chunk;
    return JSON.parse(raw);
}

async function main() {
    const payload = await readPayload();
    if (!payload.to || !payload.subject || !(payload.body || payload.html)) {
        console.error('Payload requires {to, subject, body|html}');
        process.exit(1);
    }

    const headers = {};
    if (payload.in_reply_to) headers['In-Reply-To'] = `<${payload.in_reply_to}>`;
    if (payload.references) headers['References'] = payload.references;

    const tier = Number(payload.tier ?? payload.ai_priority_tier ?? 0) || 0;
    const role = payload.role || payload.job_title || payload.subject || '';
    const attachments = payload.skip_attachments ? [] : loadAttachments(tier, role);

    const sendArgs = {
        from: FROM,
        to: payload.to,
        subject: payload.subject,
        attachments,
        headers,
    };
    if (payload.html) sendArgs.html = payload.html;
    if (payload.body) sendArgs.text = payload.body;

    const result = await resend.emails.send(sendArgs);

    process.stdout.write(JSON.stringify({
        ok: !result.error,
        message_id: result.data?.id || null,
        attachments_used: attachments.map((a) => a.filename),
        tier_used: tier,
        error: result.error || null,
    }) + '\n');
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
