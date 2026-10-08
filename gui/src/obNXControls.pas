(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXControls;

{$mode objfpc}{$H+}

interface

uses
  fpg_button,
  fpg_dialogs,
  fpg_edit,
  fpg_form,
  fpg_label,
  fpg_memo,
  fpg_panel;

type
  TNXButton = class(TfpgButton);
  TNXEditBox = class(TfpgEdit);
  TNXFileDialog = class(TfpgFileDialog);
  TNXForm = class(TfpgForm);
  TNXGroupBox = class(TfpgGroupBox);
  TNXLabel = class(TfpgLabel);
  TNXMemo = class(TfpgMemo);
  TNXPanel = class(TfpgPanel);

implementation

end.
