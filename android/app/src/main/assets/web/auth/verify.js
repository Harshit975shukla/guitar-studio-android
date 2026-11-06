// The link only opens this page; the email is confirmed when the person presses the button
// (mail scanners that open links do not use it up).
import { post, say, busy, linkToken } from './common.js';

const form = document.getElementById('verify-form');
const button = form.querySelector('button[type="submit"]');
const token = linkToken();
if (!token) {
  button.hidden = true;
  say(form, 'This link is not complete. Please open the link from your email again, or copy all of it.');
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  busy(button, true, 'Confirming…');
  const { status, data } = await post('/api/verify', { token });
  busy(button, false);
  if (status === 200 && data.ok) {
    button.hidden = true;
    document.getElementById('verify-lead').hidden = true;
    say(form, data.message, 'ok');
    return;
  }
  say(form, data.error || 'Something went wrong. Please try again.');
  if (data.code === 'bad_link') button.hidden = true;
});
