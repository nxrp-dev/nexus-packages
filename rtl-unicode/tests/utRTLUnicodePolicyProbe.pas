// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit utRTLUnicodePolicyProbe;
{$mode objfpc}
interface
implementation
initialization
  // Deliberately choose a non-UTF-8 policy before importing the UTF-8 helpers.
  SetMultiByteConversionCodePage(1252);
  SetMultiByteRTLFileSystemCodePage(1252);
end.
