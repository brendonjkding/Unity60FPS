#import <hookzz.h>
#import <substrate.h>
#define MSHookFunction(_func, _new, _orig) \
    do {\
        ZzBuildHook(_func, _new, _orig, NULL, NULL);\
        ZzEnableHook(_func);\
    } while (0)