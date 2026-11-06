import { post, say, busy, passwordToggles, linkToken, markInvalid } from './common.js';

const form = document.getElementById('reset-form');
const { password, confirm } = form.elements;
const button = form.querySelector('button[type="submit"]');
const token = linkToken();
passwordToggles();

async function start() {
  if (!token) { say(form, 'This link is not complete. Please open the link from your email again, or ask for a new one.'); return; }
  const { status, data } = await post('/api/reset/check', { token });
  if (status !== 200) { say(form, data.error || 'Something went wrong. Please try again.'); return; }
  say(form, '', 'ok');
  for (const el of form.querySelectorAll('[data-when-ready]')) el.hidden = false;
  password.focus();
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  markInvalid(password, false); markInvalid(confirm, false);
  if ([...password.value].length < 8) { markInvalid(password, true); say(form, 'Use at least 8 characters for your password.'); password.focus(); return; }
  if (password.value !== confirm.value) { markInvalid(confirm, true); say(form, 'The two passwords are not the same.'); confirm.focus(); return; }
  busy(button, true, 'Saving…');
  const { status, data } = await post('/api/reset', { token, password: password.value });
  busy(button, false);
  if (status === 200 && data.ok) {
    for (const el of form.querySelectorAll('[data-when-ready]')) el.hidden = true;
    say(form, data.message, 'ok');
    document.querySelector('.links a[href="/login"]').focus();
    return;
  }
  say(form, data.error || 'Something went wrong. Please try again.');
  if (data.code === 'password') { markInvalid(password, true); password.focus(); }
});

start();
