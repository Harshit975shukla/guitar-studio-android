// Admin page "Practice plans" (/admin/plans, server/src/plans.mjs): every student's plan and this week's score;
// create or edit a plan and assign it to one or several students; remove it. Text only through textContent.
import { get, post, say, busy, markLoggedOut } from './common.js';

const LEVELS = { beginner: 'Beginner', intermediate: 'Intermediate', advanced: 'Advanced' };
const GOALS = { songs: 'Play songs', rhythm: 'Strumming and rhythm', theory: 'Theory lessons', lead: 'Solos and scales' };
const PAGE_NAMES = {
  tuner: 'Tuner', chords: 'Chords', drill: 'Chord changes', scales: 'Scales', theory: 'Theory lessons', player: 'Chord player', metronome: 'Metronome',
  backing: 'Backing tracks', songs: 'Play along', songpractice: 'Song practice', 'quiz-fretboard': 'Fretboard quiz',
  'quiz-rhythm': 'Rhythm quiz', 'quiz-ear': 'Ear quiz', 'quiz-scale': 'Scales quiz',
};
const studentsCard = document.getElementById('students-card');
const tbody = document.getElementById('students');
const summary = document.getElementById('summary');
const search = document.getElementById('search');
const pickAll = document.getElementById('pick-all');
const formCard = document.getElementById('plan-card');
const form = document.getElementById('plan-form');
const stepsList = document.getElementById('own-steps');
const picked = document.getElementById('picked');
const assignButton = document.getElementById('assign');
const removeButton = document.getElementById('remove');

let students = [];
let options = { levels: [], goals: [], days: [], minutes: [], pages: [], maxSteps: 12, maxUsers: 300 };
let week = '';
const selected = new Set();

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
const dayLabel = (day) => new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short', timeZone: 'UTC' }).format(new Date(`${day}T12:00:00Z`));
const when = (ms) => new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium' }).format(ms);
const planText = (plan) => `${LEVELS[plan.level] ?? plan.level} · ${plan.days} days · ${plan.minutes} min · ${GOALS[plan.goal] ?? plan.goal}${plan.week ? ` · from week ${plan.week}` : ''}${plan.steps?.length ? ` · ${plan.steps.length} own steps` : ''}`;
const goLogin = () => location.replace('/login?next=%2Fadmin%2Fplans');

function fillSelect(select, values, label = (v) => String(v)) {
  select.replaceChildren(...values.map((value) => el('option', { value: String(value), text: label(value) })));
}

async function load() {
  tbody.setAttribute('aria-busy', 'true');
  const { status, data } = await get('/api/admin/plans');
  tbody.setAttribute('aria-busy', 'false');
  if (status === 401) return goLogin();
  if (status === 403) { location.replace('/account'); return; }
  if (status !== 200) { say(studentsCard, data.error || 'Could not load the students. Please reload the page.'); return; }
  students = data.students;
  week = data.week;
  if (!options.levels.length) {
    options = data.options;
    fillSelect(form.elements.level, options.levels, (v) => LEVELS[v] ?? v);
    fillSelect(form.elements.goal, options.goals, (v) => GOALS[v] ?? v);
    fillSelect(form.elements.days, options.days, (v) => `${v} days`);
    fillSelect(form.elements.minutes, options.minutes, (v) => `${v} min`);
    form.elements.minutes.value = '20';
    form.elements.days.value = '5';
    form.elements.week.replaceChildren(el('option', { value: '', text: 'Keep the student\'s week (week 1 for a new level)' }),
      ...[1, 2, 3, 4, 5, 6, 7, 8].map((n) => el('option', { value: String(n), text: `Week ${n}` })));
    document.getElementById('tz').textContent = data.timeZone === 'Asia/Kolkata' ? 'India time' : data.timeZone;
  }
  for (const id of [...selected]) if (!students.some((s) => s.id === id)) selected.delete(id);
  render();
}

function shown() {
  const q = search.value.trim().toLowerCase();
  return q ? students.filter((s) => s.name.toLowerCase().includes(q) || s.email.toLowerCase().includes(q)) : students;
}

function render() {
  const list = shown();
  tbody.replaceChildren();
  summary.textContent = `${list.length} of ${students.length} students · this week started on Monday ${week ? dayLabel(week) : ''}.`;
  if (!list.length) tbody.append(el('tr', { className: 'empty' }, el('td', { colspan: '6', text: students.length ? 'No student matches the search.' : 'No students yet.' })));
  for (const student of list) {
    const box = el('input', { type: 'checkbox', 'aria-label': `Select ${student.name}` });
    box.checked = selected.has(student.id);
    box.addEventListener('change', () => { if (box.checked) selected.add(student.id); else selected.delete(student.id); updatePicked(); });
    const planCell = student.plan
      ? el('td', {}, el('span', { className: 'badge admin', text: 'Set by teacher' }), ' ', el('span', { text: planText(student.plan) }))
      : el('td', { className: 'muted', text: 'Own plan (the student chooses)' });
    const setCell = el('td', { className: 'nowrap muted', text: student.plan ? `${when(student.planUpdatedAt)}${student.planBy ? ` by ${student.planBy}` : ''}` : '—' });
    const score = student.weekScore === null ? '—' : `${student.weekScore} %`;
    const scoreCell = el('td', { className: 'num nowrap' }, el('strong', { text: score }), student.weekMinutes ? el('span', { className: 'muted', text: ` · ${student.weekMinutes} min` }) : null);
    const edit = el('button', { type: 'button', className: 'btn btn-small', text: student.plan ? 'Edit plan' : 'Set a plan' });
    edit.addEventListener('click', () => editFor(student));
    const status = student.status === 'active' ? null : el('span', { className: `badge ${student.status}`, text: student.status === 'pending' ? 'Waiting' : 'Blocked' });
    tbody.append(el('tr', { className: 'user' },
      el('td', { className: 'pick' }, el('label', { className: 'pick-label' }, box)),
      el('td', {}, el('div', { className: 'user-name', text: student.name }), el('p', { className: 'user-email', text: student.email }), status),
      planCell, setCell, scoreCell, el('td', { className: 'row-actions' }, edit)));
  }
  pickAll.checked = list.length > 0 && list.every((s) => selected.has(s.id));
  updatePicked();
}

function updatePicked() {
  const names = students.filter((s) => selected.has(s.id)).map((s) => s.name);
  picked.textContent = names.length ? `Selected (${names.length}): ${names.slice(0, 8).join(', ')}${names.length > 8 ? ', …' : ''}` : 'No students selected. Tick students in the list above, or press “Set a plan” in a row.';
  assignButton.disabled = !names.length;
  removeButton.disabled = !students.some((s) => selected.has(s.id) && s.plan);
  assignButton.textContent = names.length > 1 ? `Assign to the ${names.length} selected students` : names.length ? `Assign to ${names[0]}` : 'Assign to the selected students';
}

// ---- own steps ----
function addStep(step = { title: '', minutes: 5, page: 'chords', check: 'self' }) {
  if (stepsList.children.length >= options.maxSteps) return;
  const n = stepsList.children.length + 1;
  const id = `step-${Date.now()}-${n}`;
  const title = el('input', { type: 'text', id: `${id}-title`, maxlength: '80', 'data-step': 'title' });
  title.value = step.title;
  const minutes = el('input', { type: 'number', id: `${id}-min`, min: '1', max: '60', inputmode: 'numeric', 'data-step': 'minutes' });
  minutes.value = String(step.minutes);
  const page = el('select', { id: `${id}-page`, 'data-step': 'page' });
  fillSelect(page, options.pages, (v) => PAGE_NAMES[v] ?? v);
  page.value = step.page;
  const check = el('select', { id: `${id}-check`, 'data-step': 'check' });
  fillSelect(check, ['mic', 'self'], (v) => (v === 'mic' ? 'Mic check (2 points)' : 'Self check (1 point)'));
  check.value = step.check;
  const remove = el('button', { type: 'button', className: 'btn btn-small btn-danger', text: 'Remove' });
  const li = el('li', { className: 'own-step' },
    el('div', { className: 'field grow' }, el('label', { for: title.id, text: 'What to practise' }), title),
    el('div', { className: 'field' }, el('label', { for: minutes.id, text: 'Minutes' }), minutes),
    el('div', { className: 'field' }, el('label', { for: page.id, text: 'Opens' }), page),
    el('div', { className: 'field' }, el('label', { for: check.id, text: 'Check' }), check),
    remove);
  remove.addEventListener('click', () => { li.remove(); document.getElementById('add-step').focus(); });
  stepsList.append(li);
  return title;
}
document.getElementById('add-step').addEventListener('click', () => addStep()?.focus());

function fillForm(plan) {
  const f = form.elements;
  f.level.value = plan?.level ?? 'beginner';
  f.week.value = plan?.week ? String(plan.week) : '';
  f.days.value = String(plan?.days ?? 5);
  f.minutes.value = String(plan?.minutes ?? 20);
  f.goal.value = plan?.goal ?? 'songs';
  f.note.value = plan?.note ?? '';
  for (const key of ['days', 'minutes', 'steps', 'tests']) f[`t-${key}`].value = plan?.targets?.[key] ?? '';
  stepsList.replaceChildren();
  for (const step of plan?.steps ?? []) addStep(step);
}

function editFor(student) {
  selected.clear();
  selected.add(student.id);
  fillForm(student.plan);
  render();
  say(formCard, `Editing the plan of ${student.name}.`, 'ok');
  document.getElementById('form-title').focus();
}

function readForm() {
  const f = form.elements;
  const number = (input) => (input.value.trim() === '' ? undefined : Number(input.value));
  const plan = { level: f.level.value, days: Number(f.days.value), minutes: Number(f.minutes.value), goal: f.goal.value };
  if (f.week.value) plan.week = Number(f.week.value);
  if (f.note.value.trim()) plan.note = f.note.value.trim();
  const targets = {};
  for (const key of ['days', 'minutes', 'steps', 'tests']) { const v = number(f[`t-${key}`]); if (v !== undefined) targets[key] = v; }
  if (Object.keys(targets).length) plan.targets = targets;
  const steps = [...stepsList.children].map((li) => ({
    title: li.querySelector('[data-step="title"]').value.trim(), minutes: Number(li.querySelector('[data-step="minutes"]').value),
    page: li.querySelector('[data-step="page"]').value, check: li.querySelector('[data-step="check"]').value,
  }));
  if (steps.length) plan.steps = steps;
  return plan;
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const userIds = [...selected];
  if (!userIds.length) { say(formCard, 'Please select at least one student first.'); return; }
  busy(assignButton, true, 'Saving…');
  const { status, data } = await post('/api/admin/plans/assign', { userIds, plan: readForm() });
  busy(assignButton, false);
  if (status === 401) return goLogin();
  if (status !== 200) { say(formCard, data.error || 'Could not save the plan. Please try again.'); return; }
  say(formCard, `Plan saved for ${data.assigned} ${data.assigned === 1 ? 'student' : 'students'}. They see it the next time they open the Practice plan.`, 'ok');
  await load();
});

removeButton.addEventListener('click', async () => {
  const chosen = students.filter((s) => selected.has(s.id) && s.plan);
  if (!chosen.length) return;
  if (!confirm(`Remove the teacher plan from ${chosen.length === 1 ? chosen[0].name : `${chosen.length} students`}? They can then make their own plan again. Their scores stay.`)) return;
  busy(removeButton, true, 'Removing…');
  const { status, data } = await post('/api/admin/plans/remove', { userIds: chosen.map((s) => s.id) });
  busy(removeButton, false);
  if (status === 401) return goLogin();
  if (status !== 200) { say(formCard, data.error || 'Could not remove the plan. Please try again.'); return; }
  say(formCard, `Plan removed for ${data.removed} ${data.removed === 1 ? 'student' : 'students'}.`, 'ok');
  await load();
});

document.getElementById('clear').addEventListener('click', () => { fillForm(null); say(formCard, ''); });
pickAll.addEventListener('change', () => { for (const s of shown()) { if (pickAll.checked) selected.add(s.id); else selected.delete(s.id); } render(); });
search.addEventListener('input', render);
document.getElementById('search-form').addEventListener('submit', (event) => event.preventDefault());
document.getElementById('logout').addEventListener('click', async (event) => {
  busy(event.currentTarget, true, 'Logging out…');
  await post('/api/logout');
  markLoggedOut();
  location.replace('/login');
});

load();
