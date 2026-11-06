import { get, post, say, busy, passwordToggles, nextPath, markInvalid, forgetOtherStudent, siteInfo, googleResult, googleMessage, setUpGoogle } from './common.js';

const form = document.getElementById('login-form');
const email = form.elements.email;
const password = form.elements.password;
const button = form.querySelector('button[type="submit"]');
const google = document.getElementById('google');
passwordToggles();

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  markInvalid(email, !email.value.trim());
  markInvalid(password, !password.value);
  if (!email.value.trim() || !password.value) {
    say(form, 'Please enter your email and password.');
    (email.value.trim() ? password : email).focus();
    return;
  }
  busy(button, true, 'Logging in…');
  say(form, '');
  const { status, data } = await post('/api/login', { email: email.value, password: password.value, next: nextPath() });
  if (status === 200 && data.ok) {
    say(form, 'Logged in. Opening Guitar Studio…', 'ok');
    forgetOtherStudent(data.userId);
    location.assign(data.next || '/');
    return;
  }
  busy(button, false);
  say(form, data.error || 'Something went wrong. Please try again.');
  if (data.code === 'wrong') { password.value = ''; password.focus(); }
});

// "Continue with Google": the server logs the person in, then sends them back here with ?google=done.
const result = googleResult();
if (result === 'done') {
  say(form, 'Logged in with Google. Opening Guitar Studio…', 'ok');
  get('/api/me').then(({ status, data }) => {
    if (status === 200 && data.user) {
      forgetOtherStudent(data.user.id);
      location.replace(nextPath());
      return;
    }
    say(form, 'Google sign-in did not work. Please try again.');
  });
}
setUpGoogle(google, () => ({ purpose: 'login', next: nextPath(), consent: true })).then(async (shown) => {
  if (result && result !== 'done') say(shown ? google : form, googleMessage(result, await siteInfo));
});
