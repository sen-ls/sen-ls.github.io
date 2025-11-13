---
layout: post
title: "Storage Type Conclusion"
categories: [storage]
tags: [FC, iSCSi, NAS, Nvme]
---

<p>
  This blog post is part of my learning journey to understand different <strong>storage types</strong> –
  especially how they are used in a <strong>virtual computing platform</strong> as either
  <em>local storage</em> or <em>shared storage pools</em>.
  I start from the physical disk interfaces, move up to file systems and raw blocks, and finally cover
  shared storage protocols like FC, iSCSI, NAS and object storage. At the end, I briefly introduce
  distributed storage as a teaser for the next post.
</p>

<hr />

<h2>1. Physical Storage Interfaces and Types</h2>

<p>
  At the lowest layer, storage is connected to the host through different <strong>physical interfaces</strong>.
  These interfaces define how data moves between the disk and the server and how it is classified
  in a virtual computing platform.
</p>

<table>
  <thead>
    <tr>
      <th>Interface</th>
      <th>Type</th>
      <th>Description</th>
      <th>Classification in Virtual Computing Platform</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>SATA (Serial ATA)</strong></td>
      <td>Local Block</td>
      <td>Common interface for HDDs and consumer SSDs; moderate performance and latency.</td>
      <td>Local storage (directly attached disk on the host)</td>
    </tr>
    <tr>
      <td><strong>SAS (Serial Attached SCSI)</strong></td>
      <td>Local Block</td>
      <td>Enterprise-grade interface with better reliability and multi-channel support.</td>
      <td>Local storage (often used in servers and disk enclosures)</td>
    </tr>
    <tr>
      <td><strong>NVMe (Non-Volatile Memory Express)</strong></td>
      <td>Local Block</td>
      <td>Connects flash memory via PCIe; very high throughput and very low latency.</td>
      <td>Local storage (NVMe disk / PCIe SSD)</td>
    </tr>
    <tr>
      <td><strong>NVMe-oF (NVMe over Fabrics)</strong></td>
      <td>Network Block</td>
      <td>Extends NVMe protocol over network transports (RoCE, TCP, FC).</td>
      <td>Shared storage (next-generation SAN)</td>
    </tr>
    <tr>
      <td><strong>FC (Fibre Channel)</strong></td>
      <td>Network Block</td>
      <td>Dedicated SAN fabric using the Fibre Channel protocol; very low latency and jitter.</td>
      <td>Shared storage pool (FC SAN)</td>
    </tr>
    <tr>
      <td><strong>iSCSI (Internet SCSI)</strong></td>
      <td>Network Block</td>
      <td>Encapsulates SCSI commands in TCP/IP; runs on standard Ethernet.</td>
      <td>Shared storage pool (IP SAN)</td>
    </tr>
    <tr>
      <td><strong>NAS (NFS / SMB)</strong></td>
      <td>Network File</td>
      <td>File-level access over Ethernet using NFS or SMB/CIFS protocols.</td>
      <td>Shared file storage (shared directory, template library, ISO repository)</td>
    </tr>
    <tr>
      <td><strong>Object Storage (S3, Swift, etc.)</strong></td>
      <td>Object-based</td>
      <td>HTTP/REST-based interface to store objects with metadata and IDs.</td>
      <td>Cloud/object storage (backup, archive, large unstructured data)</td>
    </tr>
  </tbody>
</table>

<hr />

<h2>2. File System Formats at the OS Layer</h2>

<p>
  Once a disk is visible to the operating system as a <strong>block device</strong>, it usually needs
  to be formatted with a <strong>file system</strong>. Different operating systems support different
  file system formats, each with its own features and typical use cases.
</p>

<table>
  <thead>
    <tr>
      <th>File System</th>
      <th>Platform</th>
      <th>Characteristics</th>
      <th>Common Use</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>NTFS</strong></td>
      <td>Windows</td>
      <td>Journaling, ACL permissions, compression, encryption, good stability.</td>
      <td>Default file system for Windows OS and Hyper-V virtual disks.</td>
    </tr>
    <tr>
      <td><strong>ext4</strong></td>
      <td>Linux</td>
      <td>Journaling, solid performance, very widely adopted and mature.</td>
      <td>Linux root file systems, data partitions, hypervisor data stores.</td>
    </tr>
    <tr>
      <td><strong>XFS</strong></td>
      <td>Linux</td>
      <td>Highly scalable, good for parallel I/O and very large files.</td>
      <td>Databases, large file workloads, virtualization platforms.</td>
    </tr>
    <tr>
      <td><strong>FAT32 / exFAT</strong></td>
      <td>Cross-platform</td>
      <td>Lightweight, but limited features (no journaling, file size limits for FAT32).</td>
      <td>USB sticks, portable drives, small removable media.</td>
    </tr>
    <tr>
      <td><strong>ZFS / Btrfs</strong></td>
      <td>Unix / Linux</td>
      <td>Advanced features like snapshots, checksums, replication, and integrated volume management.</td>
      <td>NAS appliances, advanced storage servers, and some distributed storage setups.</td>
    </tr>
  </tbody>
</table>

<hr />

<h2>3. From Raw Disk to File System</h2>

<p>
  Before formatting, a disk appears as a <strong>raw block device</strong>. Internally, this device is
  divided into <strong>fixed-size blocks</strong>, typically <code>512 bytes</code> or <code>4 KB</code> per block.
  The operating system reads and writes data in terms of these blocks.
</p>

<p>
  When we <strong>format</strong> a disk with a file system such as NTFS or ext4, the OS builds a logical
  structure on top of these blocks:
</p>

<ul>
  <li>It organizes blocks into <strong>files</strong> and <strong>directories</strong>.</li>
  <li>It maintains <strong>metadata</strong> like permissions, ownership, and timestamps.</li>
  <li>It handles <strong>allocation</strong> and <strong>free space</strong> management.</li>
</ul>

<p>
  After formatting, applications no longer deal with raw blocks directly. Instead, they work with files,
  while the OS and the file system translate file operations into block reads and writes.
</p>

<hr />

<h2>4. Local Disks in a Virtual Computing Platform</h2>

<p>
  The concepts above mainly apply to <strong>local disks</strong> inside a physical server.
  In a typical server used by a virtual computing platform:
</p>

<ul>
  <li>You might have pre-installed <strong>SATA</strong>, <strong>SAS</strong>, or <strong>NVMe</strong> drives.</li>
  <li>You can use an entire physical disk as a <strong>local storage pool</strong>, or partition it into multiple logical volumes/datastores.</li>
  <li>These local pools can host VM disks, ISO images, and templates on a single host.</li>
</ul>

<p>
  Data transfer between CPU and these local disks happens over the local storage bus:
</p>

<ul>
  <li><strong>SATA / SAS</strong>: traditional storage interfaces, good but with higher latency and lower throughput compared to NVMe.</li>
  <li><strong>NVMe over PCIe</strong>: extremely fast I/O, very low latency and high IOPS.</li>
</ul>

<p>
  In general, <strong>the speed and latency are strongly influenced by the physical interface</strong>
  (e.g., PCIe vs. SATA), by the disk type (SSD vs. HDD), and by queue depth and controller design.
</p>

<p>
  Local storage is great for:
</p>
<ul>
  <li>Standalone hosts.</li>
  <li>Test environments.</li>
  <li>Non-critical workloads where high availability and live migration are not strictly required.</li>
</ul>

<hr />

<h2>5. Shared Storage Pools in Computing Systems</h2>

<p>
  To support features like <strong>VM migration</strong>, <strong>high availability (HA)</strong>,
  and <strong>clustered management</strong>, multiple hosts need access to the same underlying storage.
  This is where <strong>shared storage pools</strong> come into play.
</p>

<p>
  Common shared storage technologies in virtual computing platforms include:
</p>

<ul>
  <li><strong>FC (Fibre Channel)</strong> – block-level storage over a dedicated FC SAN.</li>
  <li><strong>iSCSI</strong> – block-level storage over IP (Ethernet) networks.</li>
  <li><strong>NAS (NFS, SMB/CIFS)</strong> – file-level shared storage over Ethernet.</li>
  <li><strong>Object Storage</strong> – HTTP/REST-based storage, often used for backup and archive.</li>
</ul>

<table>
  <thead>
    <tr>
      <th>Storage Type</th>
      <th>Protocol</th>
      <th>Layer</th>
      <th>Example</th>
      <th>Typical Usage</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>FC SAN</td>
      <td>Fibre Channel</td>
      <td>L2 (FC fabric)</td>
      <td>FC switches + FC HBAs</td>
      <td>High-performance shared block storage.</td>
    </tr>
    <tr>
      <td>FCoE</td>
      <td>FC over Ethernet</td>
      <td>L2 (Ethernet)</td>
      <td>Data center Ethernet with DCB</td>
      <td>Unified fabric for LAN + SAN.</td>
    </tr>
    <tr>
      <td>iSCSI</td>
      <td>SCSI over TCP/IP</td>
      <td>L3 (IP)</td>
      <td>IP SAN using Ethernet switches</td>
      <td>Common shared storage for hypervisors.</td>
    </tr>
    <tr>
      <td>NAS</td>
      <td>NFS, SMB/CIFS</td>
      <td>L3 (IP)</td>
      <td>NFS server, Windows file server</td>
      <td>Shared file storage, ISO/template library.</td>
    </tr>
    <tr>
      <td>Object Storage</td>
      <td>HTTP/REST</td>
      <td>L7 (Application)</td>
      <td>S3, Swift, MinIO</td>
      <td>Backup, archive, large-scale object data.</td>
    </tr>
  </tbody>
</table>

<p>
  Most of these technologies run over <strong>Layer 2 (Ethernet or FC)</strong> or <strong>Layer 3 (IP)</strong>
  and integrate into the virtual computing platform as shared datastores or storage pools.
</p>

<hr />

<h2>6. FC vs. iSCSI – A Closer Comparison</h2>

<p>
  Among the shared storage options, <strong>FC</strong> and <strong>iSCSI</strong> are the two most common
  block-level solutions in datacenter virtualization. The following table compares them from protocol type
  down to typical use cases:
</p>

<table>
  <thead>
    <tr>
      <th>Category</th>
      <th>FC (Fibre Channel)</th>
      <th>iSCSI (Internet SCSI)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Protocol Type</td>
      <td>Dedicated SAN protocol for block storage.</td>
      <td>SCSI commands encapsulated in TCP/IP.</td>
    </tr>
    <tr>
      <td>Transport Medium</td>
      <td>Optical fiber or copper through FC switches.</td>
      <td>Standard Ethernet (1G, 10G, 25G, 40G+).</td>
    </tr>
    <tr>
      <td>Hardware</td>
      <td>FC HBAs and FC switches.</td>
      <td>Standard NICs or dedicated iSCSI HBAs.</td>
    </tr>
    <tr>
      <td>Network Separation</td>
      <td>Usually a fully dedicated SAN fabric.</td>
      <td>Can share existing LAN or use a dedicated VLAN/fabric.</td>
    </tr>
    <tr>
      <td>Performance</td>
      <td>Very low latency and jitter; predictable performance.</td>
      <td>Depends on Ethernet network quality and congestion.</td>
    </tr>
    <tr>
      <td>CPU Overhead</td>
      <td>Low (often offloaded to FC hardware).</td>
      <td>Higher (TCP/IP stack handled by CPU unless offloaded).</td>
    </tr>
    <tr>
      <td>Deployment Cost</td>
      <td>Higher – requires dedicated FC infrastructure.</td>
      <td>Lower – can reuse existing Ethernet infrastructure.</td>
    </tr>
    <tr>
      <td>Management</td>
      <td>Requires zoning, WWPN management and FC expertise.</td>
      <td>IP-based configuration, simpler for many admins.</td>
    </tr>
    <tr>
      <td>Typical Use Cases</td>
      <td>Enterprise SAN, mission-critical databases, core VM storage.</td>
      <td>Virtualization clusters, general-purpose shared storage, lab and test systems.</td>
    </tr>
    <tr>
      <td>Integration in Virtual Platforms</td>
      <td>FC storage pools and FC-based shared datastores.</td>
      <td>iSCSI storage pools and iSCSI-based shared datastores.</td>
    </tr>
  </tbody>
</table>

<hr />

<h2>7. Matching Storage Types to Use Cases</h2>

<p>
  Different storage technologies are usually chosen for different purposes. A rough guideline:
</p>

<table>
  <thead>
    <tr>
      <th>Storage Type</th>
      <th>Typical Usage</th>
      <th>Notes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Local NVMe / SAS / SATA</td>
      <td>Single-host VM storage, lab environments, cache tiers.</td>
      <td>Very fast and low latency, but limited to one host.</td>
    </tr>
    <tr>
      <td>FC / iSCSI (Block)</td>
      <td>High-performance shared VM disks, databases, transactional systems.</td>
      <td>Best choice when you need shared block storage with HA and live migration.</td>
    </tr>
    <tr>
      <td>NAS (NFS / SMB)</td>
      <td>Shared file libraries, templates, ISO images, backup repositories.</td>
      <td>Easy to manage and very flexible, but not ideal for the most I/O-intensive workloads.</td>
    </tr>
    <tr>
      <td>Object Storage</td>
      <td>Long-term backup, archive, cloud-native applications.</td>
      <td>Accessed via API; not a direct replacement for block storage.</td>
    </tr>
    <tr>
      <td>Distributed Storage (RBD, ONEStor, etc.)</td>
      <td>Software-defined shared storage across multiple nodes.</td>
      <td>Provides block, file, or object interfaces; supports scaling and self-healing.</td>
    </tr>
  </tbody>
</table>

<hr />

<h2>8. A Short Glimpse into Distributed Storage</h2>

<p>
  <strong>Distributed storage</strong> systems such as Ceph or vendor-specific solutions
  (for example, ONEStor or hyperconverged platforms) combine disks from many nodes into a single,
  unified storage pool. Key ideas include:
</p>

<ul>
  <li><strong>Data replication or erasure coding</strong> to tolerate disk or node failures.</li>
  <li><strong>Horizontal scaling</strong> – add more nodes to increase capacity and performance.</li>
  <li><strong>Self-healing</strong> – the system automatically rebalances and repairs data after failures.</li>
  <li><strong>Multiple interfaces</strong> – the same cluster can offer block, file, and object access.</li>
</ul>

<p>
  For a virtual computing platform, distributed storage can act as the underlying engine for
  shared storage pools, while still being completely software-defined and independent of traditional
  external SAN arrays.
</p>

<p>
  I will introduce the architecture and I/O flow of distributed storage in more detail in the
  <strong>next blog post</strong>, including concepts like placement groups, monitors, OSDs,
  and how these pieces cooperate with hypervisors.
</p>

<hr />

<p>
  To summarize, understanding the different storage types – from local SATA/NVMe disks to FC/iSCSI SANs,
  NAS shares, object storage, and distributed systems – is essential for designing an efficient and
  reliable virtual infrastructure. The right storage choice always depends on performance requirements,
  availability targets, and operational complexity.
</p>

