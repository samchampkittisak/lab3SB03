setval(chan)     Channel/WirelessChannel;
set(prop) 	Propagation/TwoRayGround;
setval(netif)	Phy/WirelessPhy;
setval(mac)	Mac/802_11;
setval(ifq)	Queue/DropTail/PriQueue;
setval(ll)	LL;
setval(ant)	Antenna/OmniAntenna;
setval(ifqlen)	50;
setval(nn)	2;
setval(rp)	AODV;
setval(x)	2000;
setval(y)	2000;
setval(time)	500.0;
setstart_time	60.0;

proc finish{} {
global ns_tracefilenamfile
$ns_flush-trace
close $tracefile
close $namfile
exit 0
}

set ns_[new Simulator]
settracefile [open simple.tr w]
$ns_use-newtrace
$ns_trace-all $tracefile
setnamefile [open simple.nam w]
$ns_namtrace-all-wireless $namfile $val(x) $val(y)

settopo		[new Topography]
$topoload_flatgrid $val(x) $val(y)

Create-god $val(nn)
setchan [new $val(chan)]

#configure node
$ns_node-config 	-adhocRouting $val(rp)\
			-llType $val(ll)\
			-macType $val(mac)\
			-ifqType $val(ifq)\
			-ifqLen $val(ifqlen)\
			-antType $val(ant)\
			-propType $val(prop)\
			-phyType $val(netif)\
			-topoInstance $topo\
			-agentTrace ON\
			-routerTrace ON\
			-macTrace ON\
			-movementTrace ON\
			-channel $chan
		for {set I 0} {$i < $val(nn)} {incri} 
{
		set node_($i) [$ns_node]
		$node_($i) random-motion 0;
		$ns_initial_node_pos $node_($i) 30
}
$node_(0) set X_ 0.0
$node_(0) set Y_ 200.0
$node_(0) set Z_ 100.0
$node_(1) set X_ 350.0
$node_(1) set Y_ 200.0
$node_(1) set Z_ 100.0
$ns_ at 180.0 "$node_(1) setdest 350.0 400.0 100.0"

for {set i 0} {$i < $val(nn)} {incri}
 {
$ns_ at 0.0 "$node_($i) setdest 10.0 10.0 10.0"
}

#Data Source, Nodes
setudp_(0) [new Agent/UDP]
$udp_(0) set fid_ 0
$ns_attach-agent $node_(0) $udp_(0)

#Null Agent to receive Packets for Node 0
setudp_(0) [new Agent/Null]
$null_(0) set fid_ 1
$ns_attach-agent $node_(1) $null_(0)

#CBR traffic generator
setcbr_(0) [new Application/Traffic/CBR]
$cbr_(0) set packetSize_ 512
$cbr_(0) set interval_ 0.1
$cbr_(0) set random_ 0
$cbr_(0) set maxpkts_ 10000
$cbr_(0) set attach-agent $udp(0)

$ns_ connect $udp_(0) $null_(0)
$ns_ at $start_time "$cbr_(0) start"

#Tell nodes when simulation ends
for {set i 0} {$i<$val(nn)} {incri} 
{
$ns_ at $val(time) "$node_($i) reset";
}

$ns_ at $val(time) "finish"
$ns_ at [expr $val(time)+0.01] "puts \NS EXITING…\"; $ns_ halt"
puts "Starting Simulation…"
$ns_ run
