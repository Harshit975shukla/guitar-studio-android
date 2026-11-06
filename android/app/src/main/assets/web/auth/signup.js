import { post, say, busy, passwordToggles, markInvalid, siteInfo, googleResult, googleMessage, setUpGoogle } from './common.js';

const form = document.getElementById('signup-form');
const { name, email, password, confirm, consent } = form.elements;
const button = form.querySelector('button[type="submit"]');
const google = document.getElementById('google');
passwordToggles();

// "Continue with Google": the page shows that this means agreeing to the privacy note.
const result = googleResult();
setUpGoogle(google, () => ({ purpose: 'signup', consent: true })).then(async (shown) => {
  if (result) say(shown ? google : form, googleMessage(result, await siteInfo));
});

function problem() {
  for (const input of [name, email, password, confirm, consent]) markInvalid(input, false);
  if (!name.value.trim()) return [name, 'Please enter your name.'];
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email.value.trim())) return [email, 'Please enter a valid email address.'];
  if ([...password.value].length < 8) return [password, 'Use at least 8 characters for your password.'];
  if (password.value !== confirm.value) return [confirm, 'The two passwords are not the same.'];
  if (!consent.checked) return [consent, 'Please tick the box to agree to the privacy note.'];
  return null;
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
  busy(button, true, 'Creating your account…');
  say(form, '');
  const { status, data } = await post('/api/signup', { name: name.value, email: email.value, password: password.value, consent: true });
  busy(button, false);
  if (status === 202 && data.ok) {
    form.hidden = true;
    const done = document.getElementById('signup-done');
    document.getElementById('signup-done-text').textContent = data.message;
    done.hidden = false;
    done.focus();
    return;
  }
  const field = { name, email, password, consent }[data.code];
  if (field) { markInvalid(field, true); field.focus(); }
  say(form, data.error || 'Something went wrong. Please try again.');
});
