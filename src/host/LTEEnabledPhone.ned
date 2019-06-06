//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

package ecsnetpp.host;

import ecsnetpp.stask.ISTask;
import ecsnetpp.stask.StreamingSupervisor;
import ecsnetpp.stask.Acker;
import ecsnetpp.cpu.CPUCore;
import inet.node.inet.StandardHost;
import inet.node.inet.AdhocHost;
import inet.node.inet.WirelessHost;
import lte.corenetwork.nodes.Ue;
import inet.node.inet.NodeBase;
import inet.transportlayer.tcp.TCP;
import inet.transportlayer.udp.UDP;
import ecsnetpp.cpu.scheduling.ICpuCoreScheduler;
import ecsnetpp.cpu.scheduling.RoundRobinCpuCoreScheduler;
import inet.mobility.contract.IMobility;
import inet.networklayer.common.InterfaceTable;
import inet.networklayer.contract.IRoutingTable;
import inet.networklayer.contract.INetworkLayer;
import lte.stack.phy.ILteNic;
import lte.stack.phy.LteNicUe;
import lte.stack.phy.LteNicUeD2D;

module LTEEnabledPhone
{
    parameters:
        @networkNode();
        @display("i=device/pocketpc;bgb=400,518");

        //# Mobility
        string mobilityType = default("StationaryMobility");

        //# Apps
        int numTcpApps = default(0);  // no of TCP apps. Specify the app types in INI file with tcpApp[0..1].typename="TCPEchoApp" syntax
        int numUdpApps = default(0);  // no of UDP apps. Specify the app types in INI file with udpApp[0..1].typename="UDPVideoStreamCli" syntax

        //# Node specs
        string nodeType = "UE";  // DO NOT CHANGE
        int masterId;
        int macNodeId = default(0); // TODO: this is not a real parameter
        int macCellId = default(0); // TODO: this is not a real parameter
        
        //# D2D capability
        bool d2dCapable = default(false);
        string nicType = d2dCapable ? "LteNicUeD2D" : "LteNicUe";

        //# Network Layer specs
        string networkLayerType = default("IPv4NetworkLayer");
        string routingTableType = default("IPv4RoutingTable");
        *.interfaceTableModule = default(absPath(".interfaceTable"));
        *.routingTableModule = default(absPath(".routingTable"));
        int cores = default(4);
        double perCoreFreq @unit(Hz) = 1.2GHz;
        int threadsPerCore = 1;
        double totalMemory @unit(Mb) = 1024Mb;
        double fixedSourceEventRate = default(0);
        bool hasAcker = default(false);
        bool hasUdp = default(false);
        bool hasTcp = default(true);
        bool isEdgeDevice = true;
        string ackerAddress = default("");
        string cpuCoreSchedulerType = default("RoundRobinCpuCoreScheduler");
        @display("bgb=728.91003,656.82");
        @statistic[processingLatency](title="processingLatency"; source=processingTime; record=vector);
        @statistic[transmissionLatency](title="Transmission Latency"; source=transmissionTime; record=vector);
        @statistic[totalLatency](title="Total Latency"; source=latency; record=vector);
    gates:
        inout hostport[];
        input radioIn @directIn;     // connection to master
    submodules:
        cpuCore[cores]: CPUCore {
            @display("p=653.4,39.6,c");
        }
        interfaceTable: InterfaceTable {
            @display("p=50,75;is=s");
        }
        // routing table
        routingTable: <routingTableType> like IRoutingTable if routingTableType != "" {
            parameters:
                @display("p=50,125;is=s");
        }
        mobility: <mobilityType> like IMobility {
            @display("p=50,175;is=s");
        }
        tcp: TCP if hasTcp {
            @display("p=175,150");
        }
        udp: UDP if hasUdp {
            @display("p=325,150");
        }
        lteNic: <nicType> like ILteNic {
            nodeType = nodeType;
            d2dCapable = d2dCapable;
            @display("p=250,407");
        }
        // network layer
        networkLayer: <networkLayerType> like INetworkLayer {
            parameters:
                @display("p=250,258");
        }
        supervisor: StreamingSupervisor;
        cpuCoreScheduler : <cpuCoreSchedulerType> like ICpuCoreScheduler if cpuCoreSchedulerType != "";
        acker: Acker if hasAcker;
    connections allowunconnected:
        tcp.ipOut --> networkLayer.transportIn++ if hasTcp;
        tcp.ipIn <-- networkLayer.transportOut++ if hasTcp;
        udp.ipOut --> networkLayer.transportIn++ if hasUdp;
        udp.ipIn <-- networkLayer.transportOut++ if hasUdp;
        lteNic.radioIn <-- radioIn;
        networkLayer.ifOut++ --> lteNic.upperLayerIn;
        networkLayer.ifIn++ <-- lteNic.upperLayerOut;
        
        supervisor.udpIn <-- udp.appOut++ if hasUdp;
        supervisor.udpOut --> udp.appIn++ if hasUdp;
        supervisor.tcpIn <-- tcp.appOut++ if hasTcp;
        supervisor.tcpOut --> tcp.appIn++ if hasTcp;
        // connect supervisor to acker 
        // only if the acker is placed in this node
        supervisor.ackerOut++ --> acker.ackerIn if hasAcker;
}
