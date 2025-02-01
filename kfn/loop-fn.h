/* loop-fn.h - sequential execution function */
#ifndef __LOOP_FN_H__
#define __LOOP_FN_H__

typedef int loop_t;

#define LOOP_RESET(loop) { loop=0; }
#if defined(__COUNTER__) && __COUNTER__!=__COUNTER__
#define LOOP_BEGIN(loop) { enum { __loop_base=__COUNTER__ }; \
    loop_t *__loop=&(loop); __loop_switch: \
    switch(*__loop) { default: *__loop=0; case 0: {
#define LOOP_POINT { enum { __loop_case=__COUNTER__-__loop_base }; \
    *__loop=__loop_case; goto __loop_leave; case __loop_case:{} }
#else
#define LOOP_BEGIN(loop) { loop_t *__loop=&(loop); __loop_switch: \
    switch(*__loop){ default: case 0: *__loop=__LINE__; case __LINE__:{
#define LOOP_POINT { *__loop=__LINE__; goto __loop_leave; case __LINE__:{} }
#endif
#define LOOP_POINT_(name) { *__loop=name; goto __loop_leave; case name:{} }
#define LOOP_END { __loop_end: *__loop=-1; case -1: return 0; } \
    }} __loop_leave: return 1; }

#endif /* __LOOP_FN_H__ */

