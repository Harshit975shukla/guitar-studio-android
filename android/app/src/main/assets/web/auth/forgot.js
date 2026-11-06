import { post, say, busy, markInvalid } from './common.js';

const form = document.getElementById('forgot-form');
const email = form.elements.email;
const button = form.querySelector('button[type="submit"]');

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const ok = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email.value.trim());
  markInvalid(email, !ok);
  if (!ok) { say(form, 'Please enter a valid email address.'); email.focus(); return; }
  busy(button, true, 'Sending…');
  const { status, data } = await post('/api/forgot', { email: email.value });
  busy(button, false);
  if (status === 202 && data.ok) {
    button.hidden = true;
    email.readOnly = true;
    say(form, data.message, 'ok');
    return;
  }
  say(form, data.error || 'Something went wrong. Please try again.');
});
