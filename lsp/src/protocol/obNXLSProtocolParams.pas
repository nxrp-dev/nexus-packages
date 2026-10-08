(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSProtocolParams;

{$mode objfpc}{$H+}

interface

uses
  fpjson,
  obNXJSONValues,
  obNXJSONRPCObjects,
  obNXLSProtocolBase;

type
  TNXLSMarkupContent = class(TNXJSONObject)
  private
    Fkind: TNXJSONString;
    Fvalue: TNXJSONString;
  published
    property kind: TNXJSONString read Fkind write Fkind;
    property value: TNXJSONString read Fvalue write Fvalue;
  end;

  TNXLSMarkupContentValue = class(TNXJSONRPCVariant)
  protected
    class function SupportedValueClasses: TNXJSONRPCValueClassArray; override;
  end;

  TNXLSParameterInformationLabelValue = class(TNXJSONRPCVariant)
  protected
    class function ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass; override;
    class function SupportedValueClasses: TNXJSONRPCValueClassArray; override;
  end;

  TNXLSInlayHintLabelValue = class(TNXJSONRPCVariant)
  protected
    class function ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass; override;
    class function SupportedValueClasses: TNXJSONRPCValueClassArray; override;
  end;

  TNXLSCompletionItemTextEditValue = class(TNXJSONRPCVariant)
  protected
    class function ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass; override;
    class function SupportedValueClasses: TNXJSONRPCValueClassArray; override;
  end;

  TNXLSWorkspaceSymbolLocationValue = class(TNXJSONRPCVariant)
  protected
    class function ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass; override;
    class function SupportedValueClasses: TNXJSONRPCValueClassArray; override;
  end;

  TNXLSRequestIDValue = class(TNXJSONRPCVariant)
  end;

  TNXLSProgressToken = class(TNXJSONRPCVariant)
  end;

  TNXLSDiagnosticCodeValue = class(TNXJSONRPCVariant)
  end;

  TNXLSCompletionContext = class;
  TNXLSSignatureHelpContext = class;
  TNXLSInlineValueContext = class;
  TNXLSWorkspaceEdit = class;
  TNXLSInlayHintLabelPart = class;
  TNXLSMessageActionItemArray = class;
  TNXLSCompletionItemLabelDetails = class;
  TNXLSCodeActionDisabled = class;
  TNXLSTextEdit = class;
  TNXLSInsertReplaceEdit = class;
  TNXLSWorkspaceSymbolLocation = class;

  TNXJSONStringArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXJSONIntegerArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSPositionArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSTextDocumentItemArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSTextDocumentIdentifierArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSClientInfo = class(TNXJSONObject)
  private
    Fname: TNXJSONString;
    Fversion: TNXJSONString;
  published
    property name: TNXJSONString read Fname write Fname;
    property version: TNXJSONString read Fversion write Fversion;
  end;

  TNXLSWorkspaceFolder = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
    Fname: TNXJSONString;
  published
    property uri: TNXJSONString read Furi write Furi;
    property name: TNXJSONString read Fname write Fname;
  end;

  TNXLSWorkspaceFolderArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSClientCapabilities = class(TNXJSONObject)
  private
    Fworkspace: TNXJSONObject;
    FtextDocument: TNXJSONObject;
    FnotebookDocument: TNXJSONObject;
    Fwindow: TNXJSONObject;
    Fgeneral: TNXJSONObject;
    Fexperimental: TNXJSONRPCUnknown;
  published
    property workspace: TNXJSONObject read Fworkspace write Fworkspace;
    property textDocument: TNXJSONObject read FtextDocument write FtextDocument;
    property notebookDocument: TNXJSONObject read FnotebookDocument write FnotebookDocument;
    property window: TNXJSONObject read Fwindow write Fwindow;
    property general: TNXJSONObject read Fgeneral write Fgeneral;
    property experimental: TNXJSONRPCUnknown read Fexperimental write Fexperimental;
  end;

  TNXLSInitializeParams = class(TNXJSONRPCObjectParams)
  private
    FprocessId: TNXJSONInteger;
    FclientInfo: TNXLSClientInfo;
    Flocale: TNXJSONString;
    FrootPath: TNXJSONString;
    FrootUri: TNXJSONString;
    FinitializationOptions: TNXJSONRPCUnknown;
    Fcapabilities: TNXLSClientCapabilities;
    Ftrace: TNXJSONString;
    FworkspaceFolders: TNXLSWorkspaceFolderArray;
  public
    constructor Create; override;
  published
    property processId: TNXJSONInteger read FprocessId write FprocessId;
    property clientInfo: TNXLSClientInfo read FclientInfo write FclientInfo;
    property locale: TNXJSONString read Flocale write Flocale;
    property rootPath: TNXJSONString read FrootPath write FrootPath;
    property rootUri: TNXJSONString read FrootUri write FrootUri;
    property initializationOptions: TNXJSONRPCUnknown read FinitializationOptions write FinitializationOptions;
    property capabilities: TNXLSClientCapabilities read Fcapabilities write Fcapabilities;
    property trace: TNXJSONString read Ftrace write Ftrace;
    property workspaceFolders: TNXLSWorkspaceFolderArray read FworkspaceFolders write FworkspaceFolders;
  end;

  TNXLSInitializedParams = class(TNXJSONRPCObjectParams)
  end;

  TNXLSCancelParams = class(TNXJSONRPCObjectParams)
  private
    Fid: TNXLSRequestIDValue;
  published
    property id: TNXLSRequestIDValue read Fid write Fid;
  end;

  TNXLSProgressParams = class(TNXJSONRPCObjectParams)
  private
    Ftoken: TNXLSProgressToken;
    Fvalue: TNXJSONRPCUnknown;
  published
    property token: TNXLSProgressToken read Ftoken write Ftoken;
    property value: TNXJSONRPCUnknown read Fvalue write Fvalue;
  end;

  TNXLSSetTraceParams = class(TNXJSONRPCObjectParams)
  private
    Fvalue: TNXJSONString;
  published
    property value: TNXJSONString read Fvalue write Fvalue;
  end;

  TNXLSLogTraceParams = class(TNXJSONRPCObjectParams)
  private
    Fmessage: TNXJSONString;
    Fverbose: TNXJSONString;
  published
    property message: TNXJSONString read Fmessage write Fmessage;
    property verbose: TNXJSONString read Fverbose write Fverbose;
  end;

  TNXLSFormattingOptions = class(TNXJSONObject)
  private
    FtabSize: TNXJSONInteger;
    FinsertSpaces: TNXJSONBoolean;
    FtrimTrailingWhitespace: TNXJSONBoolean;
    FinsertFinalNewline: TNXJSONBoolean;
    FtrimFinalNewlines: TNXJSONBoolean;
  published
    property tabSize: TNXJSONInteger read FtabSize write FtabSize;
    property insertSpaces: TNXJSONBoolean read FinsertSpaces write FinsertSpaces;
    property trimTrailingWhitespace: TNXJSONBoolean read FtrimTrailingWhitespace write FtrimTrailingWhitespace;
    property insertFinalNewline: TNXJSONBoolean read FinsertFinalNewline write FinsertFinalNewline;
    property trimFinalNewlines: TNXJSONBoolean read FtrimFinalNewlines write FtrimFinalNewlines;
  end;

  TNXLSDocumentFormattingParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
    Foptions: TNXLSFormattingOptions;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
    property options: TNXLSFormattingOptions read Foptions write Foptions;
  end;

  TNXLSDocumentRangeFormattingParams = class(TNXLSDocumentFormattingParams)
  private
    Frange: TNXLSRange;
  published
    property range: TNXLSRange read Frange write Frange;
  end;

  TNXLSDocumentOnTypeFormattingParams = class(TNXLSTextDocumentPositionParams)
  private
    Fch: TNXJSONString;
    Foptions: TNXLSFormattingOptions;
  published
    property ch: TNXJSONString read Fch write Fch;
    property options: TNXLSFormattingOptions read Foptions write Foptions;
  end;

  TNXLSReferenceContext = class(TNXJSONObject)
  private
    FincludeDeclaration: TNXJSONBoolean;
  published
    property includeDeclaration: TNXJSONBoolean read FincludeDeclaration write FincludeDeclaration;
  end;

  TNXLSReferenceParams = class(TNXLSTextDocumentPositionParams)
  private
    Fcontext: TNXLSReferenceContext;
  published
    property context: TNXLSReferenceContext read Fcontext write Fcontext;
  end;

  TNXLSCommand = class(TNXJSONObject)
  private
    Ftitle: TNXJSONString;
    Fcommand: TNXJSONString;
    Farguments: TNXJSONArray;
  published
    property title: TNXJSONString read Ftitle write Ftitle;
    property command: TNXJSONString read Fcommand write Fcommand;
    property arguments: TNXJSONArray read Farguments write Farguments;
  end;

  TNXLSCallHierarchyItem = class(TNXJSONObject)
  private
    Fname: TNXJSONString;
    Fkind: TNXJSONInteger;
    Ftags: TNXJSONIntegerArray;
    Fdetail: TNXJSONString;
    Furi: TNXJSONString;
    Frange: TNXLSRange;
    FselectionRange: TNXLSRange;
    Fdata: TNXJSONRPCUnknown;
  published
    property name: TNXJSONString read Fname write Fname;
    property kind: TNXJSONInteger read Fkind write Fkind;
    property tags: TNXJSONIntegerArray read Ftags write Ftags;
    property detail: TNXJSONString read Fdetail write Fdetail;
    property uri: TNXJSONString read Furi write Furi;
    property range: TNXLSRange read Frange write Frange;
    property selectionRange: TNXLSRange read FselectionRange write FselectionRange;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXLSTypeHierarchyItem = class(TNXJSONObject)
  private
    Fname: TNXJSONString;
    Fkind: TNXJSONInteger;
    Ftags: TNXJSONIntegerArray;
    Fdetail: TNXJSONString;
    Furi: TNXJSONString;
    Frange: TNXLSRange;
    FselectionRange: TNXLSRange;
    Fdata: TNXJSONRPCUnknown;
  published
    property name: TNXJSONString read Fname write Fname;
    property kind: TNXJSONInteger read Fkind write Fkind;
    property tags: TNXJSONIntegerArray read Ftags write Ftags;
    property detail: TNXJSONString read Fdetail write Fdetail;
    property uri: TNXJSONString read Furi write Furi;
    property range: TNXLSRange read Frange write Frange;
    property selectionRange: TNXLSRange read FselectionRange write FselectionRange;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXLSCallHierarchyIncomingCallsParams = class(TNXJSONRPCObjectParams)
  private
    Fitem: TNXLSCallHierarchyItem;
  published
    property item: TNXLSCallHierarchyItem read Fitem write Fitem;
  end;

  TNXLSCallHierarchyOutgoingCallsParams = class(TNXJSONRPCObjectParams)
  private
    Fitem: TNXLSCallHierarchyItem;
  published
    property item: TNXLSCallHierarchyItem read Fitem write Fitem;
  end;

  TNXLSTypeHierarchySupertypesParams = class(TNXJSONRPCObjectParams)
  private
    Fitem: TNXLSTypeHierarchyItem;
  published
    property item: TNXLSTypeHierarchyItem read Fitem write Fitem;
  end;

  TNXLSTypeHierarchySubtypesParams = class(TNXJSONRPCObjectParams)
  private
    Fitem: TNXLSTypeHierarchyItem;
  published
    property item: TNXLSTypeHierarchyItem read Fitem write Fitem;
  end;

  TNXLSDocumentLinkParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
  end;

  TNXLSCodeLensParams = class(TNXLSDocumentLinkParams)
  end;

  TNXLSFoldingRangeParams = class(TNXLSDocumentLinkParams)
  end;

  TNXLSDocumentSymbolParams = class(TNXLSDocumentLinkParams)
  end;

  TNXLSSemanticTokensParams = class(TNXLSDocumentLinkParams)
  end;

  TNXLSSemanticTokensDeltaParams = class(TNXLSSemanticTokensParams)
  private
    FpreviousResultId: TNXJSONString;
  published
    property previousResultId: TNXJSONString read FpreviousResultId write FpreviousResultId;
  end;

  TNXLSSemanticTokensRangeParams = class(TNXLSSemanticTokensParams)
  private
    Frange: TNXLSRange;
  published
    property range: TNXLSRange read Frange write Frange;
  end;

  TNXLSSelectionRangeParams = class(TNXLSDocumentLinkParams)
  private
    Fpositions: TNXLSPositionArray;
  published
    property positions: TNXLSPositionArray read Fpositions write Fpositions;
  end;

  TNXLSDiagnosticCodeDescription = class(TNXJSONObject)
  private
    Fhref: TNXJSONString;
  published
    property href: TNXJSONString read Fhref write Fhref;
  end;

  TNXLSDiagnosticRelatedInformation = class(TNXJSONObject)
  private
    Flocation: TNXLSLocation;
    Fmessage: TNXJSONString;
  published
    property location: TNXLSLocation read Flocation write Flocation;
    property message: TNXJSONString read Fmessage write Fmessage;
  end;

  TNXLSDiagnosticRelatedInformationArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSDiagnostic = class(TNXJSONObject)
  private
    Frange: TNXLSRange;
    Fseverity: TNXJSONInteger;
    Fcode: TNXLSDiagnosticCodeValue;
    FcodeDescription: TNXLSDiagnosticCodeDescription;
    Fsource: TNXJSONString;
    Fmessage: TNXJSONString;
    Ftags: TNXJSONIntegerArray;
    FrelatedInformation: TNXLSDiagnosticRelatedInformationArray;
    Fdata: TNXJSONRPCUnknown;
  published
    property range: TNXLSRange read Frange write Frange;
    property severity: TNXJSONInteger read Fseverity write Fseverity;
    property code: TNXLSDiagnosticCodeValue read Fcode write Fcode;
    property codeDescription: TNXLSDiagnosticCodeDescription read FcodeDescription write FcodeDescription;
    property source: TNXJSONString read Fsource write Fsource;
    property message: TNXJSONString read Fmessage write Fmessage;
    property tags: TNXJSONIntegerArray read Ftags write Ftags;
    property relatedInformation: TNXLSDiagnosticRelatedInformationArray read FrelatedInformation write FrelatedInformation;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXLSDiagnosticArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSCodeActionContext = class(TNXJSONObject)
  private
    Fdiagnostics: TNXLSDiagnosticArray;
    Fonly: TNXJSONStringArray;
    FtriggerKind: TNXJSONInteger;
  published
    property diagnostics: TNXLSDiagnosticArray read Fdiagnostics write Fdiagnostics;
    property only: TNXJSONStringArray read Fonly write Fonly;
    property triggerKind: TNXJSONInteger read FtriggerKind write FtriggerKind;
  end;

  TNXLSCodeActionParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
    Frange: TNXLSRange;
    Fcontext: TNXLSCodeActionContext;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
    property range: TNXLSRange read Frange write Frange;
    property context: TNXLSCodeActionContext read Fcontext write Fcontext;
  end;

  TNXLSDocumentColorParams = class(TNXLSDocumentLinkParams)
  end;

  TNXLSColor = class(TNXJSONObject)
  private
    Fred: TNXJSONFloat;
    Fgreen: TNXJSONFloat;
    Fblue: TNXJSONFloat;
    Falpha: TNXJSONFloat;
  published
    property red: TNXJSONFloat read Fred write Fred;
    property green: TNXJSONFloat read Fgreen write Fgreen;
    property blue: TNXJSONFloat read Fblue write Fblue;
    property alpha: TNXJSONFloat read Falpha write Falpha;
  end;

  TNXLSColorPresentationParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
    Fcolor: TNXLSColor;
    Frange: TNXLSRange;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
    property color: TNXLSColor read Fcolor write Fcolor;
    property range: TNXLSRange read Frange write Frange;
  end;

  TNXLSCompletionParams = class(TNXLSTextDocumentPositionParams)
  private
    Fcontext: TNXLSCompletionContext;
  published
    property context: TNXLSCompletionContext read Fcontext write Fcontext;
  end;

  TNXLSCompletionContext = class(TNXJSONObject)
  private
    FtriggerKind: TNXJSONInteger;
    FtriggerCharacter: TNXJSONString;
  published
    property triggerKind: TNXJSONInteger read FtriggerKind write FtriggerKind;
    property triggerCharacter: TNXJSONString read FtriggerCharacter write FtriggerCharacter;
  end;

  TNXLSParameterInformation = class(TNXJSONObject)
  private
    FLabel: TNXLSParameterInformationLabelValue;
    Fdocumentation: TNXLSMarkupContentValue;
  published
    property &label: TNXLSParameterInformationLabelValue read FLabel write FLabel;
    property documentation: TNXLSMarkupContentValue read Fdocumentation write Fdocumentation;
  end;

  TNXLSParameterInformationArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSSignatureInformation = class(TNXJSONObject)
  private
    FLabel: TNXJSONString;
    Fdocumentation: TNXLSMarkupContentValue;
    Fparameters: TNXLSParameterInformationArray;
    FactiveParameter: TNXJSONInteger;
  published
    property &label: TNXJSONString read FLabel write FLabel;
    property documentation: TNXLSMarkupContentValue read Fdocumentation write Fdocumentation;
    property parameters: TNXLSParameterInformationArray read Fparameters write Fparameters;
    property activeParameter: TNXJSONInteger read FactiveParameter write FactiveParameter;
  end;

  TNXLSSignatureInformationArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSSignatureHelp = class(TNXJSONObject)
  private
    Fsignatures: TNXLSSignatureInformationArray;
    FactiveSignature: TNXJSONInteger;
    FactiveParameter: TNXJSONInteger;
  published
    property signatures: TNXLSSignatureInformationArray read Fsignatures write Fsignatures;
    property activeSignature: TNXJSONInteger read FactiveSignature write FactiveSignature;
    property activeParameter: TNXJSONInteger read FactiveParameter write FactiveParameter;
  end;

  TNXLSSignatureHelpContext = class(TNXJSONObject)
  private
    FtriggerKind: TNXJSONInteger;
    FtriggerCharacter: TNXJSONString;
    FisRetrigger: TNXJSONBoolean;
    FactiveSignatureHelp: TNXLSSignatureHelp;
  published
    property triggerKind: TNXJSONInteger read FtriggerKind write FtriggerKind;
    property triggerCharacter: TNXJSONString read FtriggerCharacter write FtriggerCharacter;
    property isRetrigger: TNXJSONBoolean read FisRetrigger write FisRetrigger;
    property activeSignatureHelp: TNXLSSignatureHelp read FactiveSignatureHelp write FactiveSignatureHelp;
  end;

  TNXLSSignatureHelpParams = class(TNXLSTextDocumentPositionParams)
  private
    Fcontext: TNXLSSignatureHelpContext;
  published
    property context: TNXLSSignatureHelpContext read Fcontext write Fcontext;
  end;

  TNXLSWorkspaceSymbolParams = class(TNXJSONRPCObjectParams)
  private
    Fquery: TNXJSONString;
  published
    property query: TNXJSONString read Fquery write Fquery;
  end;

  TNXLSConfigurationItem = class(TNXJSONObject)
  private
    FscopeUri: TNXJSONString;
    Fsection: TNXJSONString;
  published
    property scopeUri: TNXJSONString read FscopeUri write FscopeUri;
    property section: TNXJSONString read Fsection write Fsection;
  end;

  TNXLSConfigurationItemArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSConfigurationParams = class(TNXJSONRPCObjectParams)
  private
    Fitems: TNXLSConfigurationItemArray;
  published
    property items: TNXLSConfigurationItemArray read Fitems write Fitems;
  end;

  TNXLSDidChangeConfigurationParams = class(TNXJSONRPCObjectParams)
  private
    Fsettings: TNXJSONRPCUnknown;
  published
    property settings: TNXJSONRPCUnknown read Fsettings write Fsettings;
  end;

  TNXLSRegistration = class(TNXJSONObject)
  private
    Fid: TNXJSONString;
    Fmethod: TNXJSONString;
    FregisterOptions: TNXJSONRPCUnknown;
  published
    property id: TNXJSONString read Fid write Fid;
    property method: TNXJSONString read Fmethod write Fmethod;
    property registerOptions: TNXJSONRPCUnknown read FregisterOptions write FregisterOptions;
  end;

  TNXLSRegistrationArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSRegistrationParams = class(TNXJSONRPCObjectParams)
  private
    Fregistrations: TNXLSRegistrationArray;
  published
    property registrations: TNXLSRegistrationArray read Fregistrations write Fregistrations;
  end;

  TNXLSUnregistration = class(TNXJSONObject)
  private
    Fid: TNXJSONString;
    Fmethod: TNXJSONString;
  published
    property id: TNXJSONString read Fid write Fid;
    property method: TNXJSONString read Fmethod write Fmethod;
  end;

  TNXLSUnregistrationArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSUnregistrationParams = class(TNXJSONRPCObjectParams)
  private
    Funregisterations: TNXLSUnregistrationArray;
  published
    property unregisterations: TNXLSUnregistrationArray read Funregisterations write Funregisterations;
  end;

  TNXLSFileCreate = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
  published
    property uri: TNXJSONString read Furi write Furi;
  end;

  TNXLSFileCreateArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSCreateFilesParams = class(TNXJSONRPCObjectParams)
  private
    Ffiles: TNXLSFileCreateArray;
  published
    property files: TNXLSFileCreateArray read Ffiles write Ffiles;
  end;

  TNXLSFileRename = class(TNXJSONObject)
  private
    FoldUri: TNXJSONString;
    FnewUri: TNXJSONString;
  published
    property oldUri: TNXJSONString read FoldUri write FoldUri;
    property newUri: TNXJSONString read FnewUri write FnewUri;
  end;

  TNXLSFileRenameArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSRenameFilesParams = class(TNXJSONRPCObjectParams)
  private
    Ffiles: TNXLSFileRenameArray;
  published
    property files: TNXLSFileRenameArray read Ffiles write Ffiles;
  end;

  TNXLSFileDelete = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
  published
    property uri: TNXJSONString read Furi write Furi;
  end;

  TNXLSFileDeleteArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSDeleteFilesParams = class(TNXJSONRPCObjectParams)
  private
    Ffiles: TNXLSFileDeleteArray;
  published
    property files: TNXLSFileDeleteArray read Ffiles write Ffiles;
  end;

  TNXLSFileEvent = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
    FType: TNXJSONInteger;
  published
    property uri: TNXJSONString read Furi write Furi;
    property &type: TNXJSONInteger read FType write FType;
  end;

  TNXLSFileEventArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSDidChangeWatchedFilesParams = class(TNXJSONRPCObjectParams)
  private
    Fchanges: TNXLSFileEventArray;
  published
    property changes: TNXLSFileEventArray read Fchanges write Fchanges;
  end;

  TNXLSInlayHintParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
    Frange: TNXLSRange;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
    property range: TNXLSRange read Frange write Frange;
  end;

  TNXLSInlineValueParams = class(TNXLSInlayHintParams)
  private
    Fcontext: TNXLSInlineValueContext;
  published
    property context: TNXLSInlineValueContext read Fcontext write Fcontext;
  end;

  TNXLSInlineValueContext = class(TNXJSONObject)
  private
    FframeId: TNXJSONInteger;
    FstoppedLocation: TNXLSRange;
  published
    property frameId: TNXJSONInteger read FframeId write FframeId;
    property stoppedLocation: TNXLSRange read FstoppedLocation write FstoppedLocation;
  end;

  TNXLSNotebookDocumentIdentifier = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
  published
    property uri: TNXJSONString read Furi write Furi;
  end;

  TNXLSNotebookCellExecutionSummary = class(TNXJSONObject)
  private
    FexecutionOrder: TNXJSONInteger;
    Fsuccess: TNXJSONBoolean;
  published
    property executionOrder: TNXJSONInteger read FexecutionOrder write FexecutionOrder;
    property success: TNXJSONBoolean read Fsuccess write Fsuccess;
  end;

  TNXLSNotebookCell = class(TNXJSONObject)
  private
    Fkind: TNXJSONInteger;
    Fdocument: TNXJSONString;
    Fmetadata: TNXJSONRPCUnknown;
    FexecutionSummary: TNXLSNotebookCellExecutionSummary;
  published
    property kind: TNXJSONInteger read Fkind write Fkind;
    property document: TNXJSONString read Fdocument write Fdocument;
    property metadata: TNXJSONRPCUnknown read Fmetadata write Fmetadata;
    property executionSummary: TNXLSNotebookCellExecutionSummary read FexecutionSummary write FexecutionSummary;
  end;

  TNXLSNotebookCellArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSNotebookDocument = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
    FnotebookType: TNXJSONString;
    Fversion: TNXJSONInteger;
    Fmetadata: TNXJSONRPCUnknown;
    Fcells: TNXLSNotebookCellArray;
  published
    property uri: TNXJSONString read Furi write Furi;
    property notebookType: TNXJSONString read FnotebookType write FnotebookType;
    property version: TNXJSONInteger read Fversion write Fversion;
    property metadata: TNXJSONRPCUnknown read Fmetadata write Fmetadata;
    property cells: TNXLSNotebookCellArray read Fcells write Fcells;
  end;

  TNXLSVersionedNotebookDocumentIdentifier = class(TNXLSNotebookDocumentIdentifier)
  private
    Fversion: TNXJSONInteger;
  published
    property version: TNXJSONInteger read Fversion write Fversion;
  end;

  TNXLSNotebookDocumentParams = class(TNXJSONRPCObjectParams)
  private
    FnotebookDocument: TNXLSNotebookDocumentIdentifier;
  published
    property notebookDocument: TNXLSNotebookDocumentIdentifier read FnotebookDocument write FnotebookDocument;
  end;

  TNXLSDidOpenNotebookDocumentParams = class(TNXJSONRPCObjectParams)
  private
    FnotebookDocument: TNXLSNotebookDocument;
    FcellTextDocuments: TNXLSTextDocumentItemArray;
  published
    property notebookDocument: TNXLSNotebookDocument read FnotebookDocument write FnotebookDocument;
    property cellTextDocuments: TNXLSTextDocumentItemArray read FcellTextDocuments write FcellTextDocuments;
  end;

  TNXLSNotebookDocumentChangeEvent = class(TNXJSONObject)
  private
    Fmetadata: TNXJSONRPCUnknown;
    Fcells: TNXJSONObject;
  published
    property metadata: TNXJSONRPCUnknown read Fmetadata write Fmetadata;
    property cells: TNXJSONObject read Fcells write Fcells;
  end;

  TNXLSDidChangeNotebookDocumentParams = class(TNXJSONRPCObjectParams)
  private
    FnotebookDocument: TNXLSVersionedNotebookDocumentIdentifier;
    Fchange: TNXLSNotebookDocumentChangeEvent;
  published
    property notebookDocument: TNXLSVersionedNotebookDocumentIdentifier read FnotebookDocument write FnotebookDocument;
    property change: TNXLSNotebookDocumentChangeEvent read Fchange write Fchange;
  end;

  TNXLSDidCloseNotebookDocumentParams = class(TNXLSNotebookDocumentParams)
  private
    FcellTextDocuments: TNXLSTextDocumentIdentifierArray;
  published
    property cellTextDocuments: TNXLSTextDocumentIdentifierArray read FcellTextDocuments write FcellTextDocuments;
  end;

  TNXLSWorkDoneProgressCreateParams = class(TNXJSONRPCObjectParams)
  private
    Ftoken: TNXLSProgressToken;
  published
    property token: TNXLSProgressToken read Ftoken write Ftoken;
  end;

  TNXLSWorkDoneProgressCancelParams = class(TNXJSONRPCObjectParams)
  private
    Ftoken: TNXLSProgressToken;
  published
    property token: TNXLSProgressToken read Ftoken write Ftoken;
  end;

  TNXLSRenameParams = class(TNXLSTextDocumentPositionParams)
  private
    FnewName: TNXJSONString;
  published
    property newName: TNXJSONString read FnewName write FnewName;
  end;

  TNXLSDocumentDiagnosticParams = class(TNXLSDocumentLinkParams)
  private
    Fidentifier: TNXJSONString;
    FpreviousResultId: TNXJSONString;
  published
    property identifier: TNXJSONString read Fidentifier write Fidentifier;
    property previousResultId: TNXJSONString read FpreviousResultId write FpreviousResultId;
  end;

  TNXLSDiagnosticPreviousResultId = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
    Fvalue: TNXJSONString;
  published
    property uri: TNXJSONString read Furi write Furi;
    property value: TNXJSONString read Fvalue write Fvalue;
  end;

  TNXLSDiagnosticPreviousResultIdArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSWorkspaceDiagnosticParams = class(TNXJSONRPCObjectParams)
  private
    Fidentifier: TNXJSONString;
    FpreviousResultIds: TNXLSDiagnosticPreviousResultIdArray;
  published
    property identifier: TNXJSONString read Fidentifier write Fidentifier;
    property previousResultIds: TNXLSDiagnosticPreviousResultIdArray read FpreviousResultIds write FpreviousResultIds;
  end;

  TNXLSPublishDiagnosticsParams = class(TNXJSONRPCObjectParams)
  private
    Furi: TNXJSONString;
    Fversion: TNXJSONInteger;
    Fdiagnostics: TNXLSDiagnosticArray;
  public
    constructor Create; override;
  published
    property uri: TNXJSONString read Furi write Furi;
    property version: TNXJSONInteger read Fversion write Fversion;
    property diagnostics: TNXLSDiagnosticArray read Fdiagnostics write Fdiagnostics;
  end;

  TNXLSWorkspaceFoldersChangeEvent = class(TNXJSONObject)
  private
    Fadded: TNXLSWorkspaceFolderArray;
    Fremoved: TNXLSWorkspaceFolderArray;
  published
    property added: TNXLSWorkspaceFolderArray read Fadded write Fadded;
    property removed: TNXLSWorkspaceFolderArray read Fremoved write Fremoved;
  end;

  TNXLSDidChangeWorkspaceFoldersParams = class(TNXJSONRPCObjectParams)
  private
    Fevent: TNXLSWorkspaceFoldersChangeEvent;
  published
    property event: TNXLSWorkspaceFoldersChangeEvent read Fevent write Fevent;
  end;

  TNXLSApplyWorkspaceEditParams = class(TNXJSONRPCObjectParams)
  private
    FLabel: TNXJSONString;
    Fedit: TNXLSWorkspaceEdit;
  published
    property &label: TNXJSONString read FLabel write FLabel;
    property edit: TNXLSWorkspaceEdit read Fedit write Fedit;
  end;

  TNXLSAnnotatedTextEdit = class(TNXJSONObject)
  private
    Frange: TNXLSRange;
    FnewText: TNXJSONString;
    FannotationId: TNXJSONString;
  published
    property range: TNXLSRange read Frange write Frange;
    property newText: TNXJSONString read FnewText write FnewText;
    property annotationId: TNXJSONString read FannotationId write FannotationId;
  end;

  TNXLSTextEdit = class(TNXJSONObject)
  private
    Frange: TNXLSRange;
    FnewText: TNXJSONString;
  published
    property range: TNXLSRange read Frange write Frange;
    property newText: TNXJSONString read FnewText write FnewText;
  end;

  TNXLSInsertReplaceEdit = class(TNXJSONObject)
  private
    FnewText: TNXJSONString;
    Finsert: TNXLSRange;
    Freplace: TNXLSRange;
  published
    property newText: TNXJSONString read FnewText write FnewText;
    property insert: TNXLSRange read Finsert write Finsert;
    property replace: TNXLSRange read Freplace write Freplace;
  end;

  TNXLSTextEditArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSTextDocumentEdit = class(TNXJSONObject)
  private
    FtextDocument: TNXLSOptionalVersionedTextDocumentIdentifier;
    Fedits: TNXLSTextEditArray;
  published
    property textDocument: TNXLSOptionalVersionedTextDocumentIdentifier read FtextDocument write FtextDocument;
    property edits: TNXLSTextEditArray read Fedits write Fedits;
  end;

  TNXLSTextDocumentEditArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSWorkspaceEdit = class(TNXJSONObject)
  private
    Fchanges: TNXJSONObject;
    FdocumentChanges: TNXLSTextDocumentEditArray;
    FchangeAnnotations: TNXJSONObject;
  published
    property changes: TNXJSONObject read Fchanges write Fchanges;
    property documentChanges: TNXLSTextDocumentEditArray read FdocumentChanges write FdocumentChanges;
    property changeAnnotations: TNXJSONObject read FchangeAnnotations write FchangeAnnotations;
  end;

  TNXLSWorkspaceEditResult = class(TNXLSWorkspaceEdit)
  end;

  TNXLSMessageParams = class(TNXJSONRPCObjectParams)
  private
    FType: TNXJSONInteger;
    Fmessage: TNXJSONString;
  published
    property &type: TNXJSONInteger read FType write FType;
    property message: TNXJSONString read Fmessage write Fmessage;
  end;

  TNXLSShowMessageRequestParams = class(TNXLSMessageParams)
  private
    Factions: TNXLSMessageActionItemArray;
  published
    property actions: TNXLSMessageActionItemArray read FActions write FActions;
  end;

  TNXLSMessageActionItem = class(TNXJSONObject)
  private
    Ftitle: TNXJSONString;
  published
    property title: TNXJSONString read Ftitle write Ftitle;
  end;

  TNXLSMessageActionItemArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSShowDocumentParams = class(TNXJSONRPCObjectParams)
  private
    Furi: TNXJSONString;
    Fexternal: TNXJSONBoolean;
    FtakeFocus: TNXJSONBoolean;
    Fselection: TNXLSRange;
  published
    property uri: TNXJSONString read Furi write Furi;
    property external: TNXJSONBoolean read Fexternal write Fexternal;
    property takeFocus: TNXJSONBoolean read FtakeFocus write FtakeFocus;
    property selection: TNXLSRange read Fselection write Fselection;
  end;

  TNXLSTelemetryEventParams = class(TNXJSONRPCUnknown)
  end;

  TNXLSInlayHintLabelPart = class(TNXJSONObject)
  private
    Fvalue: TNXJSONString;
    Ftooltip: TNXLSMarkupContentValue;
    Flocation: TNXLSLocation;
    Fcommand: TNXLSCommand;
  published
    property value: TNXJSONString read Fvalue write Fvalue;
    property tooltip: TNXLSMarkupContentValue read Ftooltip write Ftooltip;
    property location: TNXLSLocation read Flocation write Flocation;
    property command: TNXLSCommand read Fcommand write Fcommand;
  end;

  TNXLSInlayHintLabelPartArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSDocumentLink = class(TNXJSONRPCObjectParams)
  private
    Frange: TNXLSRange;
    Ftarget: TNXJSONString;
    Ftooltip: TNXJSONString;
    Fdata: TNXJSONRPCUnknown;
  published
    property range: TNXLSRange read Frange write Frange;
    property target: TNXJSONString read Ftarget write Ftarget;
    property tooltip: TNXJSONString read Ftooltip write Ftooltip;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXLSCodeLens = class(TNXJSONRPCObjectParams)
  private
    Frange: TNXLSRange;
    Fcommand: TNXLSCommand;
    Fdata: TNXJSONRPCUnknown;
  published
    property range: TNXLSRange read Frange write Frange;
    property command: TNXLSCommand read Fcommand write Fcommand;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXLSInlayHint = class(TNXJSONRPCObjectParams)
  private
    Fposition: TNXLSPosition;
    FLabel: TNXLSInlayHintLabelValue;
    Fkind: TNXJSONInteger;
    FtextEdits: TNXLSTextEditArray;
    Ftooltip: TNXLSMarkupContentValue;
    FpaddingLeft: TNXJSONBoolean;
    FpaddingRight: TNXJSONBoolean;
    Fdata: TNXJSONRPCUnknown;
  published
    property position: TNXLSPosition read Fposition write Fposition;
    property &label: TNXLSInlayHintLabelValue read FLabel write FLabel;
    property kind: TNXJSONInteger read Fkind write Fkind;
    property textEdits: TNXLSTextEditArray read FtextEdits write FtextEdits;
    property tooltip: TNXLSMarkupContentValue read Ftooltip write Ftooltip;
    property paddingLeft: TNXJSONBoolean read FpaddingLeft write FpaddingLeft;
    property paddingRight: TNXJSONBoolean read FpaddingRight write FpaddingRight;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXLSCompletionItem = class(TNXJSONRPCObjectParams)
  private
    FLabel: TNXJSONString;
    FLabelDetails: TNXLSCompletionItemLabelDetails;
    Fkind: TNXJSONInteger;
    Ftags: TNXJSONIntegerArray;
    Fdetail: TNXJSONString;
    Fdocumentation: TNXLSMarkupContentValue;
    Fdeprecated: TNXJSONBoolean;
    Fpreselect: TNXJSONBoolean;
    FsortText: TNXJSONString;
    FfilterText: TNXJSONString;
    FinsertText: TNXJSONString;
    FinsertTextFormat: TNXJSONInteger;
    FinsertTextMode: TNXJSONInteger;
    FtextEdit: TNXLSCompletionItemTextEditValue;
    FtextEditText: TNXJSONString;
    FadditionalTextEdits: TNXLSTextEditArray;
    FcommitCharacters: TNXJSONStringArray;
    Fcommand: TNXLSCommand;
    Fdata: TNXJSONRPCUnknown;
  published
    property &label: TNXJSONString read FLabel write FLabel;
    property labelDetails: TNXLSCompletionItemLabelDetails read FLabelDetails write FLabelDetails;
    property kind: TNXJSONInteger read Fkind write Fkind;
    property tags: TNXJSONIntegerArray read Ftags write Ftags;
    property detail: TNXJSONString read Fdetail write Fdetail;
    property documentation: TNXLSMarkupContentValue read Fdocumentation write Fdocumentation;
    property deprecated: TNXJSONBoolean read Fdeprecated write Fdeprecated;
    property preselect: TNXJSONBoolean read Fpreselect write Fpreselect;
    property sortText: TNXJSONString read FsortText write FsortText;
    property filterText: TNXJSONString read FfilterText write FfilterText;
    property insertText: TNXJSONString read FinsertText write FinsertText;
    property insertTextFormat: TNXJSONInteger read FinsertTextFormat write FinsertTextFormat;
    property insertTextMode: TNXJSONInteger read FinsertTextMode write FinsertTextMode;
    property textEdit: TNXLSCompletionItemTextEditValue read FtextEdit write FtextEdit;
    property textEditText: TNXJSONString read FtextEditText write FtextEditText;
    property additionalTextEdits: TNXLSTextEditArray read FadditionalTextEdits write FadditionalTextEdits;
    property commitCharacters: TNXJSONStringArray read FcommitCharacters write FcommitCharacters;
    property command: TNXLSCommand read Fcommand write Fcommand;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXLSCompletionItemLabelDetails = class(TNXJSONObject)
  private
    Fdetail: TNXJSONString;
    Fdescription: TNXJSONString;
  published
    property detail: TNXJSONString read Fdetail write Fdetail;
    property description: TNXJSONString read Fdescription write Fdescription;
  end;

  TNXLSCodeAction = class(TNXJSONRPCObjectParams)
  private
    Ftitle: TNXJSONString;
    Fkind: TNXJSONString;
    Fdiagnostics: TNXLSDiagnosticArray;
    FisPreferred: TNXJSONBoolean;
    Fdisabled: TNXLSCodeActionDisabled;
    Fedit: TNXLSWorkspaceEdit;
    Fcommand: TNXLSCommand;
    Fdata: TNXJSONRPCUnknown;
  published
    property title: TNXJSONString read Ftitle write Ftitle;
    property kind: TNXJSONString read Fkind write Fkind;
    property diagnostics: TNXLSDiagnosticArray read Fdiagnostics write Fdiagnostics;
    property isPreferred: TNXJSONBoolean read FisPreferred write FisPreferred;
    property disabled: TNXLSCodeActionDisabled read Fdisabled write Fdisabled;
    property edit: TNXLSWorkspaceEdit read Fedit write Fedit;
    property command: TNXLSCommand read Fcommand write Fcommand;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

  TNXLSCodeActionDisabled = class(TNXJSONObject)
  private
    Freason: TNXJSONString;
  published
    property reason: TNXJSONString read Freason write Freason;
  end;

  TNXLSWorkspaceSymbolLocation = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
  published
    property uri: TNXJSONString read Furi write Furi;
  end;

  TNXLSWorkspaceSymbol = class(TNXJSONRPCObjectParams)
  private
    Fname: TNXJSONString;
    Fkind: TNXJSONInteger;
    Ftags: TNXJSONIntegerArray;
    FcontainerName: TNXJSONString;
    Flocation: TNXLSWorkspaceSymbolLocationValue;
    Fdata: TNXJSONRPCUnknown;
  published
    property name: TNXJSONString read Fname write Fname;
    property kind: TNXJSONInteger read Fkind write Fkind;
    property tags: TNXJSONIntegerArray read Ftags write Ftags;
    property containerName: TNXJSONString read FcontainerName write FcontainerName;
    property location: TNXLSWorkspaceSymbolLocationValue read Flocation write Flocation;
    property data: TNXJSONRPCUnknown read Fdata write Fdata;
  end;

implementation

class function TNXLSMarkupContentValue.SupportedValueClasses: TNXJSONRPCValueClassArray;
begin
  Result := nil;
  SetLength(Result, 2);
  Result[0] := TNXJSONString;
  Result[1] := TNXLSMarkupContent;
end;

class function TNXLSParameterInformationLabelValue.SupportedValueClasses: TNXJSONRPCValueClassArray;
begin
  Result := nil;
  SetLength(Result, 2);
  Result[0] := TNXJSONString;
  Result[1] := TNXJSONIntegerArray;
end;

class function TNXLSParameterInformationLabelValue.ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass;
begin
  if (AData <> nil) and (AData.JSONType = jtArray) then
    Result := TNXJSONIntegerArray
  else
    Result := inherited ValueClassForJSON(AData);
end;

class function TNXLSInlayHintLabelValue.SupportedValueClasses: TNXJSONRPCValueClassArray;
begin
  Result := nil;
  SetLength(Result, 2);
  Result[0] := TNXJSONString;
  Result[1] := TNXLSInlayHintLabelPartArray;
end;

class function TNXLSInlayHintLabelValue.ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass;
begin
  if (AData <> nil) and (AData.JSONType = jtArray) then
    Result := TNXLSInlayHintLabelPartArray
  else
    Result := inherited ValueClassForJSON(AData);
end;

class function TNXLSCompletionItemTextEditValue.ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass;
begin
  if (AData is TJSONObject) and
    ((TJSONObject(AData).Find('insert') <> nil) or
     (TJSONObject(AData).Find('replace') <> nil)) then
    Result := TNXLSInsertReplaceEdit
  else if AData is TJSONObject then
    Result := TNXLSTextEdit
  else
    Result := inherited ValueClassForJSON(AData);
end;

class function TNXLSCompletionItemTextEditValue.SupportedValueClasses: TNXJSONRPCValueClassArray;
begin
  Result := nil;
  SetLength(Result, 2);
  Result[0] := TNXLSTextEdit;
  Result[1] := TNXLSInsertReplaceEdit;
end;

class function TNXLSWorkspaceSymbolLocationValue.ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass;
begin
  if (AData is TJSONObject) and (TJSONObject(AData).Find('range') <> nil) then
    Result := TNXLSLocation
  else if AData is TJSONObject then
    Result := TNXLSWorkspaceSymbolLocation
  else
    Result := inherited ValueClassForJSON(AData);
end;

class function TNXLSWorkspaceSymbolLocationValue.SupportedValueClasses: TNXJSONRPCValueClassArray;
begin
  Result := nil;
  SetLength(Result, 2);
  Result[0] := TNXLSLocation;
  Result[1] := TNXLSWorkspaceSymbolLocation;
end;

constructor TNXLSInitializeParams.Create;
begin
  inherited Create;
  processId.AcceptsNull := True;
  rootPath.AcceptsNull := True;
  rootUri.AcceptsNull := True;
end;

constructor TNXLSPublishDiagnosticsParams.Create;
begin
  inherited Create;
  version.AcceptsNull := True;
end;

class function TNXJSONStringArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXJSONString;
end;

class function TNXJSONIntegerArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXJSONInteger;
end;

class function TNXLSPositionArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSPosition;
end;

class function TNXLSTextDocumentItemArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSTextDocumentItem;
end;

class function TNXLSTextDocumentIdentifierArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSTextDocumentIdentifier;
end;

class function TNXLSWorkspaceFolderArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSWorkspaceFolder;
end;

class function TNXLSDiagnosticRelatedInformationArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSDiagnosticRelatedInformation;
end;

class function TNXLSDiagnosticArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSDiagnostic;
end;

class function TNXLSParameterInformationArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSParameterInformation;
end;

class function TNXLSSignatureInformationArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSSignatureInformation;
end;

class function TNXLSConfigurationItemArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSConfigurationItem;
end;

class function TNXLSRegistrationArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSRegistration;
end;

class function TNXLSUnregistrationArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSUnregistration;
end;

class function TNXLSFileCreateArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSFileCreate;
end;

class function TNXLSFileRenameArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSFileRename;
end;

class function TNXLSFileDeleteArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSFileDelete;
end;

class function TNXLSFileEventArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSFileEvent;
end;

class function TNXLSNotebookCellArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSNotebookCell;
end;

class function TNXLSInlayHintLabelPartArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSInlayHintLabelPart;
end;

class function TNXLSDiagnosticPreviousResultIdArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSDiagnosticPreviousResultId;
end;

class function TNXLSTextEditArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSTextEdit;
end;

class function TNXLSTextDocumentEditArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSTextDocumentEdit;
end;

class function TNXLSMessageActionItemArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSMessageActionItem;
end;

end.
