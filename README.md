# GitHub Pages Tech Blog (Jekyll + minima)

## Quick start
1) Create a **new public repo** named `YOURNAME.github.io` (user site), or any name for a project site.
2) Upload all files from this folder to the repo root (drag & drop in GitHub works).
3) In **Settings → Pages**, set:
   - **Build and deployment**: *Deploy from a branch*
   - **Branch**: `main` (or the default branch) and `/ (root)`
4) Wait ~1 minute and open `https://YOURNAME.github.io` (or `https://YOURNAME.github.io/REPO` for project sites).

## Write a post
- Add a Markdown file under `_posts/` named `YYYY-MM-DD-title.md`.
- Use the front matter template below:

```yaml
---
layout: post
title: "Your post title"
categories: [notes, howto]
tags: [vxlan, evpn, pytorch]
---
```

Then write in Markdown. Images can be put under `assets/img/` and referenced as `![alt](/assets/img/your.png)`.

## Local preview (optional)
If you want to run it locally:
```bash
gem install bundler jekyll
bundle init
echo 'gem "github-pages", group: :jekyll_plugins' >> Gemfile
bundle install
bundle exec jekyll serve
```

## Tips
- For a **project site**, set `baseurl: "/REPO-NAME"` in `_config.yml` and access via `/REPO-NAME/...`.
- Edit `_config.yml` to update title, author, and social links.
