/* mykfn.c - example of stackless c coroutines for lua */

#ifdef __GNUC__
#define EXPORT
#else
#define EXPORT __declspec(dllexport) 
#endif

#include "lauxlib.h"
#include "lua-kfn.h" /* lua wrapper */
#include "loop-fn.h" /* sequenctial function */
#include <stdio.h>

/*-- example of sequential funtion - kfn : {state,init,loop,done} ----------*/

typedef struct {
    int alive;
    loop_t loop;
    int i,n;
} MyfnState;

static void mykfn_init(MyfnState *self,lua_State* L) {
    self->alive=1;
    self->n=lua_tointeger(L,1);
    LOOP_RESET(self->loop)
    printf("kfn_init n=%d\n",self->n);
}

static void mykfn_done(MyfnState *self,lua_State* L) {
    if (self->alive) {
        self->alive=0;
        printf("kfn_done n=%d %s ", self->n, 
            self->loop<0 ? "finished":"not finished");
    } else {
        printf("kfn_done n=%d dead\n",self->n);
    }
}

static int mykfn_loop(MyfnState *self,lua_State* L) {
    LOOP_BEGIN(self->loop)
    printf("first step ");
    LOOP_POINT
    for(self->i=0;self->i<self->n;self->i++) {
       printf("step i=%d ",self->i);
       LOOP_POINT
    }
    printf("last step ");
    LOOP_END
}

DECL_LUA_KFN(mykfn,MyfnState)

/*-- declare lua dynamic library entry -------------------------------------*/

int EXPORT luaopen_mykfn(lua_State* L) {
    lua_register(L, "mykfn",  lua_mykfn); /* add gloabl function mykfn */
    return 0;
}
