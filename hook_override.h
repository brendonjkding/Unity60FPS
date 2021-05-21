#import <hookzz.h>
#import <substrate.h>
#if !(__has_feature(ptrauth_calls))
#define MSHookFunction(_func, _new, _orig) \
    do {\
        ZzBuildHook(_func, _new, _orig, NULL, NULL);\
        ZzEnableHook(_func);\
    } while (0)
#endif