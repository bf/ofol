#include "api.h"
#include "../renwindow.h"
#include "lua.h"
#include <SDL3/SDL.h>
#include <stdlib.h>

static RenWindow *persistant_window = NULL;

// static void init_window_icon(SDL_Window *window) {
// #if !defined(_WIN32) && !defined(__APPLE__)
//   #include "../resources/icons/icon.inl"
//   (void) icon_rgba_len; /* unused */
//   SDL_Surface *surf = SDL_CreateRGBSurfaceFrom(
//     icon_rgba, 64, 64,
//     32, 64 * 4,
//     0x000000ff,
//     0x0000ff00,
//     0x00ff0000,
//     0xff000000);
//   SDL_SetWindowIcon(window, surf);
//   SDL_FreeSurface(surf);
// #endif
// }

static int f_renwin_create(lua_State *L) {
  const char *title = luaL_checkstring(L, 1);
  // const int x = luaL_optinteger(L, 2, SDL_WINDOWPOS_UNDEFINED);
  // const int y = luaL_optinteger(L, 3, SDL_WINDOWPOS_UNDEFINED);
  const int x = luaL_optinteger(L, 2, SDL_WINDOWPOS_CENTERED);
  const int y = luaL_optinteger(L, 3, SDL_WINDOWPOS_CENTERED);
  // const int x = luaL_optinteger(L, 2, 0);
  // const int y = luaL_optinteger(L, 3, 0);
  float width = luaL_optnumber(L, 4, 0);
  float height = luaL_optnumber(L, 5, 0);

  SDL_Log("renwin_create 1: x %d y %d width %f height %f \n", x, y, width, height);


  if (width < 1 || height < 1) {
    SDL_DisplayID displayID = SDL_GetPrimaryDisplay();
    SDL_DisplayMode *dm = SDL_GetCurrentDisplayMode(displayID);
    
    if (dm) {
      width = dm->w * 0.8;
      height = dm->h * 0.8;
    } else {
      // error
      SDL_Log("renwin_create error SDL_GetCurrentDisplayMode %s\n", SDL_GetError());
      exit(1);
    }

  //   // if (width < 1) {
  //   //   width = dm->w * 0.8;
  //   // }
  //   // if (height < 1) {
  //   //   height = dm->h * 0.8;
  //   // }
  //   width = 500;
  //   height = 500;
  }

  SDL_Log("renwin_create 2: x %d y %d width %f height %f \n", x, y, width, height);
  // return 1;

  // SDL3 CreateWindowWithProperties
  SDL_PropertiesID props = SDL_CreateProperties();
  SDL_SetStringProperty(props, SDL_PROP_WINDOW_CREATE_TITLE_STRING, title);
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_X_NUMBER, x);
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_Y_NUMBER, y);
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER, width);
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER, height);
  // For window flags you should use separate window creation properties,
  // but for easier migration from SDL2 you can use the following:
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_FLAGS_NUMBER, SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY
   | SDL_WINDOW_HIDDEN
    );
  SDL_Window *window = SDL_CreateWindowWithProperties(props);
  SDL_DestroyProperties(props);

  // SDL_Window *window = SDL_CreateWindowWithProperties(
  //   title, x, y, width, height,
  //   SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY | SDL_WINDOW_HIDDEN
  // );
  if (window) {
    // init_window_icon(window);

    RenWindow **window_renderer = (RenWindow**)lua_newuserdata(L, sizeof(RenWindow*));
    luaL_setmetatable(L, API_TYPE_RENWINDOW);

    *window_renderer = ren_create(window);

    return 1;
  } else {
    SDL_Log("Error creating window %s\n", SDL_GetError());
    exit(1);
    return luaL_error(L, "Error creating lite-xl window: %s", SDL_GetError());
  }
}

static int f_renwin_gc(lua_State *L) {
  RenWindow *window_renderer = *(RenWindow**)luaL_checkudata(L, 1, API_TYPE_RENWINDOW);
  if (window_renderer != persistant_window)
    ren_destroy(window_renderer);

  return 0;
}

static int f_renwin_get_size(lua_State *L) {
  RenWindow *window_renderer = *(RenWindow**)luaL_checkudata(L, 1, API_TYPE_RENWINDOW);
  int w, h;
  ren_get_size(window_renderer, &w, &h);
  lua_pushnumber(L, w);
  lua_pushnumber(L, h);
  return 2;
}

static int f_renwin_persist(lua_State *L) {
  SDL_Log("f_renwin_persist\n");
  exit(1);

  RenWindow *window_renderer = *(RenWindow**)luaL_checkudata(L, 1, API_TYPE_RENWINDOW);

  persistant_window = window_renderer;
  return 0;
}

static int f_renwin_restore(lua_State *L) {
  if (!persistant_window) {
    lua_pushnil(L);
  }
  else {
    RenWindow **window_renderer = (RenWindow**)lua_newuserdata(L, sizeof(RenWindow*));
    luaL_setmetatable(L, API_TYPE_RENWINDOW);

    *window_renderer = persistant_window;
  }

  return 1;
}

static const luaL_Reg renwindow_lib[] = {
  { "create",     f_renwin_create     },
  { "__gc",       f_renwin_gc         },
  { "get_size",   f_renwin_get_size   },
  { "_persist",   f_renwin_persist    },
  { "_restore",   f_renwin_restore    },
  {NULL, NULL}
};

int luaopen_renwindow(lua_State* L) {
  luaL_newmetatable(L, API_TYPE_RENWINDOW);
  luaL_setfuncs(L, renwindow_lib, 0);
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  return 1;
}
