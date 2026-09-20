// Izzy's own event endpoint. Everything else on this Worker is the static landing
// page, which `env.ASSETS` serves untouched.
//
// The app posts small batches to POST /e. This handler is deliberately strict: it
// accepts a closed list of event names and a closed shape for their properties, and
// drops anything else on the floor. That is what keeps the privacy claim checkable —
// the endpoint cannot receive a phrase, a note, or a free-text field even if a future
// version of the app tried to send one. No IP address or user agent is read or stored.

const EVENT_NAMES = new Set([
  // Retention and daily use.
  'app_open',
  'goal_completed',
  // What gets used.
  'phrase_learned',
  'phrase_reviewed',
  'listening_started',
  'practice_opened',
  'core_images_opened',
  'stats_opened',
  'search_used',
  // Which settings the people who stay are running.
  'settings',
  // Where the Pro funnel loses people.
  'pro_lock_shown',
  'pro_screen_opened',
  'pro_purchase_started',
  'pro_purchased',
  'pro_purchase_failed',
  'pro_restored',
]);

const MAX_BODY = 64 * 1024;
const MAX_EVENTS = 100;
const MAX_PROPS = 8;
const PROP_KEY = /^[a-z][a-z0-9_]{0,15}$/;
const INSTALL = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
// Anything older than this is a broken clock, not a late flush.
const EARLIEST = Date.UTC(2026, 0, 1) / 1000;

const short = (value, limit) =>
  typeof value === 'string' && value.length > 0 && value.length <= limit ? value : null;

/** Returns the cleaned event, or null if anything about it is unexpected. */
function clean(event, now) {
  if (!event || typeof event !== 'object') return null;
  const name = short(event.n, 32);
  if (!name || !EVENT_NAMES.has(name)) return null;
  const at = event.t;
  // A device clock can be wrong in both directions; keep the event, bound the value.
  if (!Number.isInteger(at) || at < EARLIEST || at > now + 86400) return null;
  const props = {};
  if (event.p != null) {
    if (typeof event.p !== 'object' || Array.isArray(event.p)) return null;
    const keys = Object.keys(event.p);
    if (keys.length > MAX_PROPS) return null;
    for (const key of keys) {
      if (!PROP_KEY.test(key)) return null;
      // String values only: a number or an object could carry more than it looks like.
      const value = short(event.p[key], 32);
      if (value === null) return null;
      props[key] = value;
    }
  }
  return { name, at, props };
}

async function collect(request, env) {
  const length = Number(request.headers.get('content-length') ?? 0);
  if (length > MAX_BODY) return new Response(null, { status: 413 });
  const text = await request.text();
  if (text.length > MAX_BODY) return new Response(null, { status: 413 });

  let body;
  try {
    body = JSON.parse(text);
  } catch {
    return new Response(null, { status: 400 });
  }
  if (!body || typeof body !== 'object') return new Response(null, { status: 400 });
  const install = short(body.install, 36);
  if (!install || !INSTALL.test(install)) return new Response(null, { status: 400 });
  if (!Array.isArray(body.events) || body.events.length === 0) return new Response(null, { status: 400 });
  if (body.events.length > MAX_EVENTS) return new Response(null, { status: 413 });

  const now = Math.floor(Date.now() / 1000);
  const app = short(body.app, 32);
  const os = short(body.os, 16);
  const device = short(body.device, 16);
  const lang = short(body.lang, 8);

  const insert = env.izzy_events.prepare(
    'INSERT INTO events (install, name, at, received_at, app, os, device, lang, props) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
  );
  const rows = [];
  for (const event of body.events) {
    const ok = clean(event, now);
    // One malformed event does not cost the batch the rest of its events.
    if (!ok) continue;
    rows.push(insert.bind(install, ok.name, ok.at, now, app, os, device, lang, JSON.stringify(ok.props)));
  }
  if (rows.length === 0) return new Response(null, { status: 400 });

  try {
    await env.izzy_events.batch(rows);
  } catch {
    // 500 rather than 204: the app keeps the batch and tries again later.
    return new Response(null, { status: 500 });
  }
  return new Response(null, { status: 204 });
}

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (pathname === '/e') {
      if (request.method !== 'POST') return new Response(null, { status: 405, headers: { allow: 'POST' } });
      return collect(request, env);
    }
    return env.ASSETS.fetch(request);
  },
};
