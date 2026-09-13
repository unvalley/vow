const expressions = [...document.querySelectorAll('.demo-expression')];
const next = document.querySelector('.next-expression');
if (next && expressions.length > 1) {
  let current = 0;
  next.hidden = false;
  next.addEventListener('click', () => {
    expressions[current].hidden = true;
    expressions[current].querySelector('details').open = false;
    current = (current + 1) % expressions.length;
    expressions[current].hidden = false;
    document.getElementById('demo-status').textContent = expressions[current].dataset.phrase;
  });
}
