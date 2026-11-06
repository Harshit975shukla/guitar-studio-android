// Shared helpers for the login, sign-up, account and admin pages. No inline scripts (strict CSP).

const OFFLINE = 'No connection to the server. Please check your internet and try again.';

// "Save my progress": the app's practice data that is also kept in the student's account. The same list is in
// src/ui/progressSync.ts and server/src/progress.mjs (npm run test:progress checks they match).
export const PROGRESS_KEYS = [
  'guitar_studio_profiles',
  'guitar_studio_active_id',
  'guitar_studio_practice_sessions',
  'guitar_studio_custom_songs',
  'gcs-chord-game-v1',
  'gcs-chord-player-v1',
  'gcs-chord-player-stage',
  'gcs-backing-v1',
  'guitar-studio-grooves-v1',
  'gcs-guitar-look',
  'gcs-song-show-next',
  // Practice plan, quizzes and Learn lessons
  'gcs-learn-results-v1',
  'gcs-plan-v1',
  'gcs-plan-history-v1',
  'gcs-fretboard-v1',
  'gcs-rhythm-quiz-v1',
  'gcs-ear-quiz-v1',
  'gcs-scale-quiz-v1',
  'gcs-learn-v1',
];
const SYNC_META_KEY = 'gcs-sync-meta';
const SYNC_CLEAR_KEY = 'gcs-sync-clear';
/** Written after a logout cleared this device: whatever a stale app page writes later is never taken as anyone's progress. */
const LOGGED_OUT_META = JSON.stringify({ userId: 'logged-out', updatedAt: 0, hash: '', dirty: false });

function removeProgress() {
  for (const key of PROGRESS_KEYS) localStorage.removeItem(key);
  localStorage.setItem(SYNC_META_KEY, LOGGED_OUT_META);
  sessionStorage.removeItem('gcs-sync-pending');
  sessionStorage.removeItem('gcs-sync-reloaded');
}

/** After a logout (the app sets the marker): remove the practice data, so the next person on this computer starts clean. */
export function clearProgressAfterLogout() {
  try {
    if (!localStorage.getItem(SYNC_CLEAR_KEY)) return;
    removeProgress();
    localStorage.removeItem(SYNC_CLEAR_KEY);
  } catch { /* storage blocked: nothing was saved here either */ }
}

/** Logout from a server page (account, admin): the login page then removes the practice data. */
export function markLoggedOut() {
  try { localStorage.setItem(SYNC_CLEAR_KEY, '1'); } catch { /* storage blocked */ }
}

/** After "delete my account": remove the practice data from this device at once. */
export function forgetThisDevice() {
  try {
    removeProgress();
    localStorage.removeItem(SYNC_CLEAR_KEY);
  } catch { /* storage blocked: nothing was saved here either */ }
}

/** After a login: practice data on this device that belongs to ANOTHER student is removed before the app opens. */
export function forgetOtherStudent(userId) {
  try {
    const meta = JSON.parse(localStorage.getItem(SYNC_META_KEY) || 'null');
    if (meta && typeof meta.userId === 'string' && meta.userId && meta.userId !== userId) removeProgress();
  } catch { /* storage blocked or unreadable meta: the app checks again */ }
}

/** POST JSON to our API. Always sends a JSON body (the server only accepts JSON). */
export async function post(path, body = {}) {
  try {
    const response = await fetch(path, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify(body),
    });
    return { status: response.status, data: await response.json().catch(() => ({})) };
  } catch {
    return { status: 0, data: { error: OFFLINE } };
  }
}

export async function get(path) {
  try {
    const response = await fetch(path, { credentials: 'same-origin', headers: { Accept: 'application/json' }, cache: 'no-store' });
    return { status: response.status, data: await response.json().catch(() => ({})) };
  } catch {
    return { status: 0, data: { error: OFFLINE } };
  }
}

/** Shows one message in the page's error (role=alert) or status (role=status) line and clears the other. */
export function say(root, text, kind = 'error') {
  const error = root.querySelector('[data-error]');
  const status = root.querySelector('[data-status]');
  if (error) error.textContent = kind === 'error' ? text : '';
  if (status) status.textContent = kind === 'error' ? '' : text;
}

export function busy(button, on, label) {
  if (!button) return;
  if (on) {
    button.dataset.label ??= button.textContent;
    button.textContent = label || 'Please wait…';
  } else if (button.dataset.label) {
    button.textContent = button.dataset.label;
  }
  button.disabled = on;
  button.setAttribute('aria-busy', String(on));
}

/** The eye button in a password box shows or hides that password ("Show password" tick boxes: every one in the form). */
export function passwordToggles(root = document) {
  for (const button of root.querySelectorAll('[data-eye]')) {
    const input = button.parentElement.querySelector('input');
    button.addEventListener('click', () => {
      const show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      button.setAttribute('aria-pressed', String(show));
      button.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
    });
  }
  for (const box of root.querySelectorAll('[data-show-password]')) {
    box.addEventListener('change', () => {
      for (const input of box.closest('form').querySelectorAll('[data-password]')) input.type = box.checked ? 'text' : 'password';
    });
  }
}

/** Reads the secret from "#t=…" and removes it from the address bar, so it is not shared by accident. */
export function linkToken() {
  const token = new URLSearchParams(location.hash.slice(1)).get('t') || '';
  if (location.hash) history.replaceState(null, '', location.pathname);
  return token;
}

/** A path on this site to go to after login (the server checks it again). */
export function nextPath() {
  const next = new URLSearchParams(location.search).get('next') || '/';
  return next.startsWith('/') && !next.startsWith('//') && !next.includes('\\') ? next : '/';
}

/** The server's public settings (academy name, contact email, free days, Google sign-in on/off), asked once per page. */
export const siteInfo = get('/api/info').then(({ status, data }) => (status === 200 ? data : {}));

/** The result of a Google sign-in ("?google=…"): read once, then removed from the address bar. */
export function googleResult() {
  const params = new URLSearchParams(location.search);
  const code = params.get('google') || '';
  if (!code) return '';
  params.delete('google');
  const rest = params.toString();
  history.replaceState(null, '', `${location.pathname}${rest ? `?${rest}` : ''}`);
  return /^[a-z_]{1,30}$/.test(code) ? code : 'failed';
}

/** The text for a Google sign-in result code from the server. */
export function googleMessage(code, info = {}) {
  const academy = info.academyName || 'the academy';
  const Academy = academy === 'the academy' ? 'The academy' : academy;
  const contact = info.contactEmail ? ` (${info.contactEmail})` : '';
  const texts = {
    cancelled: 'Google sign-in was cancelled. You can try again.',
    expired: 'The Google sign-in took too long, or it was started in another tab or browser. Please try again.',
    failed: 'Google sign-in did not work. Please try again, or use your email and password.',
    unverified: 'Google says this email address is not confirmed. Please use another Google account, or your email and password.',
    other_google: 'This email already has an account that is linked to a different Google account. Please log in with your email and password.',
    consent: 'There is no account for this Google email yet. To make one, press “Continue with Google” on the sign-up page.',
    pending: `Your account is waiting for approval by ${academy}. We will email you when it is ready.`,
    trial_used: `This email address already had its free days, so ${Academy} will check your account. We will email you when it is ready.`,
    blocked: `Your access is paused. Please contact ${academy}${contact}.`,
    ended: `Your access has ended. Please contact ${academy}${contact} to continue.`,
    too_many: 'Too many tries from this network. Please wait an hour and try again.',
    too_many_today: `Many people signed up today. Please try again tomorrow, or contact ${academy}${contact}.`,
    no_account: 'There is no account for this Google email, so nothing was deleted.',
    last_admin: 'There must always be at least one active admin. Make another person admin first.',
  };
  return texts[code] || texts.failed;
}

/**
 * A "Continue with Google" block ([data-google], hidden until the server says Google sign-in is on).
 * body() returns what the server needs, or null when the page must say something first (an unticked box).
 * Resolves to true when the block is shown.
 */
export async function setUpGoogle(block, body) {
  const info = await siteInfo;
  if (!block || !info.google) return false;
  block.hidden = false;
  const button = block.querySelector('[data-google-start]');
  const label = button.querySelector('span');
  const text = label.textContent;
  const ready = () => { button.disabled = false; button.removeAttribute('aria-busy'); label.textContent = text; };
  button.addEventListener('click', async () => {
    const request = body();
    if (!request) return;
    button.disabled = true;
    button.setAttribute('aria-busy', 'true');
    label.textContent = 'Opening Google…';
    say(block, '');
    const { status, data } = await post('/api/auth/google/start', request);
    if (status === 200 && data.url) { location.assign(data.url); return; }
    ready();
    say(block, data.error || 'Google sign-in did not start. Please try again.');
  });
  // Back from Google's page with the browser's Back button: the button works again.
  window.addEventListener('pageshow', (event) => { if (event.persisted) ready(); });
  return true;
}

/**
 * Puts the academy's name and contact email into [data-academy] / [data-contact] elements, and, when new accounts
 * get free days, the [data-trial] text ("{days}" becomes for example "7 days").
 */
export async function fillAcademy() {
  const data = await siteInfo;
  if (!data.ok) return;
  if (data.trialDays > 0) {
    const days = `${data.trialDays} ${data.trialDays === 1 ? 'day' : 'days'}`;
    for (const el of document.querySelectorAll('[data-trial]')) {
      el.textContent = el.dataset.trial.replace('{days}', days);
      el.hidden = false;
    }
  }
  const academy = data.academyName && data.academyName !== 'the academy' ? data.academyName : '';
  if (academy) {
    for (const el of document.querySelectorAll('[data-academy]')) el.textContent = academy;
    for (const el of document.querySelectorAll('[data-academy-by]')) el.textContent = `by ${academy}`;
  }
  for (const el of document.querySelectorAll('[data-copyright]')) el.textContent = `© ${new Date().getFullYear()} ${academy || 'Guitar Studio'}`;
  for (const el of document.querySelectorAll('[data-contact-link]')) {
    if (!data.contactEmail) continue;
    el.href = `mailto:${data.contactEmail}`;
    el.hidden = false;
  }
  for (const el of document.querySelectorAll('[data-contact]')) {
    if (!data.contactEmail) { el.hidden = true; continue; }
    const link = document.createElement('a');
    link.href = `mailto:${data.contactEmail}`;
    link.textContent = data.contactEmail;
    el.replaceChildren(el.dataset.contact || '', link);
    el.hidden = false;
  }
}

export function focusFirstInvalid(form) {
  const first = form.querySelector('[aria-invalid="true"]');
  if (first) first.focus();
}

export function markInvalid(input, invalid) {
  if (!input) return;
  if (invalid) input.setAttribute('aria-invalid', 'true');
  else input.removeAttribute('aria-invalid');
}

clearProgressAfterLogout();
fillAcademy();
