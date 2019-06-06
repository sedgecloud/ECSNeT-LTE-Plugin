// 
//                           SimuLTE
// 
// This file is part of a software released under the license included in file
// "license.pdf". This license can be also found at http://www.ltesimulator.com/
// The above file and the present reference are part of the software itself, 
// and cannot be removed from it.
// 
package ecsnetpp.networks.lte;

import inet.networklayer.configurator.ipv4.IPv4NetworkConfigurator;
import inet.networklayer.ipv4.RoutingTableRecorder;
import inet.node.ethernet.Eth10G;
import inet.node.ethernet.Eth10M;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import lte.corenetwork.binder.LteBinder;
import lte.corenetwork.nodes.Ue;
import lte.corenetwork.nodes.eNodeB;
import lte.world.radio.LteChannelControl;
import lte.epc.PgwStandardSimplified;
import ecsnetpp.host.LTEEnabledPhone;
import ecsnetpp.host.CloudNodeA;
import ecsnetpp.builder.ECSBuilder;
import ecsnetpp.common.SimulationController;

network LTENetworkSingleCell
{
    parameters:
        int numPhones = default(1);
        bool ackersEnabled = default(false);
        bool hasGlobalSupervisor = default(false);
        bool checkpointsEnabled = default(false);
        string cloudAddress = default("");
        @display("i=block/network2;bgb=991,558;bgi=background/budapest");
    submodules:
        channelControl: LteChannelControl {
            @display("p=50,25;is=s");
        }
        routingRecorder: RoutingTableRecorder {
            @display("p=50,75;is=s");
        }
        configurator: IPv4NetworkConfigurator {
            @display("p=50,125");
            config = xmldoc("../src/configs/lte/network_ip_config.xml");
        }
        binder: LteBinder {
            @display("p=50,175;is=s");
        }
        stargazer3: CloudNodeA {
            @display("p=212,118;is=n;i=device/server");
        }
        router: Router {
            @display("p=321,136;i=device/smallrouter");
        }
        pgw: PgwStandardSimplified {
            nodeType = "PGW";
            @display("p=519,175;is=l");
        }
        eNodeB: eNodeB {
            @display("p=391,259;is=vl");
        }
        region1[numPhones]: LTEEnabledPhone {
            @display("p=783,278");
        }
        taskbuilder: ECSBuilder {
            @display("p=492.70398,39.871998");
        }
        simController: SimulationController {
            @display("p=783.2,39.871998");
        }
    connections:
        stargazer3.pppg++ <--> Eth10G <--> router.pppg++;
        router.pppg++ <--> Eth10G <--> pgw.filterGate;
        pgw.pppg++ <--> Eth10G <--> eNodeB.ppp;
}
