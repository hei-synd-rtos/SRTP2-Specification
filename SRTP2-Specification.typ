#import "@preview/hei-synd-report:0.2.0": *

#let doc = (
  title: "Specification of SRTP2",
  abbr: "SRTP2",
  url: "https://synd.hevs.io",
  logos: (
    tp_topleft: image("Assets/hesso-pictos.svg", height: 2cm),
    tp_topright: image("Assets/Infotronics-Logo.svg", height: 2cm),
    tp_main: [
      #image("Assets/SRTP2-Mascot.png", height: 6cm)
      #set align(center)
      *_Abstract_*

      The Simple Real-time Protocol, Version 2 (SRTP2) is a master-slave real-time data exchange protocol built on top of Ethernet. Designed specifically for educational
      environments, the protocol's functionality is deliberately minimized to ensure it remains easy for students to understand and implement. SRTP2 supports high-priority
      cyclic broadcast traffic, event-based broadcast traffic, and low-priority message-based unicast traffic. By leveraging modern Ethernet switch capabilities, such as
      store-and-forward queuing, SRTP2 achieves significantly higher bandwidth and drastically shorter cycle times compared to its predecessor, all while maintaining
      strict deterministic real-time performance.
    ],
    header: pad(top: 0.4cm, image("Assets/Infotronics-Icon-BW-Outline.svg", width: 1cm)),
  ),
  authors: ((name: "Michael Clausen", abbr: "ClM", email: "michael.clausen@hevs.ch"),),
  school: (
    name: "HES-SO Valais//Wallis",
    url: "https://hevs.ch",
    major: "Systems Engineering",
    major_url: "https://synd.hevs.io",
    orientation: "Infotronics",
    orientation_url: "https://synd.hevs.io/education/infotronics.html",
  ),
  keywords: ("Ethernet", "Template", "Report", "HEI-Vs", "Systems Engineering", "Infotronics"),
  version: "v2.1",
)

#show: report.with(
  option: (type: sys.inputs.at("type", default: "final"), lang: sys.inputs.at("lang", default: "en")),
  doc: doc,
  date: datetime.today(),
  tableof: (toc: false, tof: false, tot: false, tol: false, toe: false, maxdepth: 3),
)

= SRTP2 Introduction/Concepts

== Sampled Values

*Time-Synchronized Distributed Sampling*

The *Sampled Values* (SV) mechanism enables *synchronized data acquisition* across multiple nodes within an SRTP2 network. It guarantees that all participating nodes have
sufficient time to transmit their measured values within a single SRTP2 cycle while maintaining *strict temporal synchronization*.

An SRTP2 network supports up to *`32`* *independent SV streams* per Controller Node. These streams are dynamically managed on a per-cycle basis by the Master Node. To achieve
network-wide synchronization, the *Master Node* broadcasts a *Beacon* frame. Upon exact reception of this *Beacon*, each *Controller Node* must immediately sample its designated
inputs and update its corresponding outputs.

To control data flow, the *Master Node* embeds an *SV Group Mask* field within the *Beacon* frame, dictating exactly which SV groups must be acquired at that specific moment. Once
acquired, the resulting sampled data must be *buffered* and appended to the response frame sent by the *Controller Node* in the *subsequent cycle*, rather than the current cycle's
response. Because these responses are broadcast to the network, the synchronized measurements become readily available to any node configured to consume them.

== Events

*High-Priority Events*

During any given SRTP2 cycle, a *Controller Node* may transmit a *dynamic number* of *timestamped events*. The maximum number of events transmitted in a single cycle is limited
only by the *remaining payload capacity* of the node's outgoing Ethernet frame. Each event may carry an associated *data payload*, and the protocol supports an identifier space
of up to *`65,535`* distinct event types. These events are embedded directly into the node's standard response following a Beacon and are subsequently broadcast to all other
nodes on the network.

== Messages

*Low-Priority Unicast Messages*

The SRTP2 protocol supports *low-priority unicast* messaging to facilitate *point-to-point communication* between *Controller Nodes*. Unlike time-critical cyclic traffic, these
unicast messages support *payloads of arbitrary length*. To accommodate large payloads that exceed the capacity of a single transmission, the protocol allows a single message to
span *multiple response frames*. The transmitting node automatically fragments the message into smaller embedded Protocol Data Units (PDUs) across consecutive cycles, which are
then seamlessly reassembled by the receiving node upon delivery.

#pagebreak()

== Implicit registration

SRTP2 employs an *implicit registration and discovery mechanism*, eliminating the need for explicit network join or handshake messages. A *Controller Node* is automatically
registered as active on the network the moment it successfully transmits its first *response to a Beacon frame*. Conversely, the protocol infers node liveness through these same
responses. If a registered node fails to respond to *multiple consecutive Beacon frames*, it shall be *implicitly deregistered* and considered offline.

== Producer/Consumer model

SRTP2 utilizes a *Producer/Consumer* data distribution architecture operating over a *broadcast* topology. Every frame transmitted on the network is delivered to all connected
nodes. Consequently, each Controller Node receives the *complete stream of network traffic* and is responsible for independently inspecting the incoming frames. The node applies
local filters to extract and consume only the specific data or events relevant to its configured operational requirements, silently discarding the rest.

#pagebreak()

= SRTP2 Topology

An SRTP2 network consists of the following node types:

- A unique network supervisor called the *Master Node (MN)*
- Multiple synchronized I/O nodes called *Controller Nodes (CN)*

#figure(image("Assets/SRTP2-Topology.svg", width: 80%), caption: [SRTP2 Topology.]) <srtp2-topology>

An SRTP2 network is built upon a strict *star topology* centered around an *Ethernet Switch*. The architecture consists of exactly *one network supervisor*, designated as the
*Master Node* (MN), and one or more *distributed I/O nodes*, designated as *Controller Nodes* (CN). The *Master Node* acts as the *central authority*, coordinating all network
traffic and providing precise *time synchronization* for the local clocks of all connected *Controller Nodes*

To guarantee *deterministic real-time operation*, the network must be *isolated*, meaning *only SRTP2-compliant nodes should be connected to the central switch*. Furthermore,
the protocol fundamentally relies on the *store-and-forward mechanism* of modern Ethernet switches to buffer simultaneous transmissions and eliminate collision domains.
Consequently, the use of legacy Ethernet Hubs is strictly prohibited. Network designers must also ensure the chosen switch possesses *adequate buffer capacity*; utilizing hardware
with insufficient memory will result in *frame collisions* and * frame drops*, severely degrading system latency and *rendering the real-time capabilities unusable*.

#pagebreak()

= SRTP2 Mechanisms

A *Controller Node* (CN) may host one or more independent *applications* operating on top of the SRTP2 stack. Within this architecture, each application can concurrently *publish*
or *subscribe* to multiple *Sampled Values streams*, produce or consume *High-Priority Events*, and provide or utilize *Low-Priority Message* services. This multi-layered
architecture is illustrated in @srtp2-layers:

#figure(image("Assets/SRTP2-Layers.svg", width: 90%), caption: [SRTP2 Layers.]) <srtp2-layers>

Through this standardized stack, a single application can simultaneously utilize three distinct communication mechanisms:

- *Sampled Values* (Cyclic): #linebreak()
  Used by the application to publish continuous physical I/O readings or subscribe to control variables with hard real-time synchronization.

- *Events* (Asynchronous):#linebreak()
  Used to immediately broadcast or listen for state changes, triggers, or system faults across the network.

- *Messages* (Background): #linebreak()
  Used to expose or consume point-to-point services, allowing the transfer of larger, non-time-critical data blocks such as configuration files or diagnostic data.

The stack manages the complex task of multiplexing these streams, ensuring that real-time data is prioritized while background messages are safely fragmented.

#pagebreak()

== Sampled Values

=== Time synchronization and synchronous I/O

#figure(image("Assets/SRTP2-Timesync.svg", width: 80%), caption: [Synchronization]) <srtp2-synchronization>

Applications can register with the SRTP2 stack to receive a *low-latency notification* the exact moment a *Beacon* frame is received. This precise hardware/software trigger
enables the entire distributed system to sample inputs and update outputs *simultaneously across all nodes*. Furthermore, because the *Master Node* embeds the global *network
timestamp* within the *Beacon* payload, individual *Controller Nodes* can optionally extract this data to *synchronize their local clocks*, ensuring a unified timebase across the
whole network. This timing relationship is illustrated in @srtp2-synchronization.

#pagebreak()

=== Sampled Values Publisher

#figure(image("Assets/SRTP2-svPublish.svg", width: 80%), caption: [SV Publish]) <srtp2-sv-publish>

To initiate a Sampled Values stream, an application must submit a *Sampled Values Register Request* `svRegisterRequest()` to the underlying SRTP2 stack. The protocol enforces
strict mutual exclusion for publishing rights: only a single application may publish to a specific *SV Group* at any given time on the same node. Consequently, if an application
attempts to register for an *SV Group* that is already claimed by another process, the stack must reject the service call.

Upon receiving a *Beacon* frame, the SRTP2 stack triggers an `svPublishIndication()` to notify all successfully registered SV publishers. In response to this indication, the
application must immediately hand over its data payload—specifically, the physical values read during the preceding cycle's `svSyncIndication()`. The stack then embeds this data
into the outgoing Sampled Values stream for network transmission.

#pagebreak()

=== Sampled Values Subscriber

#figure(image("Assets/SRTP2-SVSubscribe.svg", width: 80%), caption: [SV Subscribe]) <srtp2-sv-subscribe>

An application may concurrently subscribe to multiple *Sampled Values streams*. Subscriptions are logically bound to the *SV Group* identifier rather than to a specific
Controller Node's hardware or network address. Consequently, if multiple Controller Nodes publish data to the identical *SV Group*, the subscribing application will receive the
*combined traffic from all publishers within that group*. The receiving application is therefore responsible for inspecting the incoming payloads and performing local filtering
to extract only the data relevant to its specific operation.

#pagebreak()

== Events

=== Event Publisher

#figure(image("Assets/SRTP2-EVPublish.svg", width: 80%), caption: [EV Publish]) <srtp2-ev-publish>

An application may asynchronously dispatch an event at any arbitrary time by invoking the `evPublishRequest()` service primitive. The SRTP2 protocol handles event transmission
strictly on a "fire-and-forget" basis. Consequently, the dispatch operation is entirely *unacknowledged*; the underlying stack neither requests nor provides any delivery
confirmation or receipt from the receiving nodes.

#pagebreak()

=== Event Subscriber

#figure(image("Assets/SRTP2-EVSubscribe.svg", width: 80%), caption: [EV Subscribe]) <srtp2-ev-subscribe>

An application may concurrently subscribe to multiple *Event* IDs. These subscriptions are logically bound exclusively to the Event ID and are completely agnostic to the
originating Controller Node's network address. Consequently, if multiple nodes broadcast events utilizing the identical Event ID, the subscribing application will receive the
combined event traffic from all sources. It is therefore the responsibility of the receiving application to perform local filtering—specifically by inspecting the source
Ethernet (MAC) address of the incoming frames—to identify the origin and isolate the events relevant to its specific operational context.

#pagebreak()

== Messages

=== Unicast Message Publisher

#figure(image("Assets/SRTP2-MsgPublish.svg", width: 80%), caption: [Msg Publish]) <srtp2-msg-publish>

An application may asynchronously initiate a message transfer at any time using the `msgDataRequest()` service primitive. If the message payload exceeds the available frame
capacity, the SRTP2 stack will automatically fragment the data, and transmission may span across several consecutive network cycles.

Crucially, the SRTP2 message API provides strictly *best-effort delivery*. The protocol implements no internal control mechanisms to verify that individual fragments or the
complete message have been successfully received by the destination node. Any required reliability mechanisms—such as delivery acknowledgments, sequence verification, or
retransmissions—must be implemented by the application layer operating on top of SRTP2. However, the local SRTP2 stack is required to notify the sending application as soon as
the final fragment of the message has been successfully transmitted onto the network.

=== Unicast Message Receiver

#figure(image("Assets/SRTP2-MsgReception.svg", width: 80%), caption: [Msg Reception]) <srtp2-msg-reception>

An application may register as a listener to receive *incoming messages* directed to a specific *Service Access Point Identifier* (SAPI). The SRTP2 stack enforces strict mutual
exclusion for message reception; therefore, only *a single application* may bind to a given *SAPI* at any one time. Upon the successful reception and automatic reassembly of a
complete message, the underlying stack must deliver the payload to the registered application by invoking the `msgDataIndication()` callback.

#pagebreak()

= SRTP2 Protocol

== The SRTP2 Communication Cycle

The *Master Node* periodically transmits a *Beacon* frame to establish the *network cycle* and strictly *synchronize all I/O operations* and local clocks. Upon reception of this
*Beacon*, each *Controller Node* (CN) is permitted to transmit exactly *one response*, formatted as a *Multi-PDU* (MPDU) frame.

Because all Controller Nodes receive the *Beacon* and trigger their responses nearly simultaneously, a *massive burst of concurrent network traffic is generated*. While this would
cause catastrophic collisions on legacy _CSMA/CD_ networks, *SRTP2* relies on the *store-and-forward* architecture of *modern Ethernet switches* to buffer and serialize these
simultaneous *MPDU* transmissions. Consequently, the frames are *queued and delivered to destination ports sequentially*. It is critical for developers to understand that the
arrival sequence of these *MPDU* frames is inherently *non-deterministic*; the order is completely undefined and will likely vary from one cycle to the next.

Furthermore, all *SRTP2* frames are transmitted as network-wide *broadcasts*. Because they are broadcast, frame delivery *cannot be acknowledged* at the link layer. Every node
receives the complete stream of network traffic, placing the burden of processing on the local software. The underlying *SRTP2* stack must *inspect the incoming frames* and
*filter* the content, providing a *Producer/Consumer-based API model*. This allows the *high-level application* to *subscribe* only to the specific *Sampled Values* and *Events*
relevant to its operation, silently discarding the rest.

Figure @srtp2-cycle illustrates the timing of a typical SRTP2 cycle:

#figure(image("Assets/SRTP2-Cycle.svg", width: 80%), caption: [SRTP2 Cycle]) <srtp2-cycle>

At the *Ethernet* link layer, *SRTP2* specifies exactly *two* distinct frame types: *Beacon* frames and *Multi-PDU* (MPDU) frames. The *MPDU* frame acts as an aggregate container
designed to encapsulate *multiple* embedded *SRTP2 Protocol Data Units* (PDUs) referred as *ePDU* for this reason. By multiplexing several ePDUs into a single physical Ethernet
payload, the SRTP2 stack significantly reduces protocol overhead and optimizes overall network bandwidth utilization.

#pagebreak()

== Beacon Frame

The *Beacon* frame is *periodically* transmitted by the *Master Node* as a network-wide *broadcast* to all *Controller Nodes*. Acting as the fundamental *heartbeat* and
*synchronization* pulse of the *SRTP2* network, it dictates the exact timing of the communication cycle. Crucially, a *Controller Node* is strictly prohibited from transmitting
any data onto the network except as a direct response to a valid *Beacon* frame.

#figure(image("Assets/SRTP2-Beacon.svg", height: 3.4cm), caption: [Beacon Frame]) <srtp2-beacon>

To *optimize processing overhead* and minimize byte-swapping operations on modern hardware (such as ARM and x86 architectures), all multi-byte payload fields within the *SRTP2*
frames are encoded in *little-endian* format. However, in strict compliance with the _IEEE 802.3_ standard, the *EtherType* header field must remain encoded in *big-endian*
(network byte) order.

=== Beacon Frame Field Definitions

- *Preamble*: #linebreak()
  The Preamble is managed and appended automatically by the Ethernet Network Interface Card (NIC) at the Physical Layer (Layer 1) and is not visible to the SRTP2 software stack.

- *Destination Address*: _u8[6] (6-byte array)_ #linebreak()
  The *Destination MAC Address* defines the link-layer recipient. For all *Beacon* frames, this field must be set to the broadcast address: *`FF:FF:FF:FF:FF:FF`*.

- *Source Address*: _u8[6] (6-byte array)_ #linebreak()
  The Source MAC Address contains the unique hardware address of the *Master Node* (MN) currently transmitting the frame.

- *EtherType*: _u16 (Big-Endian / Network Byte Order)_ #linebreak()
  The EtherType identifier for the SRTP2 protocol is strictly defined as *`0xACDC`*. #linebreak()
  #text(size: 10pt)[_Note: In compliance with IEEE 802.3, this is the only field in the SRTP2 header encoded in Big-Endian._]

- *Frame Type*: _u8 (Unsigned Integer)_ #linebreak()
  The *Frame Type* specifies the nature of the SRTP2 payload. Valid identifiers are:
  - *`0x00`* : *Beacon* (Synchronization and Trigger)
  - *`0x01`*: *MPDU* (Controller Node Responses)

- *Network ID*: _char[32] (Fixed-length string)_ #linebreak()
  The Network ID is a 32-character alphanumeric identifier for the logical network segment.
  - This field is *not null-terminated* (`\0`).
  - If the ID is shorter than 32 characters, all remaining bytes must be *padded* with *`0x00`*.

- *Network Time*: _u64 (64-bit Unsigned Integer, Little-Endian)_ #linebreak()
  Represents the current *Master Node* system time in *milliseconds since the UNIX Epoch*. All *Controller Nodes* (CN) must utilize this value to synchronize and discipline their
  local clocks.

- *Cycle Interval*: _u32 (32-bit Unsigned Integer, Little-Endian)_ #linebreak()
  Defines the nominal *time between two consecutive Beacon emissions*, measured in *nanoseconds*. This value defines the fundamental frequency of the SRTP2 network cycle.

- *SV Group Mask*: _u32 (32-bit Bitmask, Little-Endian)_ #linebreak()
  A *bitmask* where each of the 32 bits corresponds to a specific *Sampled Values (SV) Group* (Bit *`0`* for *Group 0*, Bit *`31`* for *Group 31*).
  - *Bit = `1`*: All Controller Nodes must sample the specified group's inputs and include the data in the subsequent response.
  - *Bit = `0`*: Acquisition for the specified group is disabled for the current cycle.

- *Frame Check Sequence (CRC)*: #linebreak()
  The CRC is calculated and appended by the *Ethernet NIC hardware*. While it ensures the integrity of the frame over the wire, it is typically stripped by the hardware upon
  reception and is handled transparently to the SRTP2 software stack.

#pagebreak()

== MPDU Frame

The *Multi-PDU* (MPDU) frame is transmitted by each *Controller Node* (CN) in direct response to a *Beacon* frame from the *Master Node*. By serving as an aggregate container for
multiple *embedded Protocol Data Units* (ePDUs), the *MPDU* minimizes protocol overhead and prevents the network congestion that would result from transmitting numerous small
Ethernet frames. This architectural choice significantly increases the overall throughput and reactivity of the SRTP2 system.

#figure(image("Assets/SRTP2-MPDU.svg", height: 3.2cm), caption: [MPDU frame]) <srtp2-mpdu>

=== Byte Order (Endianness)

To optimize processing efficiency on modern hardware architectures (e.g., ARM, x86), all multi-byte fields within the SRTP2 payload are encoded in *little-endian* format. In
strict accordance with the _IEEE 802.3_ standard, the *EtherType* field must remain in *big-endian* (network byte) order.

=== MPDU Frame Field Definitions

- *Preamble* #linebreak()
  The Preamble is handled automatically by the Ethernet Network Interface Card (NIC) hardware and is not processed by the SRTP2 software stack.

- *Destination Address*: _u8[6] (6-byte array)_ #linebreak()
  The *Destination MAC Address* specifies the recipient of the frame. For all *MPDU* frames, this field must be set to the *broadcast* address: *`FF:FF:FF:FF:FF:FF`*.

- *Source Address*:: _u8[6] (6-byte array)_ #linebreak()
  The *Source MAC Address* contains the unique hardware address of the specific *Controller Node* (CN) transmitting the response.

- *EtherType*: _u16 (Big-Endian / Network Byte Order)_ #linebreak()
  The EtherType identifier for the SRTP2 protocol is strictly defined as *`0xACDC`*. #linebreak()
  #text(size: 10pt)[Note: This is the only field in the frame header encoded in Big-Endian.]

- *ePDU Count*: _u16 (16-bit Unsigned Integer, Little-Endian)_ #linebreak()
  The *ePDU Count* specifies the total number of embedded SRTP2 PDUs encapsulated within this *MPDU* frame. This field is immediately followed by the variable-length *ePDU*
  payload blocks.

- *Frame Check Sequence (CRC)*: #linebreak()
  The CRC is automatically generated and verified by the Ethernet NIC hardware to ensure link-layer integrity. It is transparent to the SRTP2 software layer.

#pagebreak()

== SV ePDU

The *Sampled Values* (SV) *ePDU* is the specific container used to transmit *synchronized measurement data* within an *MPDU* frame.

#figure(image("Assets/SRTP2-SVePDU.svg", height: 3.4cm), caption: [SV ePDU]) <srtp2-svepdu>

=== SV ePDU Frame Field Definitions

- *ePDU Type*: _u8 (Unsigned Integer)_ #linebreak()
  The *ePDU Type identifier* determines the format of the embedded payload. For *Sampled Values*, this field is defined as *`0x00`*.

- *SV Group ID*:: _u8 (Unsigned Integer, Range: 0–31)_ #linebreak()
  The* SV Group ID* identifies the specific measurement group to which the subsequent payload belongs. #linebreak()
  #text(size: 10pt)[Note: Unlike the SV Group Mask in the Beacon frame, this field is a direct integer representing a single group index (0 to 31), not a bitmask.]


- *Length*: _u16 (16-bit Unsigned Integer, Little-Endian)_ #linebreak()
  The Length field specifies the *size of the SV Payload in bytes*. This allows the receiver to correctly delimit the data before the next *ePDU* begins.

- *SV Payload*: _u8[Length] (Variable-length binary data)_ #linebreak()
  The SV Payload contains the *raw application-specific measurement data*. The internal structure of this buffer is not mandated by the SRTP2 protocol; its format is defined
  entirely by the Producer and Consumer applications.

#pagebreak()

== EV ePDU

The Event (EV) ePDU is used to transmit *asynchronous, timestamped notifications*. Unlike Sampled Values, these units are typically generated by specific *state changes* or
*triggers* within an application.

#figure(image("Assets/SRTP2-EVePDU.svg", height: 3.4cm), caption: [EV ePDU]) <srtp2-evepdu>

=== EV ePDU Frame Field Definitions

- *ePDU Type*: _u8 (Unsigned Integer)_ #linebreak()
  The ePDU Type identifier for an *Event embedded PDU* is strictly defined as *`0x01`*.

- *Event ID*: _u16 (16-bit Unsigned Integer, Little-Endian)_ #linebreak()
  The *Event ID* is a unique identifier representing a specific event type. #linebreak()
  #text(size: 10pt)[Important: Event IDs must be unique across the entire SRTP2 network. If multiple applications or nodes coexist on the same segment, the system designer must
  ensure no ID conflicts exist to prevent cross-talk or misinterpretation.]

- *Timestamp*: _u64 (64-bit Unsigned Integer, Little-Endian)_ #linebreak()
  Specifies the precise moment the event was generated, represented in *milliseconds since the UNIX Epoch*. This allows consumers to correlate events with the global network time
  provided in the *Beacon*.

- *Length*: _u16 (16-bit Unsigned Integer, Little-Endian)_ #linebreak()
  The Length field specifies the "size of the Event Payload in bytes". If an event carries no additional data, this value is set to *`0`*.

- *Event Payload*: _u8[Length] (Variable-length binary data)_ #linebreak()
  Contains the application-specific data associated with the event. As with Sampled Values, the internal structure of this buffer is *not defined by the SRTP2 protocol* and must
  be coordinated between the producer and consumer.

#pagebreak()

== MSG ePDU

The *Message* (MSG) *ePDU* enables *point-to-point* (unicast) communication between *Controller Nodes*. Similar to *UDP* in IP-based networking, this is a connectionless and
unacknowledged service. It relies on the underlying Ethernet MAC addresses for node identification and introduces the *Service Access Point Identifier* (SAPI) to multiplex
different application-level services.

#figure(image("Assets/SRTP2-MSGePDU.svg", width: 110%), caption: [MSG ePDU]) <srtp2-msgepdu>

=== MSG ePDU Frame Field Definitions

- *ePDU Type*: _u8 (Unsigned Integer)_ #linebreak()
  The ePDU Type for a *Message embedded PDU* is strictly defined as *`0x02`*.

- *Destination Address*: _u8[6] (6-byte array)_ #linebreak()
  The hardware MAC address of the *target Controller Node*. Unlike the Beacon and MPDU headers, which use broadcast addresses, this field enables *point-to-point delivery* at the
  application layer.

- *Destination SAPI*: _u16 (16-bit Unsigned Integer, Little-Endian, Range: 1–65535)_ #linebreak()
  The *Service Access Point Identifier* of the destination service. This acts similar to a "port number" in UDP to ensure the message is delivered to the correct application on
  the target node.

- *Source SAPI*: _u16 (16-bit Unsigned Integer, Little-Endian, Range: 0–65535)_ #linebreak()
  The *SAPI* of the originating service. This allows the receiver to address a response.
  #text(size: 10pt)[Note: A value of 0 indicates that the sender is not listening for incoming messages and cannot be reached for a reply.]

- *Flags*: _u8 (Bitfield)_ #linebreak()
  Used to signal control information regarding the message state.
  - *Last Fragment* (Bit `0`):
    - *`1`*: Indicates this PDU contains the final segment of a fragmented message.
    - *`0`*: Indicates more fragments are pending in subsequent cycles.

  Bits 1–7: Reserved for future protocol extensions.

- *Fragment Length*: _u16 (16-bit Unsigned Integer, Little-Endian)_ #linebreak()
  The size of the Message Fragment Payload in bytes. #linebreak()
  #text(size: 10pt)[Note: The maximum fragment length is dynamically limited by the remaining *MTU* capacity of the Ethernet frame after accounting for the *MPDU* header and any
  preceding SV or EV ePDUs.]

- *Message Fragment Payload*: _u8[Length] (Variable-length binary data)_ #linebreak()
  Contains the raw data of the message segment. The SRTP2 stack is responsible for the sequential reassembly of these fragments based on the Last Fragment flag, while the internal
  data format remains entirely application-specific.