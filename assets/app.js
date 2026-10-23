const escapeHTML = text => text.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const stageList = document.getElementById('stage-list');
const stageDetail = document.getElementById('stage-detail');
const stageSelect = document.getElementById('stage-select');
let currentStage = null;
let currentPrompt = 0;
let step = 0;

const stagePromptText = (stageIndex, promptIndex) => flowStages[stageIndex].prompts[promptIndex].text;
const lastStageIndex = () => flowStages.length - 1;

stageSelect.innerHTML += flowStages.map((stage, index) =>
  `<option value="${index}">${index + 1}. ${escapeHTML(stage.title)}</option>`
).join('');

stageList.innerHTML = flowStages.map((stage, index) =>
  `<a href="#stage/${stage.id}" data-stage="${index}"><span class="stage-number">${index + 1}</span><span>${escapeHTML(stage.title)}</span></a>`
).join('');

function stageActions(index) {
  const prev = index > 0
    ? `<a href="#stage/${flowStages[index - 1].id}">Previous step</a>`
    : '';
  const next = index < lastStageIndex()
    ? `<a class="primary" href="#stage/${flowStages[index + 1].id}">Go to ${escapeHTML(flowStages[index + 1].title)}</a>`
    : '';
  return `<nav class="stage-actions" aria-label="Next step actions">${prev}${next}</nav>`;
}

function renderStage(index) {
  if (currentStage !== index) currentPrompt = 0;
  currentStage = index;
  const stage = flowStages[index];
  document.getElementById('entry-choices').hidden = true;
  document.getElementById('stage-workspace').hidden = false;
  document.getElementById('change-entry').hidden = false;
  document.getElementById('library').classList.add('has-stage');
  document.getElementById('library-title').textContent = 'Your ticket flow';
  document.getElementById('flow-intro').textContent =
    'Select where your work is now. Check the exit conditions before moving on.';
  stageSelect.value = String(index);
  document.querySelector('#stage-picker label').textContent = 'Current step';
  stageList.querySelectorAll('a').forEach((link, i) => {
    if (i === index) link.setAttribute('aria-current', 'step');
    else link.removeAttribute('aria-current');
  });
  const text = stagePromptText(index, currentPrompt);
  const options = stage.prompts.length > 1
    ? `<label for="stage-action">Choose an action</label><select id="stage-action">${
      stage.prompts.map((prompt, i) =>
        `<option value="${i}" ${i === currentPrompt ? 'selected' : ''}>${escapeHTML(prompt.title)}</option>`
      ).join('')
    }</select>`
    : '';
  stageDetail.innerHTML = `
    <span class="tag">You are here · Step ${index + 1} of ${flowStages.length}</span>
    <h2 tabindex="-1">${escapeHTML(stage.title)}</h2>
    <p>${escapeHTML(stage.when)}</p>
    <div class="flow-inputs">
      <p><strong>Have ready:</strong> ${escapeHTML(stage.input)}</p>
      <p><strong>Leave with:</strong> ${escapeHTML(stage.output)}</p>
    </div>
    ${options}
    <div class="prompt-bar">
      <button class="copy" data-stage-copy>Copy ${escapeHTML(stage.prompts[currentPrompt].title.toLowerCase())} prompt</button>
      <span class="token-count" title="Template only; excludes the context you add. Rough character-based estimate.">Template ≈${Math.ceil(text.length / 4)} tokens</span>
    </div>
    <pre class="prompt">${escapeHTML(text)}</pre>
    <div class="stage-gate">
      <h3>Ready to move on when</h3>
      <ul>${stage.gate.map(check => `<li>${escapeHTML(check)}</li>`).join('')}</ul>
    </div>
    ${stageActions(index)}
    <p class="helper">Moving between steps does not approve work or mark anything complete.</p>`;
}

function showEntry() {
  currentStage = null;
  currentPrompt = 0;
  document.getElementById('entry-choices').hidden = false;
  document.getElementById('stage-workspace').hidden = true;
  document.getElementById('change-entry').hidden = true;
  document.getElementById('library').classList.remove('has-stage');
  document.getElementById('library-title').textContent = 'Where are you starting?';
  document.getElementById('flow-intro').textContent =
    'Choose what you already have. Start there, then work through one step at a time.';
  document.querySelector('#stage-picker label').textContent = 'Or choose your current step';
  stageSelect.value = '';
}

function goStage(index) {
  const hash = '#stage/' + flowStages[index].id;
  if (location.hash === hash) {
    renderStage(index);
    stageDetail.querySelector('h2').focus();
  } else {
    location.hash = hash;
  }
}

document.getElementById('entry-choices').addEventListener('click', event => {
  const button = event.target.closest('[data-entry]');
  if (button) goStage(Number(button.dataset.entry));
});
stageSelect.addEventListener('change', () => {
  if (stageSelect.value !== '') goStage(Number(stageSelect.value));
});
document.getElementById('change-entry').addEventListener('click', () => {
  showEntry();
  if (location.hash !== '#library') location.hash = 'library';
  else document.getElementById('library-title').focus();
});
stageDetail.addEventListener('change', event => {
  if (event.target.id === 'stage-action') {
    currentPrompt = Number(event.target.value);
    renderStage(currentStage);
    document.getElementById('stage-action').focus();
  }
});

const rulesList = document.getElementById('hard-rules-list');
if (rulesList) {
  rulesList.innerHTML = hardRules.map(rule => `<li>${escapeHTML(rule)}</li>`).join('');
}

const impactPre = document.getElementById('impact-area-text');
if (impactPre && typeof impactAreaTemplate === 'string') {
  impactPre.textContent = impactAreaTemplate;
}

const glossaryEl = document.getElementById('glossary-dl');
if (glossaryEl && typeof glossary !== 'undefined') {
  glossaryEl.innerHTML = glossary.map(item =>
    `<dt>${escapeHTML(item.term)}</dt><dd>${escapeHTML(item.def)}</dd>`
  ).join('');
}

const steps = [...document.querySelectorAll('.lesson-step')];
const lessonNav = document.getElementById('lesson-nav');
lessonNav.innerHTML = steps.map((item, index) => {
  const label = item.querySelector('h3').textContent.replace(/^\d+\. /, '');
  return `<button data-step="${index}" aria-label="Step ${index + 1}: ${escapeHTML(label)}">${index + 1}</button>`;
}).join('');

function showStep(index, focus = false) {
  step = Math.max(0, Math.min(steps.length - 1, index));
  steps.forEach((panel, i) => { panel.hidden = i !== step; });
  lessonNav.querySelectorAll('button').forEach((button, i) => {
    if (i === step) button.setAttribute('aria-current', 'step');
    else button.removeAttribute('aria-current');
  });
  document.getElementById('lesson-status').textContent = `Step ${step + 1} of ${steps.length}`;
  document.getElementById('previous-step').disabled = step === 0;
  document.getElementById('next-step').textContent =
    step === steps.length - 1 ? 'Open ticket flow' : 'Next step';
  if (focus) {
    const heading = steps[step].querySelector('h3');
    heading.tabIndex = -1;
    heading.focus();
  }
}

lessonNav.addEventListener('click', event => {
  const button = event.target.closest('[data-step]');
  if (button) showStep(Number(button.dataset.step), true);
});
document.getElementById('previous-step').addEventListener('click', () => showStep(step - 1, true));
document.getElementById('next-step').addEventListener('click', () => {
  if (step === steps.length - 1) location.hash = 'library';
  else showStep(step + 1, true);
});

const views = ['library', 'start', 'guides'];
function route(focus = false) {
  let id;
  try { id = decodeURIComponent(location.hash.slice(1)); } catch { id = 'library'; }
  const target = document.getElementById(id);
  const stageIndex = id.startsWith('stage/')
    ? flowStages.findIndex(stage => stage.id === id.slice(6))
    : -1;
  let view = id === 'start' || target?.closest('#start')
    ? 'start'
    : id === 'guides' || id === 'glossary' || target?.closest('#guides')
      ? 'guides'
      : 'library';
  if (id === 'main') {
    view = document.querySelector('header nav a[aria-current=page]')?.hash.slice(1) || 'library';
  }
  if (stageIndex >= 0) renderStage(stageIndex);
  else if (id === '' || id === 'library' || id.startsWith('stage/')) showEntry();

  views.forEach(name => { document.getElementById(name).hidden = name !== view; });
  document.getElementById('glossary').hidden = view !== 'guides';
  const faq = document.getElementById('faq');
  if (faq) faq.hidden = view !== 'guides';

  document.querySelectorAll('header nav a').forEach(link => {
    if (link.hash === '#' + view) link.setAttribute('aria-current', 'page');
    else link.removeAttribute('aria-current');
  });
  if (view === 'start' && target?.classList.contains('lesson-step')) {
    showStep(steps.indexOf(target));
  }
  if (target?.tagName === 'DETAILS') target.open = true;
  const section = document.getElementById(view);
  section.classList.remove('view-enter');
  requestAnimationFrame(() => section.classList.add('view-enter'));
  if (focus) {
    const heading = stageIndex >= 0
      ? stageDetail.querySelector('h2')
      : section.querySelector('h1');
    heading.tabIndex = -1;
    heading.focus({ preventScroll: true });
  }
  if (target && target !== section && view === 'guides') {
    target.scrollIntoView({ block: 'start' });
  } else {
    window.scrollTo(0, 0);
  }
}

window.addEventListener('hashchange', () => route(true));
document.addEventListener('click', async event => {
  const link = event.target.closest('a[href^="#"]');
  if (link) {
    const hash = link.getAttribute('href');
    if (hash === location.hash) {
      event.preventDefault();
      route(true);
    }
    return;
  }
  const button = event.target.closest('[data-copy-source],[data-stage-copy]');
  if (!button) return;
  const text = button.hasAttribute('data-copy-source')
    ? document.getElementById(button.dataset.copySource).textContent
    : stagePromptText(currentStage, currentPrompt);
  const label = button.textContent;
  const status = document.getElementById('copy-status');
  button.disabled = true;
  try {
    await navigator.clipboard.writeText(text);
    button.textContent = 'Copied';
    if (status) status.textContent = 'Copied. Paste into your IDE agent or notes.';
    setTimeout(() => { button.textContent = label; button.disabled = false; }, 1400);
  } catch {
    button.disabled = false;
    button.parentElement.querySelector('.copy-fallback')?.remove();
    const fallback = document.createElement('div');
    fallback.className = 'copy-fallback';
    const caption = document.createElement('label');
    caption.textContent = 'Select and copy:';
    const area = document.createElement('textarea');
    area.value = text;
    area.readOnly = true;
    area.rows = 8;
    area.id = 'manual-copy-' + Date.now();
    caption.htmlFor = area.id;
    fallback.append(caption, area);
    button.after(fallback);
    area.focus();
    area.select();
    if (status) status.textContent = 'Clipboard unavailable. Selectable text shown.';
  }
});

showEntry();
showStep(0);
route();
