/* loop-fn.h - sequential execution function */
#ifndef __LOOP_FN_H__
#define __LOOP_FN_H__

typedef int loop_t;

#define LOOP_RESET(loop) { loop=0; }
#if defined(__COUNTER__) && __COUNTER__!=__COUNTER__
#define LOOP_BEGIN(loop) { enum { __loop_base=__COUNTER__ }; \
    loop_t *__loop=&(loop); int __loop_rv; __loop_switch: __loop_rv=1; \
    switch(*__loop) { default: *__loop=0; case 0: {
#define LOOP_POINT { enum { __loop_case=__COUNTER__-__loop_base }; \
    *__loop=__loop_case; goto __loop_leave; case __loop_case:{} }
#else
#define LOOP_BEGIN(loop) {loop_t*__loop=&(loop);__loop_switch:int __loop_rv=1;\
    switch(*__loop){ default: case 0: *__loop=__LINE__; case __LINE__:{
#define LOOP_POINT { *__loop=__LINE__; goto __loop_leave; case __LINE__:{} }
#endif
#define LOOP_END { __loop_end: *__loop=-1; case -1: return 0; \
    { goto __loop_end; goto __loop_switch; /* make msvc happy */ } } \
    }} __loop_leave: return __loop_rv; }
#define LOOP_SET_RV(rv) { __loop_rv=(rv); } /* rv must be non zero */
#define LOOP_INT(n) { __loop_rv=(n); LOOP_POINT } /* interrupt n */
/* for manual labeling: enum { L01=1,L02,L03,L04 }; ... LOOP_POINT_(L02) */
#define LOOP_POINT_(name) { *__loop=name; goto __loop_leave; case name:{} }
#define LOOP_INT_(name,n) { __loop_rv=(n); LOOP_POINT_(name) }
#define LOOP_JUMP(name)   { *__loop=name; goto __loop_leave; }

#endif /* __LOOP_FN_H__ */
