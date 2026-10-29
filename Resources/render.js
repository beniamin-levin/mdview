// Heading ids so in-page links like [Setup](#setup) work.
const slug = s => s.toLowerCase().trim().replace(/<[^>]+>/g, '').replace(/[^\p{L}\p{N}\s-]/gu, '').replace(/\s+/g, '-');
marked.use({
  gfm: true,
  renderer: {
    heading({ tokens, depth }) {
      const html = this.parser.parseInline(tokens);
      return `<h${depth} id="${slug(html)}">${html}</h${depth}>\n`;
    }
  }
});

// Called from Swift with the file text and the file's folder (so relative images resolve).
function render(md, base) {
  document.getElementById('base').href = base;
  md = md.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, ''); // drop YAML front matter
  document.getElementById('content').innerHTML = marked.parse(md);
}

document.addEventListener('click', e => {
  const a = e.target.closest('a');
  const href = a && a.getAttribute('href');
  if (href && href.startsWith('#')) {
    e.preventDefault();
    document.getElementById(decodeURIComponent(href.slice(1)))?.scrollIntoView();
  }
});
