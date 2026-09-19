#!/usr/bin/env python3
"""Gera o sitemap.xml a partir das pastas de content.1bit/.

Cada pasta com um index.html vira uma URL. O lastmod sai da data do proprio
post (<p class="datetime">Em DD/MM/AAAA HH:MM</p>); quando nao existe, usa o
timestamp Unix que da nome a pasta do post antigo.

Uso: python3 generate_sitemap.py
"""

import io
import os
import re
import subprocess
from datetime import datetime, timezone

BASE = "https://1bit.com.br"
ROOT = os.path.dirname(os.path.abspath(__file__))

# Paginas de listagem/busca: bloqueadas no robots.txt ou sem conteudo proprio.
SKIP = {
    "busca",
    "weblog_archive",
    "weblog_categ",
    "www.1bit.com.br",
    "www.cloudflare.com",
}

DATETIME_RE = re.compile(r'class="datetime">\s*Em\s+(\d{1,2})/(\w{1,3})/(\d{4})')
MONTHS = {
    "01": 1, "02": 2, "03": 3, "04": 4, "05": 5, "06": 6,
    "07": 7, "08": 8, "09": 9, "10": 10, "11": 11, "12": 12,
    "jan": 1, "feb": 2, "fev": 2, "mar": 3, "apr": 4, "abr": 4,
    "may": 5, "mai": 5, "jun": 6, "jul": 7, "aug": 8, "ago": 8,
    "sep": 9, "set": 9, "oct": 10, "out": 10, "nov": 11,
    "dec": 12, "dez": 12,
}


def post_date(path, dirname):
    """Data de publicacao como AAAA-MM-DD, ou None."""
    try:
        html = io.open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        html = ""
    m = DATETIME_RE.search(html)
    if m:
        day, month, year = m.group(1), m.group(2).lower(), int(m.group(3))
        month = MONTHS.get(month.zfill(2) if month.isdigit() else month)
        if month and 1990 < year < 2100:
            try:
                return datetime(year, month, int(day)).strftime("%Y-%m-%d")
            except ValueError:
                pass
    # Posts antigos usam o timestamp Unix como nome da pasta.
    if dirname.isdigit() and len(dirname) == 10:
        return datetime.fromtimestamp(int(dirname), timezone.utc).strftime("%Y-%m-%d")
    return git_date(path)


def git_date(path):
    """Data do ultimo commit que tocou o arquivo, para paginas sem data propria."""
    try:
        out = subprocess.run(["git", "log", "-1", "--format=%cs", "--", path],
                             cwd=ROOT, capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return None
    date = out.stdout.strip()
    return date or None


def collect():
    """[(url, lastmod)] com a home primeiro, depois artigos e posts."""
    urls = [(BASE + "/", git_date(os.path.join(ROOT, "index.html")))]
    content = os.path.join(ROOT, "content.1bit")

    for name in sorted(os.listdir(content)):
        if name in SKIP or name == "weblog":
            continue
        index = os.path.join(content, name, "index.html")
        if os.path.isfile(index):
            urls.append(("%s/content.1bit/%s" % (BASE, name), git_date(index)))

    weblog = os.path.join(content, "weblog")
    urls.append(("%s/content.1bit/weblog" % BASE,
                 git_date(os.path.join(weblog, "index.html"))))
    posts = []
    for name in sorted(os.listdir(weblog)):
        if name in SKIP:
            continue
        index = os.path.join(weblog, name, "index.html")
        if not os.path.isfile(index):
            continue
        posts.append(("%s/content.1bit/weblog/%s" % (BASE, name),
                      post_date(index, name)))
    # Mais recentes primeiro; sem data vao para o fim.
    posts.sort(key=lambda p: (p[1] is not None, p[1] or ""), reverse=True)
    return urls + posts


def main():
    urls = collect()
    out = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for url, lastmod in urls:
        out.append("  <url>")
        out.append("    <loc>%s</loc>" % url)
        if lastmod:
            out.append("    <lastmod>%s</lastmod>" % lastmod)
        out.append("  </url>")
    out.append("</urlset>")
    out.append("")

    path = os.path.join(ROOT, "sitemap.xml")
    io.open(path, "w", encoding="utf-8").write("\n".join(out))
    dated = sum(1 for _, d in urls if d)
    print("sitemap.xml: %d URLs (%d com lastmod)" % (len(urls), dated))


if __name__ == "__main__":
    main()
