
#include <stdio.h>

#include <asm/types.h>

/*get  x86_vendor_id and x86_model_id */
struct cpuinfo_x86
{
	__u8 x86;        /* CPU family */
	__u8 x86_vendor; /* CPU vendor */
	__u8 x86_model;
	__u8 x86_mask;
	char wp_works_ok;    /* It doesn't on 386's */
	char hlt_works_ok;    /* Problems on some 486Dx4's and old 386's */
	char hard_math;
	char rfu;
	int cpuid_level; /* Maximum supported CPUID level, -1=no CPUID */
	unsigned long x86_capability[7];
	char x86_vendor_id[16];	/* CPU manufactor */
	char x86_model_id[64];	/* CPU infomation */
	int x86_cache_size;  /* in KB - valid for CPUS which support this
					   call  */
	int x86_cache_alignment; /* In bytes */
	int fdiv_bug;
	int f00f_bug;
	int coma_bug;
	unsigned long loops_per_jiffy;
	unsigned char x86_num_cores;
};

struct cpuinfo_x86 cpu_info;

static inline void
cpuid(int op, unsigned int *eax, unsigned int *ebx,
		unsigned int *ecx, unsigned int *edx)
{
	__asm__("cpuid"
		  : "=a" (*eax),
			"=b" (*ebx),
			"=c" (*ecx),
			"=d" (*edx)
		  : "0" (op));
}

unsigned int
get_cpu_id()
{
	unsigned int *v;

	cpuid(0x00000000, &cpu_info.cpuid_level,
		 (int *)&cpu_info.x86_vendor_id[0],
		 (int *)&cpu_info.x86_vendor_id[8],
		 (int *)&cpu_info.x86_vendor_id[4]);

	v = (unsigned int *) cpu_info.x86_model_id;
	cpuid(0x80000002, &v[0], &v[1], &v[2], &v[3]);
	cpuid(0x80000003, &v[4], &v[5], &v[6], &v[7]);
	cpuid(0x80000004, &v[8], &v[9], &v[10], &v[11]);

	return 0;
}


int main(int argc, char* argv[])
{
	get_cpu_id();
	printf ("x86_model_id = %s\n", cpu_info.x86_model_id);
	printf ("x86_vendor_id = %s\n", cpu_info.x86_vendor_id);
}
