import { get, post, say, busy, passwordToggles, markInvalid, forgetThisDevice, siteInfo, googleResult, googleMessage, setUpGoogle } from './common.js';

const form = document.getElementById('delete-form');
const { email, password, confirm } = form.elements;
const button = form.querySelector('button[type="submit"]');
const google = document.getElementById('google');
const DELETED = 'Your account and your saved practice progress are deleted. This device has forgotten them too.';
passwordToggles();

// Logged in (from "My account"): fill in the email. Without a login the person types it.
get('/api/me').then(({ status, data }) => {
  if (status === 200 && data.user && !email.value) email.value = data.user.email;
});

function problem() {
  for (const input of [email, password, confirm]) markInvalid(input, false);
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email.value.trim())) return [email, 'Please enter a valid email address.'];
  if (!password.value) return [password, 'Please enter your password.'];
  if (!confirm.checked) return [confirm, 'Please tick the box to confirm that you want to delete your account.'];
  return null;
}

function showDone(message) {
  forgetThisDevice();
  form.hidden = true;
  google.hidden = true;
  const back = document.getElementById('back-link');
  back.href = '/login';
  back.textContent = 'Back to log in';
  document.getElementById('forgot-link').hidden = true;
  const done = document.getElementById('delete-done');
  document.getElementById('delete-done-text').textContent = message;
  done.hidden = false;
  done.focus();
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const found = problem();
  if (found) {
    const [input, text] = found;
    markInvalid(input, true);
    say(form, text);
    input.focus();
    return;
  }
  busy(button, true, 'Deleting…');
  say(form, '');
  const { status, data } = await post('/api/delete-account', { email: email.value, password: password.value, confirm: true });
  busy(button, false);
  if (status === 200 && data.deleted) {
    showDone(data.message);
    return;
  }
  const field = data.code === 'wrong' ? password : data.code === 'confirm' ? confirm : null;
  if (field) { markInvalid(field, true); field.focus(); }
  say(form, data.error || 'Something went wrong. Please try again.');
});

// "Confirm with Google and delete": the same tick box first; Google then shows whose account it is.
const result = googleResult();
if (result === 'deleted') showDone(DELETED);
setUpGoogle(google, () => {
  markInvalid(confirm, false);
  if (confirm.checked) return { purpose: 'delete', confirm: true };
  markInvalid(confirm, true);
  say(google, 'Please tick the box to confirm that you want to delete your account.');
  confirm.focus();
  return null;
}).then(async (shown) => {
  if (result && result !== 'deleted') say(shown ? google : form, googleMessage(result, await siteInfo));
  if (result === 'deleted') google.hidden = true;
});
