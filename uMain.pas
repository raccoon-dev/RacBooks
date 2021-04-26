unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, VirtualTrees,
  System.ImageList, Vcl.ImgList, System.Actions, Vcl.ActnList, Vcl.Menus,
  dMain, uGlobals, FireDAC.Stan.Param, System.IOUtils, uProgress, System.Character;

type TAllowedFile = record
  Ext: string;
  Image: Integer;
end;
const
  // Images must correspond with ilFiles
  AllowedFiles: array[0..3] of TAllowedFile = (
    (Ext: '';     Image: 0),
    (Ext: 'pdf';  Image: 1),
    (Ext: 'mobi'; Image: 2),
    (Ext: 'epub'; Image: 3)
  );

type
  PNodeFolder = ^TNodeFolder;
  PNodeFile = ^TNodeFile;
  TNodeFolder = record
    Id: Int64;
    Name: string;
    Path: string;
    Comment: string;
    Files: Integer;
  end;
  TNodeFile = record
    Id: Int64;
    Name: string;
    Ext: string;
    Path: string;
    Size: Int64;
    Icon: Integer;
    Comment: string;
  end;

// Disable deprecated warnings from TVirtualStringTree:
// [dcc64 Warning] W1000 Symbol 'TImageIndex' is deprecated: 'Use System.UITypes.TImageIndex'
{$WARN SYMBOL_DEPRECATED OFF}

type
  TfrmMain = class(TForm)
    grpFolders: TGroupBox;
    grpFiles: TGroupBox;
    splFolders: TSplitter;
    vFolders: TVirtualStringTree;
    vFiles: TVirtualStringTree;
    pnlInfo: TPanel;
    edtPath: TButtonedEdit;
    pnlSearch: TPanel;
    edtSearch: TButtonedEdit;
    pmnuFolders: TPopupMenu;
    pmnuFiles: TPopupMenu;
    alMain: TActionList;
    mFolderAdd: TMenuItem;
    mFolderEdit: TMenuItem;
    mFolderDel: TMenuItem;
    actFolderAdd: TAction;
    actFolderEdit: TAction;
    actFolderDel: TAction;
    N1: TMenuItem;
    mFolderScan: TMenuItem;
    actFolderScan: TAction;
    ilMain: TImageList;
    ilFolders: TImageList;
    ilFiles: TImageList;
    actFileOpen: TAction;
    actFileOpenFolder: TAction;
    mFileOpen1: TMenuItem;
    mFileOpenFolder1: TMenuItem;
    tmrSearch: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actFolderAddExecute(Sender: TObject);
    procedure actFolderEditExecute(Sender: TObject);
    procedure actFolderDelExecute(Sender: TObject);
    procedure actFolderScanExecute(Sender: TObject);
    procedure pmnuFoldersPopup(Sender: TObject);
    procedure vFoldersFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vFilesFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vFoldersGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure vFoldersGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
      var HintText: string);
    procedure vFoldersGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: TImageIndex);
    procedure FormShow(Sender: TObject);
    procedure vFoldersChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vFilesGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure vFilesGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: TImageIndex);
    procedure vFilesGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
      var HintText: string);
    procedure vFilesChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure edtPathLeftButtonClick(Sender: TObject);
    procedure edtPathRightButtonClick(Sender: TObject);
    procedure vFilesNodeDblClick(Sender: TBaseVirtualTree;
      const HitInfo: THitInfo);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileOpenFolderExecute(Sender: TObject);
    procedure tmrSearchTimer(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure edtSearchRightButtonClick(Sender: TObject);
    procedure edtSearchLeftButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure edtSearchKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtSearchKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edtPathEnter(Sender: TObject);
    procedure edtPathClick(Sender: TObject);
  private
    { Private declarations }
    FCounterAdd: Integer;
    FCounterSkip: Integer;
    procedure FillFolders;
    procedure FillFiles;
    function GetFileSize(Size: Integer): string;
    procedure ScanFolder(const FolderID: Int64);
    procedure DoScanFolder(const FolderID: Int64; const BaseFolder: string; SubFolder: string);
    procedure ExplodeSearch(const Text: string; Result: TStrings);
    procedure DoSearch(Search: TStrings); overload;
    procedure DoSearch(const Search: string); overload;
    procedure AddFile(const FolderID: Int64; const BaseFolder, SubFolder: string; const FileName: string);
    function IsBook(const FileName: string): Boolean;
    function GetDBFileName(const FileName: string): string;
    function GetDBFileExt(const FileName: string): string;
    function GetDBFileSize(const FilePath: string): Integer;
    function GetDBFileTags(const FileName: string): string;
    function GetDBFileIcon(const DBFileExt: string): Integer;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

const
  COL_DIR_NAME    = 0;
  COL_DIR_COUNTER = 1;
  COL_FIL_NAME = 0;
  COL_FIL_EXT  = 1;
  COL_FIL_SIZE = 2;

type TCharType = (ctOther, ctCharLC, ctCharUC, ctCharDigit);

{$R *.dfm}

procedure TfrmMain.actFileOpenExecute(Sender: TObject);
begin
  if (edtPath.Text <> '') then
    if TFile.Exists(edtPath.Text) then
      TGlobals.Execute(edtPath.Text, False)
    else
      TGlobals.ShowError('Can''t find file "' + edtPath.Text + '"');
end;

procedure TfrmMain.actFileOpenFolderExecute(Sender: TObject);
begin
  if (edtPath.Text <> '') then
    if TFile.Exists(edtPath.Text) then
      TGlobals.Execute(edtPath.Text, True)
    else
      TGlobals.ShowError('Can''t find file "' + edtPath.Text + '"');
end;

procedure TfrmMain.actFolderAddExecute(Sender: TObject);
var
  Folder: string;
  fid: Int64;
begin
  Folder := '';
  if TGlobals.ShowOpenFolder('Select Folder', Folder) then
    with dmMain.CreateQuery do
      try
        SQL.Text := 'INSERT INTO folders (name, path) VALUES (:NAME, :PATH)';
        ParamByName('NAME').AsWideString := ExtractFileName(Folder);
        ParamByName('PATH').AsWideString := Folder;
        ExecSQL;
        fid := dmMain.conMain.GetLastAutoGenValue('');
        dmMain.RefreshFolders;
        FillFolders;
        if TGlobals.ShowQuestionYN('Do you want scan newly added folder?') then
          ScanFolder(fid);
      finally
        Free;
      end;
end;

procedure TfrmMain.actFolderDelExecute(Sender: TObject);
var
  d: PNodeFolder;
  n: PVirtualNode;
begin
  n := vFolders.GetFirstSelected;
  d := vFolders.GetNodeData(n);
  if TGlobals.ShowQuestionYN('This function don''t remove files from harddrive.'#13#10'Are you sure you want delete folder "' + d.Name + '" with all files inside from database?') then
  begin
    with dmMain.CreateQuery do
      try
        SQL.Text := 'DELETE FROM files WHERE folder_id=:ID';
        ParamByName('ID').AsLargeInt := d.Id;
        ExecSQL;
        SQL.Text := 'DELETE FROM folders WHERE id=:ID';
        ParamByName('ID').AsLargeInt := d.Id;
        ExecSQL;
        vFolders.DeleteNode(n);
      finally
        Free;
      end;
  end;
end;

procedure TfrmMain.actFolderEditExecute(Sender: TObject);
var
  d: PNodeFolder;
  NewName: string;
begin
  d := vFolders.GetNodeData(vFolders.GetFirstSelected);
  if Assigned(d) then
  begin
    NewName := d.Name;
    if TGlobals.ShowInput('Edit Folder Name', 'New folder name', NewName) then
      with dmMain.CreateQuery do
        try
          SQL.Text := 'UPDATE folders SET name=:NAME WHERE id=:ID';
          ParamByName('NAME').AsWideString := NewName;
          ParamByName('ID').AsLargeInt     := d.Id;
          ExecSQL;
          d.Name := NewName;
        finally
          Free;
        end;
  end;
end;

procedure TfrmMain.actFolderScanExecute(Sender: TObject);
var
  d: PNodeFile;
begin
  d := vFolders.GetNodeData(vFolders.GetFirstSelected);
  if Assigned(d) then
    ScanFolder(d.Id);
end;

procedure TfrmMain.AddFile(const FolderID: Int64; const BaseFolder, SubFolder,
  FileName: string);
var
  FilePath: string;
  sName, sExt, sTags: string;
  iSize, iIcon: Integer;
begin
  with dmMain.CreateQuery do
    try
      sName := GetDBFileName(FileName);
      sExt  := GetDBFileExt(FileName);
      SQL.Text := 'SELECT * FROM files WHERE folder_id=:FID AND name=:NAME AND ext=:EXT AND path=:PATH';
      ParamByName('FID').AsLargeInt    := FolderID;
      ParamByName('NAME').AsWideString := sName;
      ParamByName('EXT').AsWideString  := sExt;
      ParamByName('PATH').AsWideString := SubFolder;
      Active := True;
      if RecordCount = 0 then
      begin
        FilePath := TPath.Combine(TPath.Combine(BaseFolder, SubFolder), FileName);
        iSize    := GetDBFileSize(FilePath);
        sTags    := GetDBFileTags(FileName);
        iIcon    := GetDBFileIcon(sExt);
        Insert;
        FieldByName('folder_id').AsLargeInt := FolderID;
        FieldByName('name').AsWideString    := sName;
        FieldByName('ext').AsWideString     := sExt;
        FieldByName('path').AsWideString    := SubFolder;
        FieldByName('size').AsInteger       := iSize;
        FieldByName('icon_idx').AsInteger   := iIcon;
        FieldByName('sha').AsString         := '';
        FieldByName('tags').AsWideString    := sTags;
        try
          Post;
          if Assigned(frmProgress) then
          begin
            Inc(FCounterAdd);
            frmProgress.TextBottom := Format('File: %s'#13#10'Files added: %d'#13#10'Files skipped: %d', [FileName, FCounterAdd, FCounterSkip]);
          end;
        except
          on E: Exception do
            TGlobals.ShowError(Format('Error during added new file:'#13#10'File name: "%s.%s"'#13#10'Sub folder: "%s"'#13#10'With message:'#13#10'%s', [sName, sExt, SubFolder, E.Message]));
        end;
      end else
        if Assigned(frmProgress) then
        begin
          Inc(FCounterSkip);
          frmProgress.TextBottom := Format('File: %s'#13#10'Files added: %d'#13#10'Files skipped: %d', [FileName, FCounterAdd, FCounterSkip]);
        end;
    finally
      Free;
    end;
end;

procedure TfrmMain.DoScanFolder(const FolderID: Int64; const BaseFolder: string; SubFolder: string);
var
  sr: TSearchRec;
begin
  if FindFirst(TPath.Combine(TPath.Combine(BaseFolder, SubFolder), '*'), faAnyFile, sr) = 0 then
  begin
    repeat
      if (sr.Name <> '.') and (sr.Name <> '..') then
      begin
        if (sr.Attr and faDirectory) <> 0 then
          DoScanFolder(FolderID, BaseFolder, TPath.Combine(SubFolder, sr.Name))
        else
          if IsBook(sr.Name) then
            AddFile(FolderID, BaseFolder, SubFolder, sr.Name)
      end;
    until (FindNext(sr) <> 0);
    FindClose(sr);
  end;
end;

procedure TfrmMain.DoSearch(const Search: string);
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    ExplodeSearch(Search, sl);
    DoSearch(sl);
  finally
    sl.Free;
  end;
end;

procedure TfrmMain.DoSearch(Search: TStrings);
var
  i: Integer;
  sql, s, sFind: string;
begin
  sql := '';
  if Search.Count > 0 then
    while Search.Count > 0 do
    begin
      sFind := Search[0];
      if Length(sFind) > 3 then
      begin
        s := ' AND ((tags LIKE ''%%;%s;%%'') OR (name LIKE ''%%%s%%'') OR (path LIKE ''%%%s%%''))';
        s := Format(s, [sFind, sFind, sFind]);
      end else
      begin
        s := ' AND ((tags LIKE ''%%;%s;%%''))';
        s := Format(s, [sFind]);
      end;
      sql := sql + #13#10 + s;
      Search.Delete(0);
    end;
  sql := sql + #13#10'ORDER BY name';
  for i := 3 to dmMain.qFiles.SQL.Count - 1 do
    dmMain.qFiles.SQL.Delete(i);
  dmMain.qFiles.SQL.Append(sql);
  dmMain.qFiles.Active := True;
  FillFiles;
end;

procedure TfrmMain.edtPathClick(Sender: TObject);
begin
  edtPath.SelectAll;
end;

procedure TfrmMain.edtPathEnter(Sender: TObject);
begin
  edtPath.SelectAll;
end;

procedure TfrmMain.edtPathLeftButtonClick(Sender: TObject);
begin
  actFileOpenFolder.Execute;
end;

procedure TfrmMain.edtPathRightButtonClick(Sender: TObject);
begin
  actFileOpen.Execute;
end;

procedure TfrmMain.edtSearchChange(Sender: TObject);
begin
  tmrSearch.Enabled := False;
  tmrSearch.Enabled := True;
end;

procedure TfrmMain.edtSearchKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = ';' then
    Key := #0;
end;

procedure TfrmMain.edtSearchKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    vFiles.SetFocus;
end;

procedure TfrmMain.edtSearchLeftButtonClick(Sender: TObject);
begin
  tmrSearch.Enabled := False;
  DoSearch(edtSearch.Text);
end;

procedure TfrmMain.edtSearchRightButtonClick(Sender: TObject);
begin
  edtSearch.Text := '';
end;

procedure TfrmMain.ExplodeSearch(const Text: string; Result: TStrings);
var
  p: Integer;
  sText, s: string;
begin
  sText := Trim(Text);
  p := Pos(' ', sText);
  while p >= Low(string) do
  begin
    s := Copy(sText, Low(string), p - 1);
    Result.Append(s);
    Delete(sText, Low(string), p);
    p := Pos(' ', sText);
  end;
  if sText <> '' then
    Result.Append(sText);
end;

procedure TfrmMain.FillFiles;
var
  d: PNodeFile;
begin
  vFiles.BeginUpdate;
  try
    vFiles.Clear;
    with dmMain.qFiles do
    begin
      First;
      while not Eof do
      begin
        vFiles.RootNodeCount := vFiles.RootNodeCount + 1;
        d         := vFiles.GetNodeData(vFiles.GetLast);
        d.Id      := FieldByName('id').AsLargeInt;
        d.Name    := FieldByName('name').AsWideString;
        d.Ext     := FieldByName('ext').AsWideString;
        d.Path    := FieldByName('path').AsWideString;
        d.Size    := FieldByName('size').AsInteger;
        d.Icon    := FieldByName('icon_idx').AsInteger;
        d.Comment := FieldByName('comment').AsString;
        Next;
      end;
    end;
  finally
    vFiles.EndUpdate;
  end;
end;

procedure TfrmMain.FillFolders;
var
  d: PNodeFolder;
begin
  vFolders.BeginUpdate;
  try
    vFolders.Clear;
    with dmMain.qFolders do
    begin
      First;
      while not Eof do
      begin
        vFolders.RootNodeCount := vFolders.RootNodeCount + 1;
        d         := vFolders.GetNodeData(vFolders.GetLast);
        d.Id      := FieldByName('id').AsLargeInt;
        d.Name    := FieldByName('name').AsWideString;
        d.Path    := FieldByName('path').AsWideString;
        d.Comment := FieldByName('comment').AsString;
        d.Files   := FieldByName('files_nr').AsInteger;
        Next;
      end;
    end;
  finally
    vFolders.EndUpdate;
  end;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  frm: TfrmProgress;
begin
  Screen.Cursor := crHourGlass;
  frm := nil;
  while not dMain.ShaTryLock do
  begin
    if not Assigned(frm) then
    begin
      frm := TfrmProgress.Create(Self);
      frm.Show;
      frm.TextTop := 'Exiting...';
      frm.TextBottom := 'Waiting for the SHA calculation thread to finish...'#13#10'This process may take several seconds.';
    end;
    Application.ProcessMessages;
  end;
  if Assigned(frm) then
    frm.Close;
  Screen.Cursor := crDefault;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  vFolders.NodeDataSize := SizeOf(TNodeFolder);
  vFiles.NodeDataSize   := SizeOf(TNodeFile);
  dmMain := TdmMain.Create(Self);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  dmMain.Free;
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = 70) and (ssCtrl in Shift) and not (ssShift in Shift) and not (ssAlt in Shift) then // Ctrl+f
    edtSearch.SetFocus;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if dmMain.conMain.Connected then
  begin
    dmMain.RefreshFolders;
    FillFolders;
  end else
    Application.Terminate;
end;

function TfrmMain.GetDBFileExt(const FileName: string): string;
begin
  Result := AnsiLowerCase(ExtractFileExt(FileName));
  if (Result <> '') and (Result[Low(string)] = '.') then
    Result := Copy(Result, Low(string) + 1, Length(Result));
end;

function TfrmMain.GetDBFileIcon(const DBFileExt: string): Integer;
var
  i: Integer;
begin
  Result := AllowedFiles[0].Image;
  for i := Low(AllowedFiles) + 1 to High(AllowedFiles) do
    if DBFileExt = AllowedFiles[i].Ext then
    begin
      Result := AllowedFiles[i].Image;
      Break;
    end;
end;

function TfrmMain.GetDBFileName(const FileName: string): string;
begin
  Result := Copy(FileName, Low(string), Length(FileName) - Length(ExtractFileExt(FileName)));
end;

function TfrmMain.GetDBFileSize(const FilePath: string): Integer;
var
  sr: TSearchRec;
begin
  if FindFirst(FilePath, faAnyFile, sr) = 0 then
  begin
    // I assume, will be no documents larger than 2GB
    Result := Integer(sr.Size);
    FindClose(sr);
  end else
    Result := 0;
end;

function TfrmMain.GetDBFileTags(const FileName: string): string;
var
  i: Integer;
  LastCharType, CurCharType: TCharType;
  s: string;
begin
  Result := ';';

  s := '';
  LastCharType := TCharType.ctOther;
  for i := Low(FileName) to High(FileName) do
  begin
    if TCharacter.IsLower(FileName[i]) then
      CurCharType := TCharType.ctCharLC else
    if TCharacter.IsUpper(FileName[i]) then
      CurCharType := TCharType.ctCharUC else
    if TCharacter.IsDigit(FileName[i]) then
      CurCharType := TCharType.ctCharDigit
    else
      CurCharType := TCharType.ctOther;

    if LastCharType <> CurCharType then
    begin
      if LastCharType = TCharType.ctOther then
      begin
        s := s + FileName[i];
      end else
      if (s = '') or ((LastCharType = TCharType.ctCharUC) and (CurCharType = TCharType.ctCharLC)) then
      begin
        s := s + FileName[i];
      end else
      begin
        Result := Result + s + ';';
        s := '';
        if CurCharType <> TCharType.ctOther then
          s := FileName[i];
      end;
    end else
      if CurCharType <> TCharType.ctOther then
        s := s + FileName[i];

    LastCharType := CurCharType;
  end;

  if s <> '' then
    Result := Result + s + ';';

  Result := LowerCase(Result);
end;

function TfrmMain.GetFileSize(Size: Integer): string;
var
  suff: string;
begin
  suff := '[B]';
  if Size >= 1024 then
  begin
    Size := Size div 1024;
    suff := '[kB]';
  end;
  if Size >= 1024 then
  begin
    Size := Size div 1024;
    suff := '[MB]';
  end;
  Result := IntToStr(Size) + ' ' + suff;
end;

function TfrmMain.IsBook(const FileName: string): Boolean;
var
  sExt: string;
  i: Integer;
begin
  Result := False;
  sExt := AnsiLowerCase(ExtractFileExt(FileName));
  if (sExt <> '') and (sExt[Low(string)] = '.') then
    Delete(sExt, Low(string), 1);
  if sExt <> '' then
    for i := Low(AllowedFiles) + 1 to High(AllowedFiles) do
      if AllowedFiles[i].Ext = sExt then
      begin
        Result := True;
        Break;
      end;
end;

procedure TfrmMain.pmnuFoldersPopup(Sender: TObject);
var
  en: Boolean;
begin
  en := Assigned(vFolders.GetNodeData(vFolders.GetFirstSelected));
  actFolderEdit.Enabled := en;
  actFolderDel.Enabled  := en;
  actFolderScan.Enabled := en;
end;

procedure TfrmMain.ScanFolder(const FolderID: Int64);
begin
  with dmMain.CreateQuery do
    try
      Screen.Cursor := crHourGlass;
      frmProgress := TfrmProgress.Create(Self);
      try
        SQL.Text := 'SELECT path FROM folders WHERE id=:ID';
        ParamByName('ID').AsLargeInt := FolderID;
        Active := True;
        if RecordCount > 0 then
        begin
          FCounterAdd := 0;
          FCounterSkip := 0;
          frmProgress.TextTop := 'Scanning folder ' + FieldByName('path').AsString;
          frmProgress.Show;
          DoScanFolder(FolderID, FieldByName('path').AsWideString, '');
        end;
        dmMain.RefreshFolders;
        FillFolders;
      finally
        frmProgress.Close;
        frmProgress := nil;
        Screen.Cursor := crDefault;
      end;
    finally
      Free;
    end;
end;

procedure TfrmMain.tmrSearchTimer(Sender: TObject);
var
  sl: TStringList;
begin
  tmrSearch.Enabled := False;
  sl := TStringList.Create;
  try
    ExplodeSearch(edtSearch.Text, sl);
    DoSearch(sl);
  finally
    sl.Free;
  end;
end;

procedure TfrmMain.vFilesChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  dfi: PNodeFile;
  dfo: PNodeFolder;
begin
  dfo := vFolders.GetNodeData(vFolders.GetFirstSelected);
  if Assigned(dfo) then
  begin
    dfi := Sender.GetNodeData(Node);
    if Assigned(dfi) then
      edtPath.Text := TGlobals.Implode(dfo.Path, dfi.Path, dfi.Name, dfi.Ext);
  end;
end;

procedure TfrmMain.vFilesFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  d: PNodeFile;
begin
  d := Sender.GetNodeData(Node);
  if Assigned(d) then
  begin
    d.Name    := '';
    d.Ext     := '';
    d.Path    := '';
    d.Comment := '';
  end;
end;

procedure TfrmMain.vFilesGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
  var HintText: string);
var
  d: PNodeFile;
begin
  d := Sender.GetNodeData(Node);
  if Assigned(d) then                          
    HintText := d.Name + '.' + d.Ext + #13#10+ d.Path + #13#10 + GetFileSize(d.Size) + #13#10 + d.Comment;
end;

procedure TfrmMain.vFilesGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: TImageIndex);
var
  d: PNodeFile;
begin
  if (Column = 0) and (Kind in [TVTImageKind.ikNormal, TVTImageKind.ikSelected]) then
  begin
    d := Sender.GetNodeData(Node);
    if Assigned(d) then
      ImageIndex := d.Icon;
  end;
end;

procedure TfrmMain.vFilesGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  d: PNodeFile;
begin
  if TextType = TVSTTextType.ttNormal then
  begin
    d := Sender.GetNodeData(Node);
    if Assigned(d) then
      if Column = COL_FIL_NAME then
        CellText := d.Name else
      if Column = COL_FIL_EXT then
        CellText := d.Ext else
      if Column = COL_FIL_SIZE then
        CellText := GetFileSize(d.Size);
  end;
end;

procedure TfrmMain.vFilesNodeDblClick(Sender: TBaseVirtualTree;
  const HitInfo: THitInfo);
begin
  actFileOpen.Execute;
end;

procedure TfrmMain.vFoldersChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  d: PNodeFolder;
begin
  edtPath.Text := '';
  d := Sender.GetNodeData(Node);
  if Assigned(d) then
  begin
    dmMain.RefreshFiles(d.Id);
    FillFiles;
  end;
end;

procedure TfrmMain.vFoldersFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  d: PNodeFolder;
begin
  d := Sender.GetNodeData(Node);
  if Assigned(d) then
  begin
    d.Name    := '';
    d.Path    := '';
    d.Comment := '';
  end;
end;

procedure TfrmMain.vFoldersGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
  var HintText: string);
var
  d: PNodeFolder;
begin
  d := Sender.GetNodeData(Node);
  if Assigned(d) then
    if d.Comment <> '' then
      HintText := d.Path + #13#10 + d.Comment
    else
      HintText := d.Path;
end;

procedure TfrmMain.vFoldersGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: TImageIndex);
begin
  if (Column = 0) and (Kind in [TVTImageKind.ikNormal, TVTImageKind.ikSelected]) then
    ImageIndex := 0;
end;

procedure TfrmMain.vFoldersGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  d: PNodeFolder;
begin
  if TextType = TVSTTextType.ttNormal then
  begin
    d := Sender.GetNodeData(Node);
    if Assigned(d) then
      if Column = COL_DIR_NAME then
        CellText := d.Name else
      if Column = COL_DIR_COUNTER then
        CellText := IntToStr(d.Files);
  end;
end;

{$WARN SYMBOL_DEPRECATED DEFAULT}

end.
