// Dark/light toggle for the CV. Initialises from localStorage if set,
// otherwise from the OS preference, and persists the choice. Also fires
// before the layout paints so we don't get a flash of the wrong theme.
//
// Lives on `.cv-layout` rather than <html> so the same script works
// whether the CV is the whole page (standalone preview) or embedded
// inside another site that has its own theming.
(function () {
  var STORAGE_KEY = 'cv-theme';

  function layouts() {
    return document.querySelectorAll('.cv-layout');
  }

  function apply(theme) {
    layouts().forEach(function (el) { el.dataset.theme = theme; });
    document.querySelectorAll('[data-cv-theme-toggle]').forEach(function (btn) {
      var label = btn.querySelector('.cv-theme-label');
      var icon  = btn.querySelector('.cv-theme-icon');
      if (label) label.textContent = theme === 'dark' ? 'Dark' : 'Light';
      if (icon)  icon.textContent  = theme === 'dark' ? '☾' : '☀';
      btn.setAttribute('aria-pressed', theme === 'dark' ? 'true' : 'false');
    });
  }

  function preferredTheme() {
    try {
      var stored = localStorage.getItem(STORAGE_KEY);
      if (stored === 'dark' || stored === 'light') return stored;
    } catch (_) { /* localStorage may be disabled */ }
    return window.matchMedia &&
           window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark' : 'light';
  }

  // Apply early to avoid a flash on first paint.
  apply(preferredTheme());

  function init() {
    apply(preferredTheme());
    document.querySelectorAll('[data-cv-theme-toggle]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var els = layouts();
        var cur = els.length && els[0].dataset.theme === 'dark' ? 'dark' : 'light';
        var next = cur === 'dark' ? 'light' : 'dark';
        apply(next);
        try { localStorage.setItem(STORAGE_KEY, next); } catch (_) {}
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
