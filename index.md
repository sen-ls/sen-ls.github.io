---
layout: home
title: Home
---

<div style="text-align: center; margin-top: 20px;">
  <h1>Welcome to My Technical Blog</h1>
  <p>
    Here, I share insights, technology blogs, and important lessons learned during my work as a network engineer. 
    This is a space for documenting experiments, configurations, and solutions to challenging problems.
  </p>
</div>
Browse by category:
<ul>
{% for category in site.categories %}
  <li>
    <a href="{{ '/categories/' | append: category[0] | relative_url }}">
      {{ category[0] | capitalize }}
    </a> ({{ category[1].size }})
  </li>
{% endfor %}
</ul>
<hr style="margin: 20px 0;">

