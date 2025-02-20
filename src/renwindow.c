#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "renwindow.h"

static int query_surface_scale(RenWindow *ren) {
  int w_pixels, h_pixels;
  int w_points, h_points;
  // SDL_GL_GetDrawableSize(ren->window, &w_pixels, &h_pixels);
  if (SDL_GetWindowSizeInPixels(ren->window, &w_pixels, &h_pixels)) {
    // sucess
  } else {
    // error
    SDL_Log("query_surface_scale Error SDL_GetWindowSizeInPixels %s\n", SDL_GetError());
    exit(1);
  }
  if (SDL_GetWindowSize(ren->window, &w_points, &h_points)) {
    // success
  } else {
    // error
    SDL_Log("query_surface_scale Error SDL_GetWindowSize %s\n", SDL_GetError());
    exit(1);
  }

  /* We consider that the ratio pixel/point will always be an integer and
     it is the same along the x and the y axis. */
  assert(w_pixels % w_points == 0 && h_pixels % h_points == 0 && w_pixels / w_points == h_pixels / h_points);
  return w_pixels / w_points;
}

static void setup_renderer(RenWindow *ren, int w, int h) {
  /* Note that w and h here should always be in pixels and obtained from
     a call to SDL_GL_GetDrawableSize(). */
  if (!ren->renderer) {
    // ren->renderer = SDL_CreateRenderer(ren->window, -1, 0);
    if (ren->renderer = SDL_CreateRenderer(ren->window, NULL)) {
      // success
    } else {
      // error
      SDL_Log("setup_renderer Error setting up renderer %s\n", SDL_GetError());
      exit(1);
    }
  }
  if (ren->texture) {
    SDL_DestroyTexture(ren->texture);
  }
  if (ren->texture = SDL_CreateTexture(ren->renderer, SDL_PIXELFORMAT_BGRA32, SDL_TEXTUREACCESS_STREAMING, w, h)) {
    // success 
  } else {
    // error
    SDL_Log("setup_renderer Error SDL_CreateTexture %s\n", SDL_GetError());
    exit(1);
  }

  ren->rensurface.scale = query_surface_scale(ren);
}


void renwin_init_surface(RenWindow *ren) {
  ren->scale_x = ren->scale_y = 1;
  SDL_Log("renwin_init_surface\n");
  if (ren->rensurface.surface) {
    SDL_DestroySurface(ren->rensurface.surface);
  }

  int w, h;
  // SDL_GL_GetDrawableSize(ren->window, &w, &h);
  
  if (SDL_GetWindowSizeInPixels(ren->window, &w, &h)) {
    // success
  } else {
    SDL_Log("Error getting window size in pixels: %s", SDL_GetError());
    exit(2);
  }

  SDL_Log("renwin_init_surfaceSDL_GetWindowSizeInPixels w %d h %d\n", w, h);

  if (ren->rensurface.surface = SDL_CreateSurface(w, h, SDL_PIXELFORMAT_BGRA32)) {
    setup_renderer(ren, w, h);
  } else {
    SDL_Log("Error creating surface: %s", SDL_GetError());
    exit(1);
  }
}

void renwin_init_command_buf(RenWindow *ren) {
  ren->command_buf = NULL;
  ren->command_buf_idx = 0;
  ren->command_buf_size = 0;
}


static RenRect scaled_rect(const RenRect rect, const int scale) {
  return (RenRect) {rect.x * scale, rect.y * scale, rect.width * scale, rect.height * scale};
}


void renwin_clip_to_surface(RenWindow *ren) {
  SDL_SetSurfaceClipRect(renwin_get_surface(ren).surface, NULL);
}


void renwin_set_clip_rect(RenWindow *ren, RenRect rect) {
  RenSurface rs = renwin_get_surface(ren);
  RenRect sr = scaled_rect(rect, rs.scale);
  SDL_SetSurfaceClipRect(rs.surface, &(SDL_Rect){.x = sr.x, .y = sr.y, .w = sr.width, .h = sr.height});
}


RenSurface renwin_get_surface(RenWindow *ren) {
  return ren->rensurface;
}

void renwin_resize_surface(RenWindow *ren) {
  SDL_Log("********* renwin_resize_surface\n");
  int new_w, new_h, new_scale;
  SDL_GetWindowSizeInPixels(ren->window, &new_w, &new_h);
  new_scale = query_surface_scale(ren);
  SDL_Log("********* renwin_resize_surface new_scale %d \n", new_scale);
  /* Note that (w, h) may differ from (new_w, new_h) on retina displays. */
  if (new_scale != ren->rensurface.scale ||
      new_w != ren->rensurface.surface->w ||
      new_h != ren->rensurface.surface->h) {
    renwin_init_surface(ren);
    renwin_clip_to_surface(ren);
    setup_renderer(ren, new_w, new_h);
  }
}

void renwin_update_scale(RenWindow *ren) {
}

void renwin_show_window(RenWindow *ren) {
  SDL_ShowWindow(ren->window);
}

void renwin_update_rects(RenWindow *ren, RenRect *rects, int count) {
  // fprintf(stderr, "********* renwin_update_rects\n");
  const int scale = ren->rensurface.scale;
  for (int i = 0; i < count; i++) {
    const RenRect *r = &rects[i];
    const int x = scale * r->x, y = scale * r->y;
    const int w = scale * r->width, h = scale * r->height;
    const SDL_Rect sr = {.x = x, .y = y, .w = w, .h = h};
    int32_t *pixels = ((int32_t *) ren->rensurface.surface->pixels) + x + ren->rensurface.surface->w * y;
    SDL_UpdateTexture(ren->texture, &sr, pixels, ren->rensurface.surface->w * 4);
  }
  // SDL_RenderCopy(ren->renderer, ren->texture, NULL, NULL);
  SDL_RenderTexture(ren->renderer, ren->texture, NULL, NULL);
  SDL_RenderPresent(ren->renderer);
}

void renwin_free(RenWindow *ren) {
  SDL_DestroyTexture(ren->texture);
  SDL_DestroyRenderer(ren->renderer);
  SDL_DestroySurface(ren->rensurface.surface);
}
