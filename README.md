# mmWave_Optimal_Beamforming

## Setup
Here are the steps for setting up the mmWave experimental platform:
 
1. Turn on the USRP
2. Turn on the power supply (press OCP, OVP, then on/off)
3. Turn on the PC
4. Turn on the laptop and open ACE:
   a. set VCO output to 7.56 GHz
   b. enable AUX RF output at 5dBm
   c. write all registers/Initialize
   d. check lock
 
On the PC side:
5. Open a terminal and cd ~/Downloads/mmw-tutorial/M-Cube-Hostcmds, and then control+shift+t to create two more tabs in the same directory
6. [tab1] ssh root@192.168.137.1 (enter password 123456)
7. [tab2] ssh root@192.168.137.2 (enter password 123456)
8. [tab3] sh setup_server.sh 1 (enable the mmWave NIC, make sure wlan0 interface is up)
9. [tab3] sh setup_server.sh 2 (enable the mmWave NIC, make sure wlan0 interface is up)
10. [tab1] python /tmp/wil6210_server (start up the python daemon)
11. [tab2] python /tmp/wil6210_server (start up the python daemon)
12. [tab3] sh ldcb.sh 1 32 (enable rf chain #5 for node 1, make sure you see the output "enabled_rf_module_vec:  5 ")
13. [tab3] sh ldcb.sh 2 128 (enable rf chain #7 for node 2, make sure you see the output "enabled_rf_module_vec: 7 ")
14. [tab3] for ((i=0;i<$(nproc --all);i++)); do sudo cpufreq-set -c $i -r -g performance; done (put all cpu cores into performance mode in order to stream 200 mega samples per second from the FPGA to the PC)
15. [tab3] matlab &
