#import <substrate.h>
#import <notify.h>
#import <string.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import "hook_override.h"

kern_return_t mach_vm_region
(
    vm_map_t target_task,
    mach_vm_address_t *address,
    mach_vm_size_t *size,
    vm_region_flavor_t flavor,
    vm_region_info_t info,
    mach_msg_type_number_t *infoCnt,
    mach_port_t *object_name
);

extern kern_return_t mach_vm_read
(
    vm_map_t        map,
    mach_vm_address_t   addr,
    mach_vm_size_t      size,
    pointer_t       *data,
    mach_msg_type_number_t  *data_size
);

static BOOL enabled;
static int customFps;
static BOOL setFPSOnFirstTouch;

static long aslr;

typedef long (*orig_t)(int);

%group unity
%hookf(long, setTargetFrameRate, int fps){
    NSLog(@"orig_setTargetFrameRate called, orig_rate: %d",fps);
    long ret=%orig(enabled?customFps:fps);
    return ret;
}
%end//unity

#pragma mark helper function
// thanks to https://reverseengineering.stackexchange.com/questions/15418/getting-function-address-by-reading-adrp-and-add-instruction-values

static inline uint64_t get_page_address_64(uint64_t addr, uint32_t pagesize)
{
    return addr&~0xfff;
}
static inline bool is_adrp(int32_t ins){
    return (((ins>>24)&0b11111)==0b10000) && (ins>>31);
}
static inline bool is_64add(int32_t ins){
    return ((ins>>23)&0b111111111)==0b100100010;
}
static inline uint64_t get_adrp_address(uint32_t ins,long pc){
    uint32_t instr, immlo, immhi;
    int32_t value;
    bool is_adrp=((ins>>31)&0b1)?1:0;


    instr = ins;
    immlo = (0x60000000 & instr) >> 29;
    immhi = (0xffffe0 & instr) >> 3;
    value = (immlo | immhi)|(1<<31);
    if((value>>20)&1) value|=0xffe00000;
    else value&=~0xffe00000;
    if(is_adrp) value<<= 12;
    //sign extend value to 64 bits
    if(is_adrp) return get_page_address_64(pc, PAGE_SIZE) + (int64_t)value;
    else return pc + (int64_t)value;
}
// static inline uint64_t get_b_address(uint32_t ins,long pc){
//  int32_t imm26=ins&(0x3ffffff);
//  if((ins>>25)&0b1) imm26|=0xfc000000;
//  else imm26&=~0xfc000000;
//  imm26<<=2;
//  return pc+(int64_t)imm26;
// }
static inline uint64_t get_add_value(uint32_t ins){
    uint32_t instr2=ins;

    //imm12 64 bits if sf = 1, else 32 bits
    uint64_t imm12;
    
    //get the imm value from add instruction
    instr2 = ins;
    imm12 = (instr2 & 0x3ffc00) >> 10;
    if(instr2 & 0xc00000)
    {
            imm12 <<= 12;

    }
    return imm12;
}
// static inline uint64_t get_str_imm12(uint32_t ins){
//  return 4*((ins&0x3ffc00)>>10);
// }
// helper function

static kern_return_t get_region_address_and_size(mach_vm_offset_t *address_p, mach_vm_size_t *size_p){
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;
    kern_return_t ret = mach_vm_region(mach_task_self(), address_p, size_p, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name);
    vm_prot_t protection = info.protection;
    if(!protection){
        *address_p += *size_p;
        return get_region_address_and_size(address_p, size_p);
    }
    pointer_t buffer;
    mach_msg_type_number_t bufferSize = *size_p;
    if ((ret = mach_vm_read(mach_task_self(), *address_p, *size_p, &buffer, &bufferSize)) != KERN_SUCCESS){
        return ret;
    }
    return ret;
}

static long find_ad_set_targetFrameRate(long ad_ref){
    ad_ref+=8;
    NSLog(@"ad_ref: 0x%lx",ad_ref-aslr);

    uint32_t ins=*(int*)ad_ref;
    long ad_set_targetFrameRate=get_adrp_address(ins,ad_ref);
    NSLog(@"ad_set_targetFrameRate: 0x%lx",ad_set_targetFrameRate-aslr);
    return ad_set_targetFrameRate;
}

static long find_ref_to_str(long ad_str){
    mach_vm_offset_t address=0;
    mach_vm_size_t size=0;
    while(get_region_address_and_size(&address,&size)==KERN_SUCCESS){
        // NSLog(@"0x%lx 0x%lx",(long)(address-aslr),((long)address+(long)size-aslr));
        if(ad_str<address){
            return false;
        }
        for(long ad=address;ad+4<address+size;ad+=4){
            int32_t ins=*(int32_t*)ad;
            int32_t ins2=*(int32_t*)(ad+4);
            if(is_adrp(ins)&&is_64add(ins2)){
                uint64_t ad_t=get_adrp_address(ins,ad)+get_add_value(ins2);;
                if(ad_t==ad_str) return ad;
            }
        }
        address+=size;
    }

    return false;
}
static long find_ad_ref(){
    mach_vm_offset_t address=0;
    mach_vm_size_t size=0;
    while(get_region_address_and_size(&address,&size)==KERN_SUCCESS){
        // NSLog(@"0x%lx 0x%lx",(long)(address-aslr),((long)address+(long)size-aslr));
        for(long ad=address;ad<address+size;ad++){
            static const char *t="UnityEngine.Application::set_targetFrameRate";
            if(!strcmp((const char*)(ad),t)) {
                static int count=0;
                NSLog(@"ad_str candidate %d: 0x%lx",++count,ad-aslr);
                long ad_ref=find_ref_to_str(ad);
                if(ad_ref) return ad_ref;
            }
        }
        address+=size;
    }

    return false;
}

static void loadFrameWork(){
    aslr=_dyld_get_image_vmaddr_slide(0);
    NSString*bundlePath=[NSString stringWithFormat:@"%@/Frameworks/UnityFramework.framework",[[NSBundle mainBundle] bundlePath]];
    NSBundle *bundle=[NSBundle bundleWithPath:bundlePath];
    [bundle load];
    if([bundle isLoaded]){
        for(int i=0;i<_dyld_image_count();i++){
            const char*image_name=_dyld_get_image_name(i);
            if(strstr(image_name, "UnityFramework.framework/UnityFramework")){
                aslr=_dyld_get_image_vmaddr_slide(i);
            }
        }
    }
    NSLog(@"aslr: 0x%lx",(long)aslr);
}

static void startHooking(){
    long ad_ref=find_ad_ref();

    long ad_set_targetFrameRate=find_ad_set_targetFrameRate(ad_ref);

    NSLog(@"hook setTargetFrameRate start");
    %init(unity,setTargetFrameRate=(void*)ad_set_targetFrameRate);
    NSLog(@"hook setTargetFrameRate success");
}

static void loadPref(){
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
    enabled=prefs[@"enabled"]?[prefs[@"enabled"] boolValue]:YES;
    customFps=prefs[@"customFps"]?[prefs[@"customFps"] intValue]:60;
    setFPSOnFirstTouch=prefs[@"setFPSOnFirstTouch"]?[prefs[@"setFPSOnFirstTouch"] boolValue]:YES;
    NSLog(@"customFps: %d",customFps);

    if(_logos_orig$unity$setTargetFrameRate) {
        (void)(orig_t)_logos_orig$unity$setTargetFrameRate(customFps);
    }
}
static BOOL isEnabledApp(){
    NSString* bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
    enabled=prefs[@"enabled"]?[prefs[@"enabled"] boolValue]:YES;
    if(!enabled) return NO;
    return [prefs[@"apps"] containsObject:bundleIdentifier];
}
%group hook
%hook UnityView
-(void)touchesBegan:(id)touches withEvent:(id)event{
    %orig;
    if(!enabled||!setFPSOnFirstTouch) return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(_logos_orig$unity$setTargetFrameRate) {
            (void)(orig_t)_logos_orig$unity$setTargetFrameRate(customFps);
        }
    });
}
%end
%end

#pragma mark ctor
%ctor {
    if(!isEnabledApp()) return;

    %init(hook);
    loadPref();

    loadFrameWork();
    startHooking();

    int token = 0;
    notify_register_dispatch("com.brend0n.unity60fpspref/loadPref", &token, dispatch_get_main_queue(), ^(int token) {
        loadPref();
    });
}
