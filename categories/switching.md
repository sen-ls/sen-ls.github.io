---
layout: page
title: Switching
permalink: /categories/switching/
---

<h2>Switching Articles</h2>
<ul>
{% assign posts = site.categories.switching | sort: 'date' | reverse %}
{% if posts and posts.size > 0 %}
  {% for post in posts %}
    <li>
      <span class="post-meta">{{ post.date | date: "%Y-%m-%d" }}</span> —
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    </li>
  {% endfor %}
{% else %}
  <p>暂无文章（Coming soon）</p>
{% endif %}
</ul>
