(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

library plugin_sample;

{$mode objfpc}{$H+}

uses
  Lua51,
  Solar2D.Plugin,
  Sample.Plugin;

function PluginOpen(L: Plua_State): Integer; cdecl;
begin
  Result := TSolarPlugin.OpenLibrary(
    L,
    'sample',
    'com.nexus',
    2,
    0,
    TSamplePlugin
  );
end;

exports
  PluginOpen name 'luaopen_plugin_sample';

begin
end.
