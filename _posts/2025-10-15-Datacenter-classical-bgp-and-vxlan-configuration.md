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
  In this blog, the <strong>HCL simulation tool from H3C</strong> is used to realize the configuration and testing.
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

<h3>IRF leaf — BGP configuration</h3>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/irf bgp con.png' | relative_url }}"
       alt="IRF leaf BGP configuration"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>

<pre><code>bgp 64000
 router-id 172.17.3.141
 peer 172.17.2.194 as-number 65000
 peer 172.17.2.194 ebgp-max-hop 255
 peer 172.17.3.42 as-number 64000
 peer 172.17.3.42 connect-interface LoopBack0
 #
 address-family ipv4 unicast
  network 172.17.3.141 255.255.255.255
  peer 172.17.2.194 enable
  peer 172.17.2.194 allow-as-loop 1
 #
 address-family l2vpn evpn
  peer 172.17.3.42 enable
</code></pre>

<h4>Line-by-line explanation</h4>
<ul>
  <li><b>bgp 64000</b> — Local AS is <code>64000</code> on the IRF leaf.</li>

  <li><b>router-id 172.17.3.141</b> — Sets a stable BGP Router-ID (usually a loopback /32). Also advertised by the
      <code>network 172.17.3.141/32</code> statement below so it’s reachable in the underlay.</li>

  <li><b>peer 172.17.2.194 as-number 65000</b> — Defines an eBGP neighbor (e.g., the spine or a remote leaf/ToR) with
      remote AS <code>65000</code>.</li>

  <li><b>peer 172.17.2.194 ebgp-max-hop 255</b> — Allows multi-hop eBGP (not just directly connected). Useful when
      peering via loopbacks or when there are intermediate L3 hops in the underlay.</li>

  <li><b>peer 172.17.3.42 as-number 64000</b> — iBGP neighbor (same AS 64000). Typically this is the EVPN iBGP peer
      (another loopback on the remote leaf).</li>

  <li><b>peer 172.17.3.42 connect-interface LoopBack0</b> — Source EVPN/iBGP sessions from <code>LoopBack0</code> to
      build stable control-plane sessions decoupled from physical links.</li>

  <li><b>address-family ipv4 unicast</b> — Underlay reachability (VPN-less IPv4). Carries loopbacks and
      transit subnets used to form BGP sessions and next-hops.</li>

  <li><b>network 172.17.3.141 255.255.255.255</b> — Advertises the loopback /32 (router-id) into the underlay so it can
      be used for multi-hop peering and as a stable next-hop.</li>

  <li><b>peer 172.17.2.194 enable</b> — Activates the eBGP neighbor for IPv4 unicast AFI/SAFI.</li>

  <li style="border:1px solid #f66; padding:.4em; border-radius:.4em;"><b>peer 172.17.2.194 allow-as-loop 1</b> — 
      <em>Key knob for single-AS designs.</em> It lets this BGP speaker accept routes that contain its own AS in the 
      <code>AS_PATH</code> (up to 1 occurrence). In practice this enables you to keep a “one-AS” fabric and still bring up
      underlay reachability with the opposite leaf via eBGP-like behavior—without having to introduce an extra
      remote-AS just for the underlay. If both sides share the same AS, normal eBGP would drop updates when it sees its
      own AS in the path; <code>allow-as-loop 1</code> relaxes that and allows the session/routes to work.</li>

  <li><b>address-family l2vpn evpn</b> — EVPN control-plane for the VXLAN overlay.</li>

  <li><b>peer 172.17.3.42 enable</b> — Enables the iBGP EVPN session (typically loopback-to-loopback) which carries
      MAC/IP (Type-2), IRB routes (Type-5) etc. between leaves.</li>
</ul>

<p><em>Result:</em> With this setup the underlay can be established to the spine/peer, and the EVPN overlay runs over
stable loopbacks. The <code>allow-as-loop 1</code> line is the trick that lets you maintain a single AS across the fabric
while still exchanging underlay routes with the opposite leaf.</p>


<h4><strong>Second Step</strong>:Spine Configuration</h4>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/spine bgp.png' | relative_url }}"
       alt="Spine BGP configuration"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>

<pre><code>bgp 65000
 router-id 172.17.2.194
 peer 172.17.3.141 as-number 64000
 peer 172.17.3.141 ebgp-max-hop 255
 peer 172.17.3.42 as-number 64000
 peer 172.17.3.42 connect-interface LoopBack0
 #
 address-family ipv4 unicast
  network 172.17.2.194 255.255.255.255
  peer 172.17.3.141 enable
  peer 172.17.3.141 allow-as-loop 1
 #
 address-family l2vpn evpn
  peer 172.17.3.42 enable
</code></pre>

<h5>Line-by-line explanation</h5>
<ul>
  <li><b>bgp 65000</b> — Starts the BGP process on the Spine with AS number <code>65000</code>. The spine typically uses a different AS from the leaves (<code>64000</code>) to form eBGP sessions for underlay reachability.</li>

  <li><b>router-id 172.17.2.194</b> — Sets the unique BGP Router-ID, usually the loopback IP of the Spine. This provides a stable identifier independent of any physical interface status.</li>

  <li><b>peer 172.17.3.141 as-number 64000</b> — Defines an eBGP neighbor, the IRF leaf device (AS <code>64000</code>), to exchange underlay routes.</li>

  <li><b>peer 172.17.3.141 ebgp-max-hop 255</b> — Extends eBGP reachability beyond directly connected links. Required when the eBGP session is established through loopbacks or routed intermediate hops.</li>

  <li><b>peer 172.17.3.42 as-number 64000</b> — Declares another peer with AS <code>64000</code> for iBGP EVPN peering. This is typically a loopback-to-loopback session with another leaf in the same AS domain.</li>

  <li><b>peer 172.17.3.42 connect-interface LoopBack0</b> — Uses <code>LoopBack0</code> as the source interface for iBGP sessions. This ensures stable and redundant control-plane connectivity, decoupled from physical link failures.</li>

  <li><b>address-family ipv4 unicast</b> — Activates the IPv4 underlay routing table within BGP, used for loopback and transit subnet advertisement.</li>

  <li><b>network 172.17.2.194 255.255.255.255</b> — Advertises the Spine’s loopback /32 into BGP so other devices (like Leafs) can reach it for multi-hop peering and route reflection.</li>

  <li><b>peer 172.17.3.141 enable</b> — Enables the IPv4 unicast neighbor session with the IRF leaf for underlay route exchange.</li>

  <li style="border:1px solid #f66; padding:.4em; border-radius:.4em;"><b>peer 172.17.3.141 allow-as-loop 1</b> — 
      <em>Crucial parameter for unified AS design.</em> It allows the Spine to accept routes that contain its own AS number once in the <code>AS_PATH</code>. This enables underlay communication with Leafs that share the same AS (e.g., <code>64000</code>) without BGP rejecting those routes as loops. The result is a clean single-AS fabric that behaves like eBGP between layers, without assigning unique ASNs to every device.</li>

  <li><b>address-family l2vpn evpn</b> — Enables the EVPN control-plane, which carries MAC/IP and tenant information for VXLAN overlays.</li>

  <li><b>peer 172.17.3.42 enable</b> — Activates the EVPN iBGP session with the remote leaf. The Spine acts as a   <li style="border:1px solid #f66; padding:.4em; border-radius:.4em;"> <b>Route Reflector</b>, redistributing EVPN routes (Type-2 for MAC/IP, Type-5 for IRB) across the fabric.</li>
</li> </ul>

<p><em>Result:</em> This configuration allows the Spine (AS 65000) to form eBGP underlay sessions with Leafs (AS 64000) while maintaining a unified single-AS architecture through <code>allow-as-loop 1</code>. It also establishes iBGP EVPN sessions over loopbacks for overlay control-plane distribution, enabling VXLAN EVPN operation with stable multi-hop BGP connectivity.</p>

<h4><strong>Third Step</strong>: Leaf2 Configuration</h4>

<p align="center">
  <img src="{{ '/assets/images/2025-10-15/leaf2 bgp con.png' | relative_url }}"
       alt="Leaf2 BGP configuration"
       style="max-width: 780px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
</p>

<pre><code>bgp 64000
 router-id 172.17.3.200
 peer 20.1.1.1 as-number 65000
 peer 20.1.1.1 ebgp-max-hop 255
 peer 172.17.3.42 as-number 64000
 peer 172.17.3.42 connect-interface LoopBack0
 #
 address-family ipv4 unicast
  network 172.17.3.200 255.255.255.255
  peer 20.1.1.1 enable
  peer 20.1.1.1 allow-as-loop 1
 #
 address-family l2vpn evpn
  peer 172.17.3.42 enable
 #
 ip vpn-instance vpn1
  #
  address-family ipv4 unicast
   network 172.17.254.43 255.255.255.255
#
return
</code></pre>

<p>The overall configuration of <b>Leaf2</b> is very similar to <b>Leaf1</b>, sharing the same AS number (<code>64000</code>) and the same BGP peering structure. The key difference lies in the part where the configuration binds an <code>ip vpn-instance</code> to BGP.</p>

<h4>Explanation of <code>ip vpn-instance vpn1</code></h4>

<ul>
  <li><b>ip vpn-instance vpn1</b> — Creates a VPN instance (VRF) named <code>vpn1</code>. This defines a separate routing table for tenant traffic and is essential in EVPN-VXLAN deployments for multi-tenancy isolation.</li>

  <li><b>address-family ipv4 unicast</b> — Enters the IPv4 unicast address family within this VRF. It allows BGP to advertise and learn routes belonging to this specific VPN instance instead of the global routing table.</li>

  <li><b>network 172.17.254.43 255.255.255.255</b> — Advertises a route belonging to the tenant’s Layer-3 gateway or SVI (typically a <code>Vlan-interface</code> or <code>VBDIF</code> interface) inside <code>vpn1</code>.  
  This ensures that tenant traffic can be properly routed between Leaf switches via the EVPN control plane, with each Leaf advertising its own VRF routes to the others.</li>
</ul>

<p><em>In summary:</em> this section enables tenant-specific routing by binding user subnets to the VPN instance <code>vpn1</code>. These routes are then distributed through EVPN Type-5 (IP Prefix) routes across the overlay network, achieving full Layer-3 connectivity between tenants over VXLAN.</p>

---

<h4><strong>Last Step</strong>: Validation</h4>

<p>The detailed interface-level configuration is not shown here, as it mainly follows standard VLAN, VBDIF, and NVE binding steps already covered in previous sections.</p>

<p>To verify the complete setup, ensure the following:</p>

<ol>
  <li><b>DHCP validation:</b> Both Leaf1 and Leaf2 clients should successfully obtain IP addresses from their respective VLANs, proving that the DHCP relay and underlay routes are functioning correctly.</li>

  <li><b>VXLAN tunnel establishment:</b> Verify that the VXLAN tunnels are successfully established between the two Leafs (you can check this via <code>display vxlan tunnel brief</code>), confirming that the overlay control plane (EVPN) is active.</li>

  <li><b>BGP reachability:</b> Confirm that eBGP sessions (underlay) and iBGP sessions (overlay) are both established — eBGP for the routed underlay between Spine and Leafs, and iBGP for EVPN route exchange between Leafs via the Spine route reflector.</li>
</ol>

<p><em>Design note:</em> In traditional datacenter deployments, it’s common to assign each Leaf two different AS numbers — one for eBGP (underlay) and another for iBGP (overlay). However, this approach becomes difficult to manage as the network scales.  
In this configuration, a simplified model is used: all Leafs share the same AS (<code>64000</code>), while Spines use a distinct AS (<code>65xxx</code>). The <code>allow-as-loop</code> mechanism allows eBGP sessions to work even with shared AS numbers, greatly simplifying operations and making the AS scheme more intuitive and maintainable.</p>
