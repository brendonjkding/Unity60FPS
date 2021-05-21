#import <dobby.h>
#import <substrate.h>
#define MSHookFunction(_func, _new, _orig) \
    do {\
        dobby_enable_near_branch_trampoline();\
        DobbyHook(_func, _new, _orig);\
        dobby_disable_near_branch_trampoline();\
    } while (0)