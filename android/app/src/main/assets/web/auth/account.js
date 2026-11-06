import { get, post, say, busy, passwordToggles, markInvalid, markLoggedOut } from './common.js';

const form = document.getElementById('password-form');
const { current, password, confirm } = form.elements;
const button = form.querySelector('button[type="submit"]');
const logoutCard = document.getElementById('logout-card');
passwordToggles();

function show(user) {
  document.getElementById('me-name').textContent = user.name;
  document.getElementById('me-email').textContent = user.email;
  document.getElementById('me-access').textContent = user.accessUntil || 'No end date';
  document.getElementById('me-login').textContent = user.google
    ? (user.hasPassword ? 'Google, or email and password' : 'Google')
    : 'Email and password';
  // Google-only accounts have no current password to type: they can add one with a reset link.
  document.getElementById('no-password').hidden = user.hasPassword;
  form.hidden = !user.hasPassword;
  document.getElementById('username').value = user.email;
  document.getElementById('must-change').hidden = !user.mustChangePassword;
  document.getElementById('open-app').hidden = user.mustChangePassword;
  document.getElementById('open-admin').hidden = user.role !== 'admin' || user.mustChangePassword;
  if (user.mustChangePassword) current.focus();
}

async function load() {
  const { status, data } = await get('/api/me');
  if (status === 401) { location.replace('/login?next=%2Faccount'); return; }
  if (status !== 200) { say(form, data.error || 'Could not load your account. Please reload the page.'); return; }
  show(data.user);
  loadLeaderboardChoice(data.user);
}

// "Hide me from the leaderboard" (server/src/plans.mjs). Students only: admins are never ranked.
const boardCard = document.getElementById('leaderboard-card');
const hideBoard = document.getElementById('hide-leaderboard');
async function loadLeaderboardChoice(user) {
  if (user.role !== 'student' || user.mustChangePassword) { boardCard.hidden = true; return; }
  const { status, data } = await get('/api/plan');
  if (status !== 200) { boardCard.hidden = true; return; }
  hideBoard.checked = data.hideFromLeaderboard === true;
  boardCard.hidden = false;
}
hideBoard.addEventListener('change', async () => {
  const hide = hideBoard.checked;
  hideBoard.disabled = true;
  const { status, data } = await post('/api/plan/settings', { hideFromLeaderboard: hide });
  hideBoard.disabled = false;
  if (status === 200 && data.ok) {
    say(boardCard, hide ? 'You are now hidden from the leaderboard.' : 'You are now shown on the leaderboard.', 'ok');
    return;
  }
  hideBoard.checked = !hide;
  say(boardCard, data.error || 'Something went wrong. Please try again.');
});

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  for (const input of [current, password, confirm]) markInvalid(input, false);
  if (!current.value) { markInvalid(current, true); say(form, 'Please enter your current password.'); current.focus(); return; }
  if ([...password.value].length < 8) { markInvalid(password, true); say(form, 'Use at least 8 characters for your new password.'); password.focus(); return; }
  if (password.value !== confirm.value) { markInvalid(confirm, true); say(form, 'The two new passwords are not the same.'); confirm.focus(); return; }
  busy(button, true, 'Saving…');
  const { status, data } = await post('/api/password', { current: current.value, password: password.value });
  busy(button, false);
  if (status === 200 && data.ok) {
    form.reset();
    say(form, data.message, 'ok');
    await load();
    document.getElementById('open-app').focus();
    return;
  }
  if (status === 401) { location.replace('/login?next=%2Faccount'); return; }
  say(form, data.error || 'Something went wrong. Please try again.');
  const field = data.code === 'wrong_current' ? current : data.code === 'password' ? password : null;
  if (field) { markInvalid(field, true); field.focus(); }
});

async function logout(path, button) {
  busy(button, true, 'Logging out…');
  const { status, data } = await post(path);
  // The login page then removes this student's practice data from the device.
  if (status === 200) { markLoggedOut(); location.replace('/login'); return; }
  busy(button, false);
  say(logoutCard, data.error || 'Something went wrong. Please try again.');
}
document.getElementById('logout').addEventListener('click', (event) => logout('/api/logout', event.currentTarget));
document.getElementById('logout-all').addEventListener('click', (event) => logout('/api/logout-all', event.currentTarget));

load();
