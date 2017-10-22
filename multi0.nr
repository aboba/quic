.\" format this document with "rfc multi0.nr draft-aboba-avtcore-quic-multiplexing-00.txt"
.nr HY 0
.pl 10.0i
.po 0
.ll 7.2i
.lt 7.2i
.nr LL 7.2i
.nr LT 7.2i
.ds LH INTERNET-DRAFT
.ds CH QUIC Multiplexing
.ds RH \*(DY
.ds LF Aboba, et. al
.ds CF Informational
.ds RF FORMFEED[Page %]

.tl 'AVTCORE Working Group''B. Aboba'
.tl 'INTERNET-DRAFT''Microsoft Corporation'
.tl 'Category: Informational''P. Thatcher'
.tl 'Expires: April 24, 2018''Google'
.tl '''C. Perkins'
.tl '''University College London'
.tl '''\*(DY'
.ad l
.LP
.ce
QUIC Multiplexing
.ce
draft-aboba-avtcore-quic-multiplexing-00.txt

Abstract

.in +0.3i
This document describes potential approaches to
multiplexing of QUIC along with RTP, RTCP, DTLS, STUN,
TURN and ZRTP in WebRTC peer-to-peer data exchange.
.in -0.3i

Status of This Memo

.in +0.3i
This Internet-Draft is submitted in full conformance with the
provisions of BCP 78 and BCP 79.

Internet-Drafts are working documents of the Internet Engineering
Task Force (IETF).  Note that other groups may also distribute
working documents as Internet-Drafts.  The list of current Internet-
Drafts is at http://datatracker.ietf.org/drafts/current/.

Internet-Drafts are draft documents valid for a maximum of six months
and may be updated, replaced, or obsoleted by other documents at any
time.  It is inappropriate to use Internet-Drafts as reference
material or to cite them other than as "work in progress."

This Internet-Draft will expire on April 24, 2018. 
.in -0.3i
.bp
Copyright Notice

.in +0.3i
Copyright (c) 2017 IETF Trust and the persons identified as the
document authors.  All rights reserved.

This document is subject to BCP 78 and the IETF Trust's Legal
Provisions Relating to IETF Documents
(http://trustee.ietf.org/license-info) in effect on the date of
publication of this document.  Please review these documents
carefully, as they describe your rights and restrictions with respect
to this document.  Code Components extracted from this document must
include Simplified BSD License text as described in Section 4.e of
the Trust Legal Provisions and are provided without warranty as
described in the Simplified BSD License.
.in -0.3i

Table of Contents

.in +0.3i
.nf
1.  Introduction . . . . . . . . . . . . . . . . . . . . . . . . .  3
  1.1.  Terminology  . . . . . . . . . . . . . . . . . . . . . . .  4
2.  Solutions  . . . . . . . . . . . . . . . . . . . . . . . . . .  4
  2.1.  QUIC Header Changes  . . . . . . . . . . . . . . . . . . .  4
  2.2.  Multiplexing Shim  . . . . . . . . . . . . . . . . . . . .  4
  2.3.  Heuristics . . . . . . . . . . . . . . . . . . . . . . . .  5   
4.  Security Considerations  . . . . . . . . . . . . . . . . . . .  5
5.  IANA Considerations  . . . . . . . . . . . . . . . . . . . . .  6
6.  References . . . . . . . . . . . . . . . . . . . . . . . . . .  6
  6.1. Informative references  . . . . . . . . . . . . . . . . . .  6
Acknowledgments  . . . . . . . . . . . . . . . . . . . . . . . . .  6
Authors' Addresses . . . . . . . . . . . . . . . . . . . . . . . .  7
.fi
.in -0.3i
.bp
.NH 1
.R
Introduction

.in +0.3i
Currently, there is interest in using QUIC for peer-to-peer
data exchange within WebRTC. For example, a Javascript API for
peer-to-peer QUIC data exchange has been incorporated into the
ORTC API [ORTC], under development within the W3C ORTC Community Group. 

In WebRTC peer-to-peer data exchange scenarios, QUIC may need to be
multiplexed with packets from RTP, RTCP, DTLS, STUN, TURN and
ZRTP over a single ICE transport.
As noted in [RFC7983] Figure 3, multiplexing of these protocols currently
relies upon differentiation based on the first octet, as follows:

.nf
                    +----------------+
                    |        [0..3] -+--> forward to STUN
                    |                |
                    |      [16..19] -+--> forward to ZRTP
                    |                |
        packet -->  |      [20..63] -+--> forward to DTLS
                    |                |
                    |      [64..79] -+--> forward to TURN Channel
                    |                |
                    |    [128..191] -+--> forward to RTP/RTCP
                    +----------------+

     Figure 1: The DTLS-SRTP receiver's packet demultiplexing algorithm.
.fi

As noted by Colin Perkins and Lars Eggert in [QUIC-Issue] this creates a potential conflict
with the current design of the QUIC headers, since
the first octet of the QUIC header is either:

.nf
 +-+-+-+-+-+-+-+-+
 |1|   Type (7)  |  Long header packet
 +-+-+-+-+-+-+-+-+
.fi

which potentially produces values of the first octet in the range 128-136, conflicting
with RTP/RTCP, or

.nf
 +-+-+-+-+-+-+-+-+
 |0|C|K| Type (5)|  Short header packet
 +-+-+-+-+-+-+-+-+
.fi

which produces values for the first octet in the ranges 0-3, 32-35, 64-67 or 96-99,
potentially conflicting with STUN, DTLS or TURN.
.in -0.3i
.NH 2
.R
Terminology

.in +0.3i
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in [RFC2119].
.in -0.3i
.NH 1
.R
Solutions

.in +0.3i
This section presents potential solutions to the QUIC multiplexing problem,
including changes to the QUIC headers, addition of a multiplexing octet and
use of heuristics.
.in -0.3i
.NH 2
.R
QUIC Header Changes

.in +0.3i
As noted in [QUIC-issue], a potential solution involves changes to the QUIC headers,
such as setting the top two bits of the first octet of a QUIC packet to 1.  This
would imply a reduction in the size of the type fields: 

.nf
 +-+-+-+-+-+-+-+-+
 |1|1|1|Type (5) |  Long header packet
 +-+-+-+-+-+-+-+-+

 +-+-+-+-+-+-+-+-+
 |1|1|0|C|K|Type3|  Short header packet
 +-+-+-+-+-+-+-+-+
.fi
.in -0.3i
.NH 3
.R
Pros and Cons

.in +0.3i
The advantage to this approach is that it adds no additional overhead to the on-the-wire QUIC protocol.
However it does require a reduction in the size of the QUIC Type fields and could potentially
require allocation of first octet code points 192-223 (Short header) 
and 224-255 (Long header) for use by QUIC, consuming much (all?) of the multiplexing space not
allocated in [RFC7983].
Note: double-check this.
.in -0.3i
.NH 2
.R
Multiplexing Shim

.in +0.3i
In this approach, an initial octet not allocated within [RFC7983] would be prepended to
each QUIC packet, allowing QUIC packets to be differentiated from RTP, RTCP, DTLS, STUN,
TURN and ZRTP based on the first octet alone. As an example, an octet with decimal
value 192 could be used:

.nf
 +-+-+-+-+-+-+-+-+
 |1|1|0|0|0|0|0|0|
 +-+-+-+-+-+-+-+-+
.fi
.in -0.3i
.NH 3
.R
Pros and Cons

.in +0.3i
The advantage of this approach is that it consumes only a single unallocated code point for demultiplexing
of QUIC. The disadvantage is that adds a single octet of overhead to every QUIC packet, which could impact
performance in situations where small payloads are exchanged, such as in peer-to-peer gaming. 
.in -0.3i
.NH 2
.R
Heuristics

.in +0.3i
During the QUIC WG interim in Seattle, Martin Thomson suggested the following heuristics for differentiation
of QUIC packets from RTP/RTCP/DTLS/STUN/TURN/ZRTP: 

.nf
1. Demux differently during "handshake time" and "steady state".  
2. During handshake, we only need to worry about long-form QUIC, which makes it is easy.  
    a. Force all handshake packets to be QUIC long-form
    b. QUIC long form (0x1XXXXXXX) does not conflict with STUN (0x000000XX), 
       DTLS (0x000XXXXX), or TURN Channel (0x01XXXXXX)
    c. It does conflict with RTP/RTCP (0x10XXXXXX) but those packets typically 
       aren't sent until the handshake is completed. (Corner case: you bring up 
       A/V keyed with DTLS-SRTP without QUIC, then decide you want to add QUIC data (e.g. a white-board)). 
        i. Alternative: force the RTP padding bit to 1 using a one-byte pad if 
           there isn't already padding (pad == 0x01).  Then force QUIC to have a type < 64 (the current max is 8).
3. During "steady state", we only need to worry about short-form which makes it easy.
    a. QUIC doesn't need long form after the handshake.
    b. QUIC short form (0x0XXXXXXX) does not conflict with RTP/RTCP (0x10XXXXXX), so 
       only need to worry about conflicts with STUN/TURN/ZRTP/DTLS.
    c. Disallow simultaneous use of DTLS and QUIC short form packets.  
         i. Alternative: when using DTLS at the same time, use long form QUIC for all packets.  
            Not optimal, but isn't really needed.
    d. ICE can be demuxed using the magic cookie and checksum.  
         i. Alternative: STUN can only conflict with 3 QUIC packet types: Version Negotiation, 
            Client Initial, and Server Stateless Retry.  Out of those, none should be needed during the steady state. 
    e. You shouldn't need to demux QUIC with TURN channel data or other STUN traffic. (What about consent packets?)
.fi
.in -0.3i
.NH 3
.R
Pros and Cons

.in +0.3i
This approach has the advantage that it requires no changes to QUIC headers, nor does it add any overhead
to QUIC packets.
Question: How would this affect the remaining multiplexing space? 
.in -0.3i
.NH 1
.R
Security Considerations

.in +0.3i
It is not believed that the solutions discussed in this document
introduce any specific security
considerations beyond those detailed in [RFC7983].
.in -0.3i
.NH 1
.R
IANA Considerations

.in +0.3i
This document does not require actions by IANA.
.in -0.3i
.NH 1
.R
References
.NH 2
.R
Informative References
.IP [ORTC] 10
Raymond, R., Aboba, B. and J. Uberti,
"Object RTC (ORTC) API for WebRTC", W3C,
http://draft.ortc.org/, October 2017.
.IP [RFC7983]
Petit-Huguenin, M. and G. Salgueiro, 
"Multiplexing Scheme Updates
for Secure Real-time Transport Protocol (SRTP) Extension
for Datagram Transport Layer Security (DTLS)",
RFC 7983, September 2016.
.IP [QUIC-Issue]
Perkins, C., "QUIC header format/demultiplexing", 
https://github.com/quicwg/base-drafts/issues/426, 
March, 2017. 
.LP
Acknowledgments

.in +0.3i
We would like to thank Martin Thomson, Roni Even and other participants
in the IETF QUIC and AVTCORE working groups
for their discussion of the QUIC multiplexing
issue, and their input relating to potential solutions.
.in -0.3i
.bp
Authors' Addresses

.in +0.3i
.nf
Bernard Aboba
Microsoft Corporation
One Microsoft Way
Redmond, WA  98052
USA

Email:  bernard.aboba@gmail.com

Peter Thatcher
Google
747 6th St S
Kirkland, WA  98033
USA

Email: pthatcher@google.com

Colin Perkins
Department of Computer Science
University College London
London WC1E 6BT
United Kingdom

Email: C.Perkins@cs.ucl.ac.uk
.fi
.in -0.3i
