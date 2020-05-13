document.addEventListener('DOMContentLoaded', (event) => {
  document.querySelectorAll('code').forEach((block) => {
    hljs.highlightBlock(block);
  });
});
