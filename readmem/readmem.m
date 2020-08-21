#import "readmem.h"
//Content modified from https://github.com/gdbinit/readmem

/* globals */
mach_vm_address_t vmaddr_slide = 0;

void 
readmem(mach_vm_offset_t *buffer, mach_vm_address_t address, mach_vm_size_t size, vm_map_t target_task , vm_region_basic_info_data_64_t *info)
{
    // get task for pid
    vm_map_t port = target_task;
    kern_return_t kr = 0;
    
    mach_msg_type_number_t info_cnt = sizeof (vm_region_basic_info_data_64_t);
    mach_port_t object_name;
    mach_vm_size_t size_info;
    mach_vm_address_t address_info = address;
    kr = mach_vm_region(port, &address_info, &size_info, VM_REGION_BASIC_INFO_64, (vm_region_info_t)info, &info_cnt, &object_name);
    if (kr)
    {
        LOG_ERROR("mach_vm_region failed with error %d", (int)kr);
        exit(1);
    }

    // read memory - vm_read_overwrite because we supply the buffer
    mach_vm_size_t nread = 0;
    kr = mach_vm_read_overwrite(port, address, size, (mach_vm_address_t)buffer, &nread);

    if (kr)
    {
        LOG_ERROR("vm_read failed! %d", kr);
    }
    else if (nread != size)
    {
        LOG_ERROR("vm_read failed! requested size: 0x%llx read: 0x%llx", size, nread);
    }
}

/*
 * we need to find the binary file size
 * which is taken from the filesize field of each segment command
 * and not the vmsize (because of alignment)
 * if we dump using vmaddresses, we will get the alignment space into the dumped
 * binary and get into problems :-)
 */
uint64_t
get_image_size(mach_vm_address_t address, vm_map_t target_task )
{

    vm_region_basic_info_data_64_t region_info = {0};
    // allocate a buffer to read the header info
    // NOTE: this is not exactly correct since the 64bit version has an extra 4 bytes
    // but this will work for this purpose so no need for more complexity!
    struct mach_header header = {0};
    readmem((mach_vm_offset_t*)&header, address, sizeof(struct mach_header), target_task, &region_info);

    if (header.magic != MH_MAGIC && header.magic != MH_MAGIC_64)
    {
        LOG_ERROR("Target is not a mach-o binary!");
        exit(1);
    }
    
    uint64_t imagefilesize = 0;
    // read the load commands
    uint8_t *loadcmds = (uint8_t*)malloc(header.sizeofcmds);
    uint16_t mach_header_size = sizeof(struct mach_header);
    if (header.magic == MH_MAGIC_64)
    {
        mach_header_size = sizeof(struct mach_header_64);
    }
    readmem((mach_vm_offset_t*)loadcmds, address+mach_header_size, header.sizeofcmds, target_task, &region_info);
    
    // process and retrieve address and size of linkedit
    uint8_t *loadCmdAddress = 0;
    // first load cmd address
    loadCmdAddress = (uint8_t*)loadcmds;
    struct load_command *loadCommand    = NULL;
    struct segment_command *segCmd      = NULL;
    struct segment_command_64 *segCmd64 = NULL;
    // process commands to find the info we need
    for (uint32_t i = 0; i < header.ncmds; i++)
    {
        loadCommand = (struct load_command*)loadCmdAddress;
        // 32bits and 64 bits segment commands
        // LC_LOAD_DYLIB to find the ordinal
        if (loadCommand->cmd == LC_SEGMENT)
        {
            segCmd = (struct segment_command*)loadCmdAddress;
            if (strncmp(segCmd->segname, "__PAGEZERO", 16) != 0)
            {
                if (strncmp(segCmd->segname, "__TEXT", 16) == 0)
                {
                    vmaddr_slide = address - segCmd->vmaddr;
                }
                imagefilesize += segCmd->filesize;
            }
        }
        else if (loadCommand->cmd == LC_SEGMENT_64)
        {
            segCmd64 = (struct segment_command_64*)loadCmdAddress;
            if (strncmp(segCmd64->segname, "__PAGEZERO", 16) != 0)
            {
                if (strncmp(segCmd64->segname, "__TEXT", 16) == 0)
                {
                    vmaddr_slide = address - segCmd64->vmaddr;
                }
                imagefilesize += segCmd64->filesize;
            }
        }
        // advance to next command
        loadCmdAddress += loadCommand->cmdsize;
    }
    free(loadcmds);
    return imagefilesize;
}

/*
 * find main binary by iterating memory region
 * assumes there's only one binary with filetype == MH_EXECUTE
 */
kern_return_t
find_main_binary(vm_map_t target_task, mach_vm_address_t *main_address)
{
  // get task for pid
  kern_return_t kr;
  
  vm_address_t iter = 0;
  while (1)
  {
      struct mach_header mh = {0};
      vm_address_t addr = iter;
      vm_size_t lsize = 0;
      uint32_t depth;
      mach_vm_size_t bytes_read = 0;
      struct vm_region_submap_info_64 info;
      mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
      if (vm_region_recurse_64(target_task, &addr, &lsize, &depth, (vm_region_info_t)&info, &count))
      {
          break;
      }
      kr = mach_vm_read_overwrite(target_task, (mach_vm_address_t)addr, (mach_vm_size_t)sizeof(struct mach_header), (mach_vm_address_t)&mh, &bytes_read);
      if (kr == KERN_SUCCESS && bytes_read == sizeof(struct mach_header))
      {
          /* only one image with MH_EXECUTE filetype */
          if ( (mh.magic == MH_MAGIC || mh.magic == MH_MAGIC_64) && mh.filetype == MH_EXECUTE)
          {
              *main_address = addr;
              break;
          }
      }
      iter = addr + lsize;
  }
  return KERN_SUCCESS;
}




