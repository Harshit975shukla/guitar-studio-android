// Admin page. Every value from the server is put in with textContent (never as HTML).
import { get, post, say, busy, markLoggedOut } from './common.js';

const panel = document.querySelector('section.card');
const list = document.getElementById('users');
const summary = document.getElementById('list-summary');
const form = document.getElementById('search-form');
const statusSelect = document.getElementById('filter-status');
const roleSelect = document.getElementById('filter-role');
const recentBox = document.getElementById('filter-recent');
const WEEK = 7 * 24 * 3600 * 1000;
const STATUS = { pending: 'Waiting', active: 'Active', blocked: 'Blocked' };
const ACTIONS = {
  signup: 'signed up', verify_email: 'confirmed the email', approve: 'approved', block: 'blocked', unblock: 'unblocked',
  access: 'changed the access date of', reset_link: 'sent a password link to', reset_requested: 'asked for a password link',
  temp_password: 'set a temporary password for', role: 'changed the role of', delete: 'deleted', password_change: 'changed the password',
  password_reset: 'chose a new password with a link', logout_everywhere: 'logged out on all devices', create_admin: 'made an admin',
  trial_start: 'started the free days', google_link: 'linked Google sign-in', feedback_delete: 'deleted feedback from',
};
const KINDS = { idea: 'Idea', problem: 'Problem', other: 'Other' };
// The app's pages, as named in its menu (practice time is kept per page).
const PAGES = {
  detector: 'Live studio', chords: 'Chords', songs: 'Play along', player: 'Chord player', game: 'Chord game', drill: 'Chord changes',
  scales: 'Scales', trainer: 'Ear training', songpractice: 'Song practice', metronome: 'Metronome', rhythm: 'Drums & tabla',
  backing: 'Backing tracks', tuner: 'Tuner', theory: 'Theory lessons', fifths: 'Circle of fifths', lab: 'Guitar Lab', other: 'Other',
};
const feedbackCard = document.getElementById('feedback-card');
const feedbackList = document.getElementById('feedback');
let allUsers = [];
let counts = {};
let sort = { key: null, dir: 'asc' };
const expanded = new Set(); // ids of rows whose Manage panel is open
let timeZone = 'Asia/Kolkata';
let shownPassword = null; // { id, password } — shown once, until the next action

const when = (ms) => (ms ? new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium', timeStyle: 'short', timeZone }).format(ms) : 'never');
const size = (bytes) => (bytes < 1_048_576 ? `${Math.max(1, Math.round(bytes / 1024))} KB` : `${(bytes / 1_048_576).toFixed(1)} MB`);
/** Seconds -> "0 min", "under 1 min", "25 min", "2 h 10 min". */
const duration = (seconds) => {
  if (seconds > 0 && seconds < 30) return 'under 1 min';
  const minutes = Math.round(seconds / 60);
  return minutes < 60 ? `${minutes} min` : `${Math.floor(minutes / 60)} h${minutes % 60 ? ` ${minutes % 60} min` : ''}`;
};
const pageList = (pages) => pages.map(([page, seconds]) => `${PAGES[page] || page} ${duration(seconds)}`).join(', ');
const dayLabel = (day) => new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short', timeZone: 'UTC' }).format(new Date(`${day}T12:00:00Z`));
// Feedback times in the admin's own browser language and time zone.
const localWhen = (ms) => new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(ms);

function el(tag, attrs = {}, ...children) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (value === false || value === null || value === undefined) continue;
    if (key === 'text') node.textContent = value;
    else if (key === 'className') node.className = value;
    else node.setAttribute(key, value === true ? '' : value);
  }
  node.append(...children.filter(Boolean));
  return node;
}

function goLogin() { location.replace('/login?next=%2Fadmin'); }

async function load(focusId) {
  list.setAttribute('aria-busy', 'true');
  // One request for everybody; searching, filtering and sorting happen in this page.
  const { status, data } = await get('/api/admin/users?status=all');
  list.setAttribute('aria-busy', 'false');
  if (status === 401) return goLogin();
  if (status !== 200) { say(panel, data.error || 'Could not load the list. Please reload the page.'); return; }
  timeZone = data.timeZone || timeZone;
  allUsers = data.users;
  counts = data.counts || {};
  fillStatusOptions();
  if (data.practiceOverview) practiceOverview(data.practiceOverview);
  render(focusId);
}

function fillStatusOptions() {
  const chosen = statusSelect.value || 'all';
  const options = [['all', 'All'], ['pending', 'Waiting'], ['active', 'Active'], ['blocked', 'Blocked']];
  statusSelect.replaceChildren(...options.map(([value, label]) =>
    el('option', { value, text: `${label} (${counts[value] ?? 0})` })));
  statusSelect.value = chosen;
}

/** The newest of the last app use and the last login (ms), or 0. */
const lastActive = (user) => Math.max(user.practice?.lastActiveAt || 0, user.lastLoginAt || 0);
const weekSeconds = (user) => user.practice?.week || 0;
const planScore = (user) => (typeof user.planScore === 'number' && Number.isFinite(user.planScore) ? user.planScore : null);
const planText = (user) => {
  const score = planScore(user);
  if (score !== null) return String(score);
  return typeof user.planScore === 'string' && user.planScore.trim() ? user.planScore.trim() : '—';
};
const STATUS_ORDER = { pending: 0, active: 1, blocked: 2 };
const SORTERS = {
  name: (a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }),
  email: (a, b) => a.email.localeCompare(b.email, undefined, { sensitivity: 'base' }),
  role: (a, b) => a.role.localeCompare(b.role),
  status: (a, b) => (STATUS_ORDER[a.status] ?? 9) - (STATUS_ORDER[b.status] ?? 9),
  // "No end date" sorts after every real date.
  access: (a, b) => (a.accessUntil || '9999-99-99').localeCompare(b.accessUntil || '9999-99-99'),
  active: (a, b) => lastActive(a) - lastActive(b),
  week: (a, b) => weekSeconds(a) - weekSeconds(b),
  plan: (a, b) => (planScore(a) ?? -1) - (planScore(b) ?? -1),
};

function visibleUsers() {
  const q = form.elements.q.value.trim().toLowerCase();
  const wantStatus = statusSelect.value || 'all';
  const wantRole = roleSelect.value;
  const cutoff = Date.now() - WEEK;
  const rows = allUsers.filter((user) =>
    (!q || user.name.toLowerCase().includes(q) || user.email.toLowerCase().includes(q))
    && (wantStatus === 'all' || user.status === wantStatus)
    && (wantRole === 'all' || user.role === wantRole)
    && (!recentBox.checked || lastActive(user) >= cutoff));
  if (sort.key) {
    const compare = SORTERS[sort.key];
    const sign = sort.dir === 'asc' ? 1 : -1;
    // A stable sort, so equal rows keep the server's order.
    rows.sort((a, b) => sign * compare(a, b));
  }
  return rows;
}

function render(focusId) {
  const rows = visibleUsers();
  for (const th of document.querySelectorAll('th[aria-sort]')) {
    const key = th.querySelector('[data-sort]').dataset.sort;
    th.setAttribute('aria-sort', sort.key === key ? (sort.dir === 'asc' ? 'ascending' : 'descending') : 'none');
  }
  list.replaceChildren(...rows.flatMap(userRows));
  if (!rows.length) {
    list.append(el('tr', { className: 'empty' }, el('td', { colspan: '9', text: allUsers.length ? 'No accounts match these filters.' : 'No accounts yet.' })));
  }
  summary.textContent = `Showing ${rows.length} of ${allUsers.length} ${allUsers.length === 1 ? 'account' : 'accounts'}.`;
  if (focusId) (list.querySelector(`[data-id="${CSS.escape(focusId)}"] [data-manage]`) || document.getElementById('search'))?.focus();
}

/** One account = a table row, plus a second row (Manage) with every action. */
function userRows(user) {
  const id = user.id;
  const open = expanded.has(id) || shownPassword?.id === id;
  const time = user.practice;
  const manage = el('button', { type: 'button', className: 'btn btn-small', 'data-manage': true, 'aria-expanded': String(open), 'aria-controls': `manage-${id}`, text: 'Manage' });
  manage.setAttribute('aria-label', `Manage ${user.name}`);
  manage.addEventListener('click', () => {
    if (open) { expanded.delete(id); if (shownPassword?.id === id) shownPassword = null; } else expanded.add(id);
    render(id);
  });
  const quick = [];
  if (user.status === 'pending') {
    const approve = el('button', { type: 'button', className: 'btn btn-small', text: 'Approve' });
    approve.setAttribute('aria-label', `Approve ${user.name}`);
    approve.addEventListener('click', () => run(user, 'approve', { done: `${user.name} is approved. We sent them an email.` }, approve));
    quick.push(approve);
  }
  const row = el('tr', { className: 'user', 'data-id': id },
    el('th', { scope: 'row', className: 'user-name', text: user.name }),
    el('td', { className: 'user-email', text: user.email }),
    el('td', {}, el('span', { className: user.role === 'admin' ? 'badge admin' : 'badge', text: user.role === 'admin' ? 'Admin' : 'Student' })),
    el('td', {},
      el('span', { className: `badge ${user.status}`, text: STATUS[user.status] || user.status }),
      user.accessEnded && el('span', { className: 'badge warn', text: 'Access ended' })),
    el('td', { className: 'nowrap', text: user.accessUntilLabel || 'No end date' }),
    el('td', { className: 'nowrap', text: lastActive(user) ? when(lastActive(user)) : 'never' }),
    el('td', { className: 'nowrap num', text: time ? duration(time.week) : '0 min' }),
    el('td', { className: 'nowrap num', text: planText(user) }),
    el('td', { className: 'row-actions' }, ...quick, manage));
  const detail = el('tr', { className: 'user-detail', id: `manage-${id}`, hidden: !open }, el('td', { colspan: '9' }, detailPanel(user)));
  return [row, detail];
}

function detailPanel(user) {
  const id = user.id;
  const badges = el('ul', { className: 'badges', 'aria-label': 'Account details' },
    el('li', { className: user.emailVerified ? 'badge' : 'badge warn', text: user.emailVerified ? 'Email confirmed' : 'Email not confirmed' }),
    user.google && el('li', { className: 'badge', text: 'Google' }),
    user.mustChangePassword && el('li', { className: 'badge', text: 'Must change password' }),
    user.locked && el('li', { className: 'badge warn', text: 'Locked for 15 min (wrong passwords)' }),
    user.accessEnded && el('li', { className: 'badge warn', text: 'Access ended' }),
  );
  const meta = el('p', { className: 'user-meta', text:
    `Signed up ${when(user.createdAt)} · Last login ${when(user.lastLoginAt)} · Access ${user.accessUntilLabel ? `until ${user.accessUntilLabel}` : 'with no end date'}` });
  // Only the size and time: admins never see the saved practice data itself.
  const saved = el('p', { className: 'user-meta user-progress', text:
    user.progressBytes ? `Progress saved: ${size(user.progressBytes)} · ${when(user.progressUpdatedAt)}` : 'No saved progress' });
  // Practice time: minutes the app was on screen and in use (numbers only).
  const time = user.practice;
  const practice = el('p', { className: 'user-meta user-practice', text: time
    ? `Practice: today ${duration(time.today)} · last 7 days ${duration(time.week)} · total ${duration(time.total)} · last active ${when(time.lastActiveAt)}${time.pages.length ? ` · Most used (7 days): ${pageList(time.pages)}` : ''}`
    : 'No practice time yet' });

  const button = (label, name, options = {}) => {
    const b = el('button', { type: 'button', className: `btn btn-small${options.danger ? ' btn-danger' : ''}`, text: label });
    b.addEventListener('click', () => run(user, name, options, b));
    return b;
  };
  const actions = el('div', { className: 'user-actions' },
    user.status === 'pending' && button('Approve', 'approve', { done: `${user.name} is approved. We sent them an email.` }),
    user.status !== 'blocked' && button('Block', 'block', { danger: true, confirm: `Block ${user.name}? They will be logged out and cannot use the app until you unblock them.`, done: `${user.name} is blocked.` }),
    user.status === 'blocked' && button('Unblock', 'unblock', { done: `${user.name} is active again.` }),
    button('Send password link', 'reset-link', { done: `We sent a password link to ${user.email}. It works for 1 hour.` }),
    button('Set temporary password', 'temp-password', { confirm: `Set a temporary password for ${user.name}? Their old password stops working and they are logged out.`, done: `Temporary password set for ${user.name}. Give it to them; they must change it when they log in.` }),
    user.role === 'admin'
      ? button('Remove admin', 'role', { body: { role: 'student' }, confirm: `Remove admin rights from ${user.name}?`, done: `${user.name} is now a student.` })
      : button('Make admin', 'role', { body: { role: 'admin' }, confirm: `Make ${user.name} an admin? Admins can see and change all accounts.`, done: `${user.name} is now an admin.` }),
    button('Delete', 'delete', { danger: true, confirm: `Delete the account of ${user.name} (${user.email})? This cannot be undone.`, done: `The account of ${user.name} is deleted.` }),
  );

  const dateId = `access-${id}`;
  const date = el('input', { type: 'date', id: dateId, value: user.accessUntil || '' });
  const save = el('button', { type: 'button', className: 'btn btn-small', text: 'Save date' });
  save.addEventListener('click', () => run(user, 'access', { body: { date: date.value }, done: date.value ? `Access for ${user.name} now ends after the chosen date.` : `Access for ${user.name} now has no end date.` }, save));
  const noEnd = el('button', { type: 'button', className: 'btn btn-small', text: 'No end date' });
  noEnd.addEventListener('click', () => { date.value = ''; run(user, 'access', { body: { date: '' }, done: `Access for ${user.name} now has no end date.` }, noEnd); });
  const access = el('div', { className: 'access' },
    el('div', { className: 'field' }, el('label', { for: dateId, text: 'Access until (last day)' }), date), save, noEnd);

  const temp = shownPassword?.id === id
    ? el('p', { className: 'temp', role: 'status' }, 'Temporary password (shown only once): ', el('code', { text: shownPassword.password }))
    : null;

  return el('div', { className: 'detail-panel' }, badges, meta, saved, practice, actions, access, temp);
}

const CSV_COLUMNS = ['Name', 'Email', 'Role', 'Status', 'Access until', 'Last active', 'Practice this week (minutes)', 'Plan score'];
/** One CSV cell. A leading = + - @ would be run as a formula by a spreadsheet, so it gets a ' first. */
const csvCell = (value) => {
  let text = String(value ?? '');
  if (/^[=+\-@\t\r]/.test(text)) text = `'${text}`;
  return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
};
function downloadCsv() {
  const rows = visibleUsers().map((user) => [
    user.name, user.email, user.role, STATUS[user.status] || user.status, user.accessUntil || 'No end date',
    lastActive(user) ? new Date(lastActive(user)).toISOString() : '', Math.round(weekSeconds(user) / 60), planText(user) === '—' ? '' : planText(user),
  ]);
  const text = [CSV_COLUMNS, ...rows].map((row) => row.map(csvCell).join(',')).join('\r\n');
  const url = URL.createObjectURL(new Blob(['﻿', text], { type: 'text/csv;charset=utf-8' }));
  const link = el('a', { href: url, download: `guitar-studio-accounts-${new Date().toISOString().slice(0, 10)}.csv` });
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
  say(panel, `Downloaded ${rows.length} ${rows.length === 1 ? 'row' : 'rows'}.`, 'ok');
}

/** Practice time of all students (admins not counted): today and the last 7 days, and the pages used most. */
function practiceOverview(overview) {
  const box = document.getElementById('practice-overview');
  const people = (n) => `${n} ${n === 1 ? 'student' : 'students'}`;
  box.replaceChildren(
    el('p', { text: `Today: ${people(overview.today.students)} · ${duration(overview.today.seconds)}` }),
    el('p', { text: `Last 7 days (since ${dayLabel(overview.from)}): ${people(overview.week.students)} · ${duration(overview.week.seconds)}` }),
    el('p', { text: overview.pages.length ? `Most used: ${pageList(overview.pages)}` : 'No practice time yet.' }));
}

async function run(user, name, options, button) {
  if (options.confirm && !window.confirm(options.confirm)) return;
  busy(button, true);
  const { status, data } = await post(`/api/admin/users/${encodeURIComponent(user.id)}/${name}`, options.body || {});
  busy(button, false);
  if (status === 401) return goLogin();
  if (status !== 200 || !data.ok) { say(panel, data.error || 'Something went wrong. Please try again.'); return; }
  shownPassword = data.temporaryPassword ? { id: user.id, password: data.temporaryPassword } : null;
  say(panel, options.done || 'Done.', 'ok');
  await load(data.deleted ? null : user.id);
  if (data.deleted) document.getElementById('admin-title').focus?.();
  // A deleted account's feedback is deleted with it.
  if (data.deleted) loadFeedback();
  loadAudit();
}

async function loadFeedback() {
  feedbackList.setAttribute('aria-busy', 'true');
  const { status, data } = await get('/api/admin/feedback');
  feedbackList.setAttribute('aria-busy', 'false');
  if (status === 401) return goLogin();
  if (status !== 200) { say(feedbackCard, data.error || 'Could not load the feedback. Please reload the page.'); return; }
  document.getElementById('feedback-digest').textContent = data.digestTime
    ? `New messages are also emailed to the admin once a day, at ${data.digestTime} (${data.timeZone}).`
    : 'The daily feedback email is off (ADMIN_NOTIFY_EMAIL is empty on the server).';
  feedbackList.replaceChildren(...data.feedback.map(feedbackItem));
  if (!data.feedback.length) feedbackList.append(el('li', { className: 'hint', text: 'No feedback yet.' }));
}

function feedbackItem(entry) {
  const who = entry.user ? entry.user.name : 'Deleted account';
  const remove = el('button', { type: 'button', className: 'btn btn-small btn-danger', text: 'Delete' });
  remove.addEventListener('click', () => deleteFeedback(entry, who, remove));
  return el('li', { className: 'feedback-item', 'data-id': entry.id },
    el('div', { className: 'feedback-head' },
      el('span', { className: `badge kind-${KINDS[entry.kind] ? entry.kind : 'other'}`, text: KINDS[entry.kind] || entry.kind }),
      el('strong', { text: who }),
      entry.user && el('span', { className: 'user-email', text: entry.user.email })),
    el('p', { className: 'user-meta' },
      el('time', { datetime: new Date(entry.createdAt).toISOString(), text: localWhen(entry.createdAt) }),
      `${entry.page ? ` · Page: ${entry.page}` : ''}${entry.sentAt ? ' · In the daily email' : ''}`),
    el('p', { className: 'feedback-message', text: entry.message }),
    el('div', { className: 'user-actions' }, remove));
}

async function deleteFeedback(entry, who, button) {
  if (!window.confirm(`Delete this message from ${who}? This cannot be undone.`)) return;
  busy(button, true);
  const { status, data } = await post(`/api/admin/feedback/${encodeURIComponent(entry.id)}/delete`);
  busy(button, false);
  if (status === 401) return goLogin();
  if (status !== 200 || !data.ok) { say(feedbackCard, data.error || 'Something went wrong. Please try again.'); return; }
  say(feedbackCard, `The message from ${who} is deleted.`, 'ok');
  await loadFeedback();
  document.getElementById('feedback-title').focus();
  loadAudit();
}

async function loadAudit() {
  const { status, data } = await get('/api/admin/audit?limit=100');
  if (status !== 200) return;
  const audit = document.getElementById('audit');
  audit.replaceChildren(...data.entries.map((entry) => el('li', {},
    el('time', { datetime: new Date(entry.at).toISOString(), text: when(entry.at) }),
    entry.action === 'self_delete'
      ? `A student deleted their own account (${entry.detail})`
      : `${entry.actor} ${ACTIONS[entry.action] || entry.action}${entry.target && entry.target !== entry.actor ? ` ${entry.target}` : ''}${entry.detail ? ` (${entry.detail})` : ''}`)));
  if (!data.entries.length) audit.append(el('li', { text: 'Nothing yet.' }));
}

form.addEventListener('submit', (event) => event.preventDefault());
form.addEventListener('input', () => render());
form.addEventListener('change', () => render());
document.getElementById('download-csv').addEventListener('click', downloadCsv);
for (const b of document.querySelectorAll('[data-sort]')) {
  b.addEventListener('click', () => {
    const key = b.dataset.sort;
    // First click: A to Z (times and numbers: biggest or newest first). A second click turns it round.
    const firstDir = ['active', 'week', 'plan'].includes(key) ? 'desc' : 'asc';
    sort = sort.key === key ? { key, dir: sort.dir === 'asc' ? 'desc' : 'asc' } : { key, dir: firstDir };
    render();
    b.focus();
  });
}
document.getElementById('audit-reload').addEventListener('click', loadAudit);
document.getElementById('feedback-reload').addEventListener('click', () => { say(feedbackCard, ''); loadFeedback(); });
document.getElementById('logout').addEventListener('click', async (event) => {
  busy(event.currentTarget, true, 'Logging out…');
  await post('/api/logout');
  markLoggedOut();
  location.replace('/login');
});

document.getElementById('admin-title').setAttribute('tabindex', '-1');
load();
loadFeedback();
loadAudit();
