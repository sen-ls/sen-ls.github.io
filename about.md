---
layout: page
title: About
permalink: /about/
---

<div>
  <button onclick="showContent('english')">English</button>
  <button onclick="showContent('german')">Deutsch</button>
</div>

<div id="english" class="language-content">
  <h1>👋 About Me</h1>
  <p>
    Hi, I'm <strong>Sen Liao</strong>, an engineer and lifelong learner passionate about <strong>networking</strong>, <strong>embedded systems</strong>, and <strong>optical computing for HPC</strong>.
  </p>
  <p>
    I graduated with both <strong>Bachelor’s and Master’s degrees in Electrical and Information Technology</strong> from the <strong>Technical University of Munich (TUM)</strong>, where I focused on <strong>embedded design</strong> and <strong>hardware–software co-development</strong>.
    During my studies, I worked on <strong>AUTOSAR ECU base software</strong> development and completed my <strong>Master’s thesis</strong> at <strong>Infineon Technologies</strong>, optimizing process-related task identification for the <strong>AURIX microcontroller series</strong>.
  </p>
  <p>
    Currently, I work as a <strong>Network Engineer</strong>, focusing on <strong>data center networking, EVPN/VXLAN architectures, and system automation</strong>.
    This website is my personal space to share <strong>projects, notes, and learning insights</strong> — from embedded and network systems to modern computing architectures.
  </p>
  <p>
    If you’re interested in my work or want to discuss something technical, feel free to reach out:<br>
    📧 <strong>sen.liao@outlook.com</strong>
  </p>
</div>

<div id="german" class="language-content" style="display:none;">
  <h1>👋 Über mich</h1>
  <p>
    Hallo! Ich heiße <strong>Sen Liao</strong> und bin Ingenieur mit einer Leidenschaft für <strong>Netzwerktechnik</strong>, <strong>eingebettete Systeme</strong> und <strong>optisches Rechnen im Hochleistungsumfeld (HPC)</strong>.
  </p>
  <p>
    Ich habe sowohl meinen <strong>Bachelor- als auch Masterabschluss in Electrical and Information Technology</strong> an der <strong>Technischen Universität München (TUM)</strong> erworben.
    Mein Studienschwerpunkt lag im Bereich <strong>Embedded Design</strong>. Während des Studiums arbeitete ich an der Entwicklung von <strong>AUTOSAR-ECU-Basisssoftware</strong> und verfasste meine <strong>Masterarbeit bei Infineon Technologies</strong>, in der ich Prozesse zur <strong>Aufgabenidentifikation auf AURIX-Mikrocontrollern</strong> optimierte.
  </p>
  <p>
    Derzeit arbeite ich als <strong>Netzwerkingenieur</strong> mit Fokus auf <strong>Rechenzentrumsnetzwerke, EVPN/VXLAN-Architekturen und Systemautomatisierung</strong>.
    Auf dieser Webseite teile ich meine <strong>Projekte, technische Notizen und Lernerfahrungen</strong> – von eingebetteten Systemen bis hin zu modernen Rechenarchitekturen.
  </p>
  <p>
    Wenn Sie sich für meine Inhalte interessieren oder Fragen haben, können Sie mich gerne kontaktieren:<br>
    📧 <strong>sen.liao@outlook.com</strong>
  </p>
</div>

<script>
  function showContent(language) {
    document.getElementById('english').style.display = language === 'english' ? 'block' : 'none';
    document.getElementById('german').style.display = language === 'german' ? 'block' : 'none';
  }
</script>

<style>
  button {
    margin: 5px;
    padding: 10px 15px;
    font-size: 16px;
    cursor: pointer;
  }

  .language-content {
    margin-top: 20px;
  }
</style>