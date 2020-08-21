//Content modified from https://github.com/gdbinit/readmem
#import <mach/mach.h>
#import <mach/vm_region.h>
#import <mach/vm_map.h>
#import <mach-o/loader.h>
#import <sys/sysctl.h>
#import <stdio.h>
#import <stdlib.h>

extern kern_return_t
mach_vm_read(
		vm_map_t		map,
		mach_vm_address_t	addr,
		mach_vm_size_t		size,
		pointer_t		*data,
		mach_msg_type_number_t	*data_size);

extern kern_return_t
mach_vm_write(
		vm_map_t			map,
		mach_vm_address_t		address,
		pointer_t			data,
		__unused mach_msg_type_number_t	size);

extern kern_return_t
mach_vm_region(
		vm_map_t		 map,
		mach_vm_offset_t	*address,
		mach_vm_size_t		*size,		
		vm_region_flavor_t	 flavor,
		vm_region_info_t	 info,		
		mach_msg_type_number_t	*count,	
		mach_port_t		*object_name);
extern kern_return_t mach_vm_read_overwrite
(
		vm_map_t target_task,
		mach_vm_address_t address,
		mach_vm_size_t size,
		mach_vm_address_t data,
		mach_vm_size_t *outsize
 );

extern intptr_t _dyld_get_image_vmaddr_slide(uint32_t image_index);

#define VERSION "0.6"

#define MAX_SIZE 100000000

#define LOG_ERROR(fmt, ...) fprintf(stderr, "[ERROR] " fmt " (%s, %d)\n", ## __VA_ARGS__, __func__, __LINE__)
#define LOG_BADOPT(fmt, ...) fprintf(stderr, "[BAD OPTION] " fmt "\n", ## __VA_ARGS__)


void readmem(mach_vm_offset_t *buffer, mach_vm_address_t address, mach_vm_size_t size, vm_map_t target_task, vm_region_basic_info_data_64_t *info);
mach_vm_address_t get_image_size(mach_vm_address_t address, vm_map_t target_task);
kern_return_t find_main_binary(vm_map_t target_task, mach_vm_address_t *main_address);
