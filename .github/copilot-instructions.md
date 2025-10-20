# AI Coding Agent Instructions for `sen-ls.github.io`

## Project Overview
This repository hosts a technical blog built with Jekyll and the `minima` theme. It is designed for publishing notes, experiments, and how-to guides. The blog is deployed via GitHub Pages.

### Key Directories and Files
- `_posts/`: Contains blog posts written in Markdown. Follow the naming convention `YYYY-MM-DD-title.md`.
- `_config.yml`: Configuration file for Jekyll, including site metadata, theme settings, and plugins.
- `assets/css/custom.css`: Custom styles for the blog.
- `_includes/custom-footer.html`: Custom HTML for the site footer.
- `README.md`: Quick start guide for setting up and running the blog.

## Writing Blog Posts
1. Create a new Markdown file in `_posts/`.
2. Use the following front matter template:

   ```yaml
   ---
   layout: post
   title: "Your post title"
   categories: [category1, category2]
   tags: [tag1, tag2]
   ---
   ```
3. Write content in Markdown. Place images in `assets/img/` and reference them as `![alt text](/assets/img/filename.png)`.

## Local Development
To preview the site locally:
1. Install dependencies:
   ```bash
   gem install bundler jekyll
   bundle init
   echo 'gem "github-pages", group: :jekyll_plugins' >> Gemfile
   bundle install
   ```
2. Serve the site locally:
   ```bash
   bundle exec jekyll serve
   ```
3. Open `http://localhost:4000` in your browser.

## Customization
- **CSS**: Modify `assets/css/custom.css` for styling.
- **Footer**: Edit `_includes/custom-footer.html` to update the footer content.
- **Configuration**: Update `_config.yml` for site-wide settings like title, author, and social links.

## Deployment
1. Push changes to the `main` branch.
2. GitHub Pages will automatically deploy the site.

## Conventions
- Use descriptive commit messages.
- Follow the Markdown syntax for Jekyll posts.
- Keep CSS changes scoped to avoid overriding theme defaults.

## External Dependencies
- Jekyll plugins: `jekyll-feed`, `jekyll-seo-tag`.
- LinkedIn badge script in `_includes/custom-footer.html`.

## Examples
- Example post: `_posts/2025-10-16-hello-github-pages.md`.
- Example CSS customization: `assets/css/custom.css`.

---

For further questions, refer to the `README.md` or the [Jekyll documentation](https://jekyllrb.com/docs/).