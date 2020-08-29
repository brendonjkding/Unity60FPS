#import <substrate.h>
#import <notify.h>
#include <string.h>
#import <Foundation/Foundation.h>
#import "readmem/readmem.h"

long aslr;
long ad_fps;
uint64_t main_address;
long main_size;
BOOL enabled=0;
int customFps=60;

static long (*orig_setTargetFrameRate)(int fps)=0;
static long mysetTargetFrameRate(int fps){
	// NSLog(@"orig_setTargetFrameRate called, orig_rate: %d",fps);
	long ret=orig_setTargetFrameRate(enabled?customFps:fps);
	return ret;
}
static long (*orig_callback)(int fps)=0;
static long mycallback(int fps){
	// NSLog(@"orig_callback called");
	if(enabled) *(int*)ad_fps=customFps;
	long ret=orig_callback(enabled?customFps:fps);
	return ret;
}



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
static inline uint64_t get_b_address(uint32_t ins,long pc){
	int32_t imm26=ins&(0x3ffffff);
	if((ins>>25)&0b1) imm26|=0xfc000000;
	else imm26&=~0xfc000000;
	imm26<<=2;
	return pc+(int64_t)imm26;
}
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
static inline uint64_t get_str_imm12(uint32_t ins){
	return 4*((ins&0x3ffc00)>>10);
}
//end----------

long find_ad(long ad_ref){
	ad_ref+=8;
	NSLog(@"ad_ref: 0x%lx",ad_ref-aslr);

	uint32_t ins=*(int*)ad_ref;
	long ad_mid=get_adrp_address(ins,ad_ref);
	NSLog(@"ad_mid: 0x%lx",ad_mid-aslr);


	ins=*(int*)ad_mid;
	long ad_final=get_b_address(ins,ad_mid);
	NSLog(@"ad_final: 0x%lx",ad_final-aslr);

	return ad_final;
}
long search_targetins(long ad_str){
	for(long ad=main_address;ad<main_address+main_size;ad++){
		int32_t ins=*(int32_t*)ad;
		int32_t ins2=*(int32_t*)(ad+4);
		if(is_adrp(ins)&&is_64add(ins2)){
			uint64_t ad_t=get_adrp_address(ins,ad)+get_add_value(ins2);;
			if(ad_t==ad_str) return ad;
		}
	}
	return false;
}
long search_targetstr(){
	for(long ad=main_address;ad<main_address+main_size;ad++){
			static const char *t="UnityEngine.Application::set_targetFrameRate";
			if(!strcmp((const char*)(ad),t)) return ad;
	}
	return false;
}

void hook_callback(long ad_t){
	ad_fps=get_adrp_address(*(uint32_t*)ad_t,ad_t)+get_str_imm12(*(uint32_t*)(ad_t+0x4));
	NSLog(@"ad_fps: 0x%lx",ad_fps-aslr);

	long ad_callback=get_b_address(*(uint32_t*)(ad_t+0x8),ad_t+0x8);
	NSLog(@"ad_callback: 0x%lx",ad_callback-aslr);

	NSLog(@"hook callback start");
	MSHookFunction((void *)ad_callback, (void *)mycallback, (void **)&orig_callback);
	NSLog(@"hook callback success");
}

void hook_setTargetFrameRate(){
	find_main_binary(mach_task_self(),&main_address);
	main_size=get_image_size(main_address,mach_task_self());
	NSLog(@"[*] main: 0x%llx size: %ldMB",main_address-aslr,main_size/1024/1024);

    long ad_str=search_targetstr();
    NSLog(@"ad_str:0x%lx",ad_str-aslr);

    long ad_ref=search_targetins(ad_str);
    long ad_t=find_ad(ad_ref);
    if(is_adrp(*(uint32_t*)ad_t)){
		hook_callback(ad_t);
		return;
	}
	
	NSLog(@"hook setTargetFrameRate start");
	MSHookFunction((void *)ad_t, (void *)mysetTargetFrameRate, (void **)&orig_setTargetFrameRate);
	NSLog(@"hook setTargetFrameRate success");

	return;
}

void loadPref(){
	NSLog(@"loadPref..........");
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.brend0n.fgotw60fpspref.plist"];
	if(!prefs) prefs=[NSMutableDictionary new];
	enabled=prefs[@"enabled"]?[prefs[@"enabled"] boolValue]:YES;
	customFps=prefs[@"customFps"]?[prefs[@"customFps"] intValue]:60;
	NSLog(@"now fps: %d",customFps);
	if(!enabled) return;
	if(orig_setTargetFrameRate) orig_setTargetFrameRate(customFps);
	if(orig_callback) {
		if(enabled) *(int*)ad_fps=customFps;
		orig_callback(customFps);
		
	}
}
bool is_enabled_app(){
	NSString* bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];
	NSArray *fgo_ids=@[@"com.xiaomeng.fategrandorder",@"com.bilibili.fatego",@"com.aniplex.fategrandorder",@"com.aniplex.fategrandorder.en"];
	if([fgo_ids containsObject:bundleIdentifier])return true;
	
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.brend0n.fgotw60fpspref.plist"];
	NSArray *apps=prefs?prefs[@"apps"]:nil;
	if(!apps) return false;
	if([apps containsObject:bundleIdentifier]) return true;
	
	return false;
}


%ctor {
	if(!is_enabled_app()) return;
	loadPref();
	aslr=_dyld_get_image_vmaddr_slide(0);
	NSLog(@"ASLR=0x%lx",aslr);
	hook_setTargetFrameRate();
	int token = 0;
	notify_register_dispatch("com.brend0n.fgotw60fpspref/loadPref", &token, dispatch_get_main_queue(), ^(int token) {
		loadPref();
	});
}
