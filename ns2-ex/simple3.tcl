# A simple example for wireless simulation or  simple.tr
# ======================================================================
# Define options
# ======================================================================
set val(chan)         Channel/WirelessChannel
set val(prop)         Propagation/TwoRayGround
set val(netif)        Phy/WirelessPhy
set val(mac)          Mac/802_11
set val(ifq)          Queue/DropTail/PriQueue
set val(ll)           LL
set val(ant)          Antenna/OmniAntenna
set val(ifqlen)       50
set val(nn)           4
set val(rp)           AODV
set val(x)            1000   ;# X dimension of the topography
set val(y)            1000   ;# Y dimension of the topography
set val(time)         20.0  ;# simulation time
set start_time        5.0   ;# simulation start time

proc finish {} {
global ns_ tracefile namfile
$ns_ flush-trace
close $tracefile
close $namfile
exit 0
}

# Main Program
# Initialize Global Variables
set ns_ [new Simulator]

#Define different colors for data flows
$ns color 1 Blue
$ns color 2 Red

set tracefile [open simple2.tr w]
$ns_ use-newtrace
$ns_ trace-all $tracefile


set namfile [open simple2.nam w]
$ns_ namtrace-all-wireless $namfile $val(x) $val(y)

# set up topography object
set topo        [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Create God
create-god $val(nn)
set chan [new $val(chan)]


$ns_ node-config -adhocRouting $val(rp) \
 -llType $val(ll) \
 -macType $val(mac) \
 -ifqType $val(ifq) \
 -ifqLen $val(ifqlen) \
 -antType $val(ant) \
 -propType $val(prop) \
 -phyType $val(netif) \
 -topoInstance $topo \
 -agentTrace ON \
 -routerTrace ON \
 -macTrace ON \
 -movementTrace ON \
 -channel $chan

for {set i 0} {$i< $val(nn) } {incr i} {
    set node_($i) [$ns_ node]
    $node_($i) random-motion 0 ;# disable random motion
}


# Provide initial (X,Y, for now Z=0) co-ordinates for mobilenodes
# and produce some simple node movements
$node_(0) set X_ 10.0
$node_(0) set Y_ 100.0
$node_(0) set Z_ 0.0
$node_(1) set X_ 10.0
$node_(1) set Y_ 200.0
$node_(1) set Z_ 0.0
$node_(2) set X_ 210.0
$node_(2) set Y_ 150.0
$node_(2) set Z_ 0.0
$node_(3) set X_ 300.0
$node_(3) set Y_ 150.0
$node_(3) set Z_ 0.0


$ns_ at 7.0 "$node_(2) setdest 210.0 200.0 100.0"
$ns_ at 10.0 "$node_(2) setdest 210.0 150.0 100.0"

for {set i 0} {$i< $val(nn) } {incr i} {
    $ns_ initial_node_pos $node_($i) 30
}



#for {set i 0} {$i< $val(nn) } {incr i} {
#$ns_ at 0.0 "$node_($i) setdest 10.0 10.0 0.0"
#}


set udp_(0) [new Agent/UDP]
$udp_(0) set fid_ 0
$udp_(1) set class_ 1
$ns_ attach-agent $node_(0) $udp_(0)

set udp_(1) [new Agent/UDP]
$udp_(1) set fid_ 1
$udp_(1) set class_ 2
$ns_ attach-agent $node_(1) $udp_(1)


# Null Agent to receive Packets for Node 0
set null_(0) [new Agent/Null]
$null_(0) set fid_ 3
$ns_ attach-agent $node_(3) $null_(0)

# Constant Bit rate traffic generator
set cbr_(0) [new Application/Traffic/CBR]
$cbr_(0) set packetSize_ 512
$cbr_(0) set interval_ 0.1
$cbr_(0) set random_ 0
$cbr_(0) set maxpkts_ 10000
$cbr_(0) attach-agent $udp_(0)

set cbr_(1) [new Application/Traffic/CBR]
$cbr_(1) set packetSize_ 512
$cbr_(1) set interval_ 0.1
$cbr_(1) set random_ 0
$cbr_(1) set maxpkts_ 10000
$cbr_(1) attach-agent $udp_(1)

$ns_ connect $udp_(0) $null_(0)
$ns_ at $start_time "$cbr_(0) start"

$ns_ connect $udp_(1) $null_(0)
$ns_ at $start_time "$cbr_(1) start"


# Tell nodes when the simulation ends
for {set i 0} {$i< $val(nn) } {incr i} {
    $ns_ at $val(time) "$node_($i) reset";
}

$ns_ at $val(time) "finish"
$ns_ at [expr $val(time) + 0.01] "puts \"NS EXITING...\"; $ns_ halt"
puts "Starting Simulation..."
$ns_ run
