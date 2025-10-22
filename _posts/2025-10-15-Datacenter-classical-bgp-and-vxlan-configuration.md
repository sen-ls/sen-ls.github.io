---
layout: post
title: "Datacenter Classical BGP and VXLAN Configuration"
categories: [networking, datacenter]
tags: [bgp, vxlan, configuration]
---

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
  <img src="{{ '/assets/images/2025-10-15/TOPO-realistic.png' | relative_url }}"
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

<h3>Specific Configuration</h3>
<h4>IRF Leaf</h4>
<p>
  Configure two switches as an IRF stack. The following diagram (<code>irf dis irf.png</code>) illustrates the setup:
</p>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/irf dis irf.png' | relative_url }}"
       alt="IRF Stack Configuration"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>
