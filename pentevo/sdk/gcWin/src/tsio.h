#pragma once
__sfr __at 0xFE BORDER;

__sfr __banked __at 0x00AF TS_VCONFIG;
__sfr __banked __at 0x01AF TS_VPAGE;
__sfr __banked __at 0x0FAF TS_BORDER;
__sfr __banked __at 0x10AF TS_PAGE0;
__sfr __banked __at 0x11AF TS_PAGE1;
__sfr __banked __at 0x12AF TS_PAGE2;
__sfr __banked __at 0x13AF TS_PAGE3;

#define TS_VID_256X192      0x00

#define TS_VID_ZX           0x00

void strprn_xy(u16 *str, u8 x, u8 y, u8 color);