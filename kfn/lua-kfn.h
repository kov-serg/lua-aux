/* lua-kfn.h */

#define DECL_LUA_KFN(Name,CtxType) \
    static int lua_##Name##_kfn(lua_State* L,int status,lua_KContext kctx) { \
        CtxType *ctx=(CtxType*)kctx; \
        if (Name##_loop(ctx,L)) { \
            lua_settop(L,0); return lua_yieldk(L,0,kctx,lua_##Name##_kfn); \
        } \
        Name##_done(ctx,L); lua_settop(L,0); return 0; \
    } \
    static int lua_##Name##_start(lua_State* L) { \
        CtxType *ctx=(CtxType*)lua_touserdata(L,lua_upvalueindex(1)); \
        return lua_##Name##_kfn(L,1,(lua_KContext)ctx); \
    } \
    static int lua_##Name##_gc(lua_State* L) { \
        CtxType *ctx=(CtxType*)lua_touserdata(L,1); \
        Name##_done(ctx,L); return 0; \
    } \
    static int lua_##Name(lua_State* L) { \
        lua_State* co = lua_newthread(L); \
        CtxType *ctx=(CtxType*)lua_newuserdata(co,sizeof(CtxType)); \
        Name##_init(ctx,L); \
        lua_newtable(co); \
        lua_pushstring(co, "__gc"); \
        lua_pushcfunction(co, lua_##Name##_gc); \
        lua_settable(co,-3); \
        lua_setmetatable(co, -2); \
        lua_pushcclosure(co,lua_##Name##_start,1); \
        return 1; \
    }
