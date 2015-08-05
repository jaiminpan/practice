
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>

#include <sys/socket.h>

#include <sys/ioctl.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <net/ethernet.h>
#include <netinet/if_ether.h>

#define LOG_SYS 1
#define LEVEL_ERR 2
//#include <stddef.h>
//#include <malloc.h>

void
logit(int a, int level, const char* msg)
{
	printf(msg);
}


struct ifconf ifc;

struct ifreq* ifr;

unsigned char *mac_addr;

static int
get_mac_addr(void)
{
	int sockfd, size = 1;

	sockfd = socket(PF_INET, SOCK_DGRAM, IPPROTO_IP);
	if (0 > sockfd)
	{
		logit(LOG_SYS, LEVEL_ERR, "get_mac_addr: cannot open socket.\n" );
		return -1;
	}

	ifc.ifc_req = NULL;
	do {
		++size;
		/* realloc buffer size until no overflow occurs  */
		if (NULL == (ifc.ifc_req = realloc(ifc.ifc_req, size * sizeof(struct ifreq))))
		{
			logit(LOG_SYS, LEVEL_ERR,  "get_mac_addr: out of memory.\n" );
			return -1;
		}
		ifc.ifc_len =  size * sizeof(struct ifreq);
		if (ioctl(sockfd, SIOCGIFCONF, &ifc))
		{
			logit(LOG_SYS, LEVEL_ERR, "get_mac_addr: ioctl SIOCFIFCONF");
			return -1;
		}
	} while (size * sizeof(struct ifreq) <= ifc.ifc_len);

	ifr = ifc.ifc_req;

	for (; ( char * )ifr < ( char * )ifc.ifc_req + ifc.ifc_len; ++ifr)
	{
		if (ifr->ifr_addr.sa_data == (ifr + 1)->ifr_addr.sa_data)
		{
			continue;  /* duplicate, skip it */
		}

		if (ioctl(sockfd, SIOCGIFFLAGS, ifr))
			continue;  /* failed to get flags, skip it */

		printf( "Interface:  %s\n", ifr->ifr_name);
		if (0 == ioctl(sockfd, SIOCGIFHWADDR, ifr))
		{
			switch (ifr->ifr_hwaddr.sa_family)
			{
				case ARPHRD_NETROM:
				case ARPHRD_ETHER:
				case ARPHRD_PPP:
				case ARPHRD_EETHER:
				case ARPHRD_IEEE802:
					break;
				default:
					printf( "%d \n", ifr->ifr_hwaddr.sa_family);
					continue;
			}
			mac_addr = (unsigned char *)&ifr->ifr_addr.sa_data;
			if (mac_addr[0] + mac_addr[1] + mac_addr[2] + mac_addr[3]
				+ mac_addr[4] + mac_addr[5] )
				return 0;
			else
				return -1;
		}
		printf( "\n" );
	}
	close(sockfd);
	return 0;
}

int
main(int argc, char* argv[])
{
	get_mac_addr();

	printf("> MAC Address: %02x:%02x:%02x:%02x:%02x:%02x\n",
			mac_addr[0], mac_addr[1],
			mac_addr[2], mac_addr[3],
			mac_addr[4], mac_addr[5]);
}
