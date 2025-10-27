---
layout: post
title: "Datacenter Classical BGP and VXLAN Configuration"
categories: [networking, datacenter]
tags: [bgp, vxlan, configuration]
---

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

<p>
  The devices (switches) used in this setup must support both DHCP relay and L2VPN functionalities as mandatory features.  
  In this blog, the HCL simulation tool from H3C is used to realize the configuration and testing.
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

<h4>VRF / EVPN Instance: <code>vpn1</code></h4>

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

<h5>Why these lines matter</h5>
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

<h3>SVI/VBDIF (IRB) Interfaces on the IRF leaf</h3>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/irf vsi int.png' | relative_url }}"
       alt="IRF leaf Vsi-interface configuration"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>

<pre><code>interface Vsi-interface102
 ip binding vpn-instance vpn1
 ip address 10.1.0.254 255.255.255.0
 mac-address 0001-0001-0001
 local-proxy-arp enable
 distributed-gateway local

interface Vsi-interface103
 ip binding vpn-instance vpn1
 ip address 10.1.1.254 255.255.255.0
 mac-address 0001-0002-0001
 local-proxy-arp enable
 dhcp select relay
 dhcp relay information enable
 dhcp relay server-address &lt;DHCP-SERVER-IP&gt; vpn-instance vpn1
 dhcp relay source-address interface LoopBack1
 distributed-gateway local
</code></pre>

<h4>Line-by-line explanation</h4>
<ul>
  <li><b>ip binding vpn-instance vpn1</b> — Places the SVI (IRB) into tenant VRF <code>vpn1</code>, so routing for this subnet uses the tenant table and the EVPN/VPNv4 policies you set earlier.</li>
  <li><b>ip address 10.1.0.254/24</b> on <code>Vsi-interface102</code> — L3 gateway for the subnet where the <em>DHCP server</em> resides (acts as the server VLAN’s default gateway).</li>
  <li><b>ip address 10.1.1.254/24</b> on <code>Vsi-interface103</code> — L3 gateway for the <em>client pool</em> subnet (matches the gateway configured in the DHCP server’s IP pool).</li>
  <li><b>mac-address 0001-xxxx-0001</b> — Sets a stable virtual MAC for the anycast gateway. For distributed gateway, keep the <em>same MAC per VLAN</em> across all participating leaves to ensure hosts ARP to the same gateway MAC.</li>
  <li><b>local-proxy-arp enable</b> — The leaf answers ARP locally to reduce L2 flooding across the EVPN fabric (useful in VXLAN overlays).</li>
  <li><b>dhcp select relay</b> (on 103) — Enables the SVI to work as a DHCP relay agent for the client subnet.</li>
  <li><b>dhcp relay information enable</b> — Inserts Option 82 (relay agent information) so the DHCP server can make per-interface/policy decisions.</li>
  <li><b>dhcp relay server-address &lt;DHCP-SERVER-IP&gt; vpn-instance vpn1</b> — Points the relay to the DHCP server’s IP and VRF (server reachable via <code>vpn1</code>).</li>
  <li><b>dhcp relay source-address interface LoopBack1</b> — Uses the loopback as source of the unicast DHCP relay packets; stable and routable across the underlay.</li>
  <li><b>distributed-gateway local</b> — Enables EVPN anycast gateway on this SVI so both leaves can serve as the default gateway using the same virtual MAC/IP.</li>
</ul>

<h3>VSI (EVPN/VXLAN) Settings</h3>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/irf vsi setting.png' | relative_url }}"
       alt="VSI EVPN/VXLAN settings"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>

<pre><code>vsi 102
 gateway vsi-interface 102
 vxlan 102
 evpn encapsulation vxlan
  route-distinguisher auto
  vpn-target auto export-extcommunity
  vpn-target auto import-extcommunity

vsi 103
 gateway vsi-interface 103
 vxlan 103
 evpn encapsulation vxlan
  route-distinguisher auto
  vpn-target auto export-extcommunity
  vpn-target auto import-extcommunity
</code></pre>

<ul>
  <li><b>vsi &lt;id&gt;</b> — Creates a Layer-2 EVPN instance for the VLAN/VNI (tenant segment).</li>
  <li><b>gateway vsi-interface &lt;id&gt;</b> — Binds the L3 SVI (IRB) to this VSI to form IRB (L2+L3) so the anycast gateway participates in EVPN (MAC/IP advertisement).</li>
  <li><b>vxlan &lt;VNI&gt;</b> — Maps the VSI to a VXLAN Network Identifier (e.g., 102 ↔ VNI 102). All leaves with the same VNI build the same broadcast domain.</li>
  <li><b>evpn encapsulation vxlan</b> — Uses EVPN as control-plane and VXLAN as data-plane for this VSI.</li>
  <li><b>route-distinguisher auto</b> — Auto-generates the EVI RD. Unique per VSI per device; not used for policy, only uniqueness.</li>
  <li><b>vpn-target auto import/export</b> — Auto-derives RTs for this EVI. As long as other leaves derive the same values (same VNI/EVI scheme), L2 EVPN routes are shared. (Your VRF <code>vpn1</code> RTs govern L3 routes; these <em>auto</em> RTs govern L2 EVPN.)</li>
</ul>

<p><em>Summary:</em> <code>Vsi-interface102</code> acts as the gateway in the server VLAN; <code>Vsi-interface103</code> is the client VLAN gateway and DHCP relay (server IP reachable via <code>vpn1</code>, relay sourced from <code>LoopBack1</code>). The <code>vsi 102/103</code> blocks bind IRB to VXLAN VNIs and enable EVPN control so MAC/IP reachability and anycast gateway are consistently advertised to peer leaves.</p>


