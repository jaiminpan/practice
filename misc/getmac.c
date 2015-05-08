
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <net/ethernet.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <netinet/if_ether.h>

#include <errno.h>


struct
{
	const char *dev;
	int sd;
	struct ether_addr hwaddr;
	struct in_addr ip;
	struct in_addr bcast;
	struct in_addr nmask;
	unsigned int mtu;
} local_info;

void Utils_EthInit(const char* devname);
void Utils_EthGetMAC(void);
void Utils_EthGetIP(void);
void Utils_EthGetMTU(void);
void Utils_EthGetBCMask(void);

void Utils_PrintMAC(void);
void Utils_PrintIP(void);
void Utils_PrintMTU(void);
void Utils_PrintBCMask(void);

int
main(int argc, char **argv)
{
	if (argc != 2)
	{
		fprintf(stderr,"usage: <command> <devicename>\n");
		exit(1);
	}
	Utils_EthInit(argv[1]);

	Utils_EthGetMAC();
	Utils_EthGetIP();
	Utils_EthGetMTU();
	Utils_EthGetBCMask();

	return 0;
}

void
Utils_EthInit(const char *devname)
{
	//Intitating Socket
	int sockfd = socket(PF_INET, SOCK_DGRAM, IPPROTO_IP);
	if (sockfd < 0)
	{
		printf("> Error initating the ethernet socket..%s\n", strerror(errno));
		exit(-1);
	}
	local_info.sd = sockfd;
	local_info.dev = devname;
}

/*
 * <net/ethernet.h>
 * The number of bytes in an ethernet (MAC) address.
 * ETHER_ADDR_LEN
 * struct ether_addr
*/
void
Utils_EthGetMAC(void)
{
	struct ifreq ifr;

	memset(&ifr,0,sizeof(ifr));
	strncpy(ifr.ifr_name, local_info.dev, sizeof(ifr.ifr_name));
	if (ioctl(local_info.sd, SIOCGIFHWADDR, &ifr) < 0)
	{
		printf("> Error Getting the Local Mac address\n");
		exit(-1);
	}

	memcpy(&(local_info.hwaddr), &ifr.ifr_hwaddr.sa_data, ETHER_ADDR_LEN);

	Utils_PrintMAC();
}

void
Utils_PrintMAC(void)
{
	printf("> MAC Address: %02x:%02x:%02x:%02x:%02x:%02x\n",
			local_info.hwaddr.ether_addr_octet[0], local_info.hwaddr.ether_addr_octet[1],
			local_info.hwaddr.ether_addr_octet[2], local_info.hwaddr.ether_addr_octet[3],
			local_info.hwaddr.ether_addr_octet[4], local_info.hwaddr.ether_addr_octet[5]);
}

/* Device IP Address
 * INET_ADDRSTRLEN
 */
void
Utils_EthGetIP(void)
{
	struct ifreq ifr;

	memset(&ifr, 0, sizeof(ifr));
	strncpy(ifr.ifr_name, local_info.dev, sizeof(ifr.ifr_name));
	if (ioctl(local_info.sd, SIOCGIFADDR, &ifr) < 0)
	{
		printf("> Error gettint the local IP address\n");
		exit(-1);
	}
	memcpy(&(local_info.ip), &((struct sockaddr_in *)(&ifr.ifr_addr))->sin_addr, sizeof(struct in_addr));

	Utils_PrintIP();
}

void
Utils_PrintIP(void)
{
	printf("> IP Address: %s\n", inet_ntoa(local_info.ip));
}

/* Device MTU */
void
Utils_EthGetMTU(void)
{
	struct ifreq ifr;

	memset(&ifr,0,sizeof(ifr));
	strncpy(ifr.ifr_name, local_info.dev, sizeof(ifr.ifr_name));
	if (ioctl(local_info.sd, SIOCGIFMTU, &ifr) < 0)
	{
		printf("> Error Getting the MTU Value\n");
		exit(-1);
	}

	local_info.mtu = ifr.ifr_mtu;

	Utils_PrintMTU();
}

void
Utils_PrintMTU(void)
{
	printf("> MTU Value: %d \n", local_info.mtu);
}

/* Device BroadCast Mask */
void
Utils_EthGetBCMask(void)
{
	struct ifreq ifr;

	memset(&ifr, 0, sizeof(ifr));
	strncpy(ifr.ifr_name, local_info.dev, sizeof (ifr.ifr_name));
	if (ioctl(local_info.sd, SIOCGIFBRDADDR, &ifr) < 0 )
	{
		printf("> Error getting the Broadcast address\n");
		exit(-1);
	}
	memcpy(&(local_info.bcast), &((struct sockaddr_in *)(&ifr.ifr_addr))->sin_addr,
			sizeof(struct in_addr));

	Utils_PrintBCMask();
}

void
Utils_PrintBCMask(void)
{
	printf("> BroadCast address: %s\n", inet_ntoa(local_info.bcast));
}

