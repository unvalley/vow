// The hero recording plays muted on a loop. Reduce Motion starts it paused on its first frame,
// and the button pauses or resumes it either way.
const video = document.querySelector('.hero-video video');
const toggle = document.querySelector('.video-toggle');
if (video && toggle) {
  const show = () => {
    const paused = video.paused;
    toggle.classList.toggle('is-paused', paused);
    toggle.setAttribute('aria-label', paused ? toggle.dataset.play : toggle.dataset.pause);
  };
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) video.pause();
  video.addEventListener('play', show);
  video.addEventListener('pause', show);
  toggle.addEventListener('click', () => (video.paused ? video.play() : video.pause()));
  toggle.hidden = false;
  show();
}
