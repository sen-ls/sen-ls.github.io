---
layout: post
title: "Datacenter Classical BGP and VXLAN Configuration"
categories: [networking, datacenter]
tags: [bgp, vxlan, configuration]
---

<div>
  <button onclick="showContent('english')">English</button>
  <button onclick="showContent('german')">Deutsch</button>
</div>

<div id="english" class="language-content">
  <h2>Datacenter Classical BGP and VXLAN Configuration</h2>
  <p>
    This blog post explains the configuration of BGP and VXLAN in a datacenter environment.  
    The goal is to achieve a scalable and efficient network design through classical underlay and overlay separation.
  </p>

  <h3>Experimental Topology</h3>
  <p>
    The following topology diagram (<code>TOPO-realistic.png</code>) shows the setup used for this experiment.  
    It includes the IRF leaf stack, spine, leaf2, and connected servers/clients for DHCP relay and VXLAN overlay testing.
  </p>

  <p align="center">
    <img src="{{ '/assets/imges/2025-10-15/TOPO-realistic.png' | relative_url }}"
         alt="Experimental Topology"
         style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
  </p>

  <h3>Steps:</h3>
  <ol>
    <li>Establish the IRF connection between leaf switches and connect to the server.  
        Clients under the IRF leaf obtain IP addresses via DHCP relay  
        (<strong>no VLAN interfaces configured on leaf</strong>).</li>
    <li>Set up <strong>eBGP</strong> sessions between the spine, IRF leaf, and leaf2  
        to build the <strong>underlay network</strong>.</li>
    <li>Establish a <strong>VXLAN tunnel</strong> between the two leaf switches  
        and configure <strong>iBGP</strong> for the <strong>overlay network</strong>.</li>
    <li>Verify that leaf2 can communicate with the server, and that clients under leaf2  
        can obtain DHCP-assigned IP addresses through the VXLAN overlay.</li>
  </ol>
</div>

<div id="german" class="language-content" style="display:none;">
  <h2>Datacenter Klassische BGP- und VXLAN-Konfiguration</h2>
  <p>
    Dieser Blogbeitrag erklärt die Konfiguration von BGP und VXLAN in einer Datacenter-Umgebung.  
    Ziel ist es, durch die Trennung von Underlay und Overlay ein skalierbares und effizientes Netzwerkdesign zu erreichen.
  </p>

  <h3>Experimentelle Topologie</h3>
  <p>
    Das folgende Topologiebild (<code>TOPO-realistic.png</code>) zeigt den Versuchsaufbau.  
    Es umfasst den IRF-Leaf-Stack, Spine, Leaf2 sowie die verbundenen Server und Clients zur Überprüfung des DHCP-Relay- und VXLAN
