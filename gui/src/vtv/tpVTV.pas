{ Native fpGUI adaptation of Virtual TreeView 6.0.0.

  The original VirtualTrees.pas was written by Mike Lischke.
  Copyright (c) 1999-2001 digital publishing AG. All Rights Reserved.
  Lazarus port: Luiz Americo Pereira Camara.
  Native fpGUI adaptations: Copyright (c) 2026 Kevin Collins.

  This file is subject to the Mozilla Public License, Version 1.1.
  https://www.mozilla.org/MPL/1.1/
  Alternatively, it may be used under the GNU Lesser General Public License,
  version 2.1 or later, as described in the upstream source.
}

unit tpVTV;

{$mode objfpc}{$H+}

interface

uses
  fpg_base;

type
  TColumnIndex = Integer;
  TSortDirection = (sdAscending, sdDescending);
  TCheckType = (ctNone, ctTriStateCheckBox, ctCheckBox, ctRadioButton, ctButton);
  TCheckState = (csUncheckedNormal, csUncheckedPressed, csCheckedNormal,
    csCheckedPressed, csMixedNormal, csMixedPressed);

  TVirtualNodeState = (vsInitialized, vsChecking, vsCutOrCopy, vsDisabled,
    vsDeleting, vsExpanded, vsHasChildren, vsVisible, vsSelected,
    vsOnFreeNodeCallRequired, vsAllChildrenHidden, vsClearing, vsMultiline,
    vsHeightMeasured, vsToggling, vsFiltered, vsChildrenInitialized);
  TVirtualNodeStates = set of TVirtualNodeState;
  TVirtualNodeInitState = (ivsDisabled, ivsExpanded, ivsHasChildren,
    ivsMultiline, ivsSelected, ivsFiltered, ivsReInit);
  TVirtualNodeInitStates = set of TVirtualNodeInitState;
  TVTNodeAttachMode = (amNoWhere, amInsertBefore, amInsertAfter,
    amAddChildFirst, amAddChildLast);

  PVirtualNode = ^TVirtualNode;
  TVirtualNode = record
    Index, ChildCount: Cardinal;
    NodeHeight: Word;
    States: TVirtualNodeStates;
    CheckState: TCheckState;
    CheckType: TCheckType;
    TotalCount, TotalHeight, VisibleCount: Cardinal;
    Parent, PrevSibling, NextSibling, FirstChild, LastChild: PVirtualNode;
    Data: record end;
  end;
  TNodeArray = array of PVirtualNode;

  TCacheEntry = record
    Node: PVirtualNode;
    AbsoluteTop: Integer;
  end;
  TCache = array of TCacheEntry;

  TVTPaintOption = (toShowButtons, toShowTreeLines, toShowRoot,
    toShowHorzGridLines, toShowVertGridLines, toHideSelection,
    toFullVertGridLines, toHotTrack);
  TVTPaintOptions = set of TVTPaintOption;
  TVTSelectionOption = (toMultiSelect, toFullRowSelect, toRightClickSelect);
  TVTSelectionOptions = set of TVTSelectionOption;
  TVTMiscOption = (toEditable, toReadOnly, toCheckSupport);
  TVTMiscOptions = set of TVTMiscOption;
  TVTAutoOption = (toAutoTristateTracking);
  TVTAutoOptions = set of TVTAutoOption;

  THitPosition = (hiNowhere, hiOnItem, hiOnItemButton, hiOnItemCheckbox,
    hiOnItemLabel, hiOnHeader);
  THitPositions = set of THitPosition;
  THitInfo = record
    HitNode: PVirtualNode;
    HitColumn: TColumnIndex;
    HitPositions: THitPositions;
    HitPoint: TfpgPoint;
  end;

const
  cNoColumn = -1;
  cVTVCacheStride = 128;
  cVTVDefaultNodeHeight = 24;

implementation

end.
