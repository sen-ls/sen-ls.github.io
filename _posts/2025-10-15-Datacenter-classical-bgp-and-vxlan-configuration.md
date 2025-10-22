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
<h4><strong>First Step</strong>:IRF Leaf Configuration</h4>
<p>
  Configure two switches as an IRF stack. The following diagram (<code>irf dis irf.png</code>) illustrates the setup:
</p>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/irf dis irf.png' | relative_url }}"
       alt="IRF Stack Configuration"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>

<p>
  And also configure the underlay interface pointed to the spine switch
</p>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/irf int spine.png' | relative_url }}"
       alt="IRF Spine Interface Configuration"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>

<h3>VRF / EVPN Instance: <code>vpn1</code></h3>

<p>
  The following configuration creates a tenant VRF (<code>vpn1</code>) and assigns
  Route Distinguisher (RD) and Route Targets (RTs) for both IPv4 VPN and EVPN
  address-families.
</p>

<pre><code>ip vpn-instance vpn1
 route-distinguisher 1:2
 vpn-target 2:2 import-extcommunity
 vpn-target 2:2 export-extcommunity
 #
 address-family ipv4
  vpn-target 2:2 import-extcommunity
  vpn-target 2:2 export-extcommunity
 #
 address-family evpn
  vpn-target 2:2 import-extcommunity
  vpn-target 2:2 export-extcommunity
</code></pre>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/irf vpninstance1.png' | relative_url }}"
       alt="vpn-instance vpn1 configuration overview"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>

<h4>Why these lines matter</h4>
<ul>
  <li><strong><code>ip vpn-instance vpn1</code></strong> — Creates a VRF named <em>vpn1</em>.
      This is the tenant routing table used by your overlay (and any L3 gateways you later bind to it).</li>

  <li><strong><code>route-distinguisher 1:2</code></strong> — RD makes per-VRF routes globally
      unique in BGP (VPNv4/EVPN). The format is typically <code>&lt;ASN&gt;:&lt;ID&gt;</code> (or
      <code>&lt;IP&gt;:&lt;ID&gt;</code>). It does <em>not</em> control import/export; it’s only an
      identifier. Best practice: keep the RD <em>unique per PE per VRF</em> (it does not need to match across devices).</li>

  <li><strong><code>vpn-target 2:2 import/export-extcommunity</code> (global)</strong> — Sets default
      Route Targets for this VRF. RTs are extended-community tags that control which routes a VRF
      <em>imports</em> and which it <em>exports</em>. Using the same RT (<code>2:2</code>) for both
      import and export means all PEs that use RT <code>2:2</code> will form a full-mesh “sharing group”
      (typical for any-to-any tenant). For hub-and-spoke you would use asymmetric RTs.</li>

  <li><strong><code>address-family ipv4</code> … RTs</strong> — Applies the same RT policy to VPNv4
      unicast. Use this when advertising/learning IPv4 prefixes inside the tenant (e.g., static routes, L3
      interfaces bound to this VRF, or DHCP relay next-hops carried as routes).</li>

  <li><strong><code>address-family evpn</code> … RTs</strong> — Applies the same RT policy to EVPN routes
      (MAC/IP, IRB/Type-5, etc.). This is what lets your VXLAN overlay exchange MAC and IP reachability
      for the same tenant across leaves.</li>
</ul>

<p><em>Notes:</em> In Step&nbsp;1 you keep the IRF leaf without VLAN interfaces (pure L2 + DHCP relay).
Later, when you enable L3 gateway for the tenant, you will bind the relevant SVI/VBDIF or interface to
<code>vpn1</code> so routed traffic uses this VRF. Ensuring matching RTs (<code>2:2</code>) across both leaves
guarantees that EVPN/VPNv4 routes for this tenant are imported on all participating PEs.</p>

