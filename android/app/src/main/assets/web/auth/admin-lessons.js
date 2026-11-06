// Admin page "Video lessons" (/admin/lessons): add, edit and remove YouTube links for the app's lesson library.
import { get, post, say, busy, markLoggedOut } from './common.js';

const card = document.getElementById('lessons-card');
const form = document.getElementById('lesson-form');
const title = form.elements.title;
const youtubeUrl = form.elements.youtubeUrl;
const description = form.elements.description;
const save = document.getElementById('save-lesson');
const cancel = document.getElementById('cancel-edit');
const list = document.getElementById('lesson-list');
const summary = document.getElementById('catalog-summary');
const formTitle = document.getElementById('form-title');

let lessons = [];
let editingId = null;
const goLogin = () => location.replace('/login?next=%2Fadmin%2Flessons');

function fillForm(lesson) {
  editingId = lesson?.id ?? null;
  title.value = lesson?.title ?? '';
  youtubeUrl.value = lesson ? `https://www.youtube.com/watch?v=${lesson.videoId}` : '';
  description.value = lesson?.description ?? '';
  formTitle.textContent = editingId ? 'Edit lesson' : 'Add a lesson';
  save.textContent = editingId ? 'Save changes' : 'Add lesson';
  cancel.hidden = !editingId;
  if (editingId) title.focus();
}

function render() {
  list.replaceChildren();
  summary.textContent = `${lessons.length} ${lessons.length === 1 ? 'lesson' : 'lessons'}`;
  if (!lessons.length) {
    const empty = document.createElement('li');
    empty.className = 'catalog-empty';
    empty.textContent = 'No lessons have been added yet.';
    list.append(empty);
    return;
  }
  for (const lesson of lessons) {
    const item = document.createElement('li');
    item.className = 'admin-lesson';
    const copy = document.createElement('div');
    copy.className = 'admin-lesson-copy';
    const heading = document.createElement('h3');
    heading.textContent = lesson.title;
    copy.append(heading);
    if (lesson.description) {
      const text = document.createElement('p');
      text.textContent = lesson.description;
      copy.append(text);
    }
    const video = document.createElement('a');
    video.href = `https://www.youtube.com/watch?v=${encodeURIComponent(lesson.videoId)}`;
    video.target = '_blank';
    video.rel = 'noopener noreferrer';
    video.textContent = 'Open on YouTube';
    copy.append(video);
    const actions = document.createElement('div');
    actions.className = 'admin-lesson-actions';
    const edit = document.createElement('button');
    edit.type = 'button';
    edit.className = 'btn btn-small';
    edit.textContent = 'Edit';
    edit.setAttribute('aria-label', `Edit ${lesson.title}`);
    edit.addEventListener('click', () => fillForm(lesson));
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.className = 'btn btn-small btn-danger';
    remove.textContent = 'Delete';
    remove.setAttribute('aria-label', `Delete ${lesson.title}`);
    remove.addEventListener('click', () => void deleteLesson(lesson));
    actions.append(edit, remove);
    item.append(copy, actions);
    list.append(item);
  }
}

async function load() {
  list.setAttribute('aria-busy', 'true');
  const { status, data } = await get('/api/admin/lessons');
  list.setAttribute('aria-busy', 'false');
  if (status === 401) return goLogin();
  if (status === 403) { location.replace('/account'); return; }
  if (status !== 200 || !Array.isArray(data.lessons)) {
    summary.textContent = '';
    list.replaceChildren();
    say(card, data.message || 'Could not load the lessons. Please reload the page.');
    return;
  }
  lessons = data.lessons;
  render();
}

async function deleteLesson(lesson) {
  if (!window.confirm(`Delete “${lesson.title}” from the lesson library?`)) return;
  const { status, data } = await post(`/api/admin/lessons/${encodeURIComponent(lesson.id)}/delete`);
  if (status === 401) return goLogin();
  if (status !== 200) return say(card, data.message || 'Could not delete the lesson. Please try again.');
  if (editingId === lesson.id) fillForm(null);
  say(card, 'Lesson deleted.', 'ok');
  await load();
}

form.addEventListener('reset', () => {
  editingId = null;
  formTitle.textContent = 'Add a lesson';
  save.textContent = 'Add lesson';
  cancel.hidden = true;
});
cancel.addEventListener('click', () => form.reset());
form.addEventListener('submit', async (event) => {
  event.preventDefault();
  say(card, '');
  const fields = [title, youtubeUrl, description];
  fields.forEach((field) => field.removeAttribute('aria-invalid'));
  if (!title.value.trim()) { title.setAttribute('aria-invalid', 'true'); say(card, 'Please enter a title.'); title.focus(); return; }
  if (!youtubeUrl.value.trim()) { youtubeUrl.setAttribute('aria-invalid', 'true'); say(card, 'Please enter a YouTube video link.'); youtubeUrl.focus(); return; }
  busy(save, true, 'Saving…');
  const path = editingId ? `/api/admin/lessons/${encodeURIComponent(editingId)}` : '/api/admin/lessons';
  const { status, data } = await post(path, { title: title.value, description: description.value, youtubeUrl: youtubeUrl.value });
  busy(save, false);
  if (status === 401) return goLogin();
  if (status !== 200 && status !== 201) return say(card, data.message || 'Could not save the lesson. Please check the title and YouTube link.');
  const updated = !!editingId;
  form.reset();
  say(card, updated ? 'Lesson updated.' : 'Lesson added.', 'ok');
  await load();
});

document.getElementById('logout').addEventListener('click', async () => {
  const button = document.getElementById('logout');
  busy(button, true, 'Logging out…');
  await post('/api/logout');
  markLoggedOut();
  location.replace('/login');
});

void load();
