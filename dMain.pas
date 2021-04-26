unit dMain;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet,
  uGlobals, System.IOUtils, FireDAC.Comp.ScriptCommands, FireDAC.Stan.Util,
  FireDAC.Comp.Script, Vcl.ExtCtrls, System.Hash, System.SyncObjs;

type
  TdmMain = class(TDataModule)
    conMain: TFDConnection;
    fdPhysSQLite1: TFDPhysSQLiteDriverLink;
    fdCursor1: TFDGUIxWaitCursor;
    qFolders: TFDQuery;
    qFiles: TFDQuery;
    tmrCalcSha: TTimer;
    qSha: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure conMainAfterConnect(Sender: TObject);
    procedure tmrCalcShaTimer(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    function  CreateDB(const DBPath: string): Boolean;
    procedure OpenDB(const DBPath: string);
    procedure CalcNextSha;
    procedure DoWriteSha(const FileID: Int64; Sha: string);
    procedure DoCalcNextSha(const FileID: Int64; const FilePath: string);
    procedure DoDeleteFile(const FileID: Int64);
  public
    function CreateQuery: TFDQuery;
    procedure RefreshFolders;
    procedure RefreshFiles(FolderID: Int64);
  end;

  procedure ShaLock;
  function  ShaTryLock: boolean;
  procedure ShaUnlock;
      
var
  dmMain: TdmMain;

implementation

var
  CSSha: TCriticalSection;

procedure ShaLock;
begin
  if dmMain.tmrCalcSha.Enabled then
    dmMain.tmrCalcSha.Enabled := False;
  CSSha.Acquire;
end;

function ShaTryLock: boolean;
begin
  Result := CSSha.TryEnter;
end;

procedure ShaUnlock;
begin
  CSSha.Release;
end;
  
{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmMain.CalcNextSha;
begin
  qSha.Active := True;
  if qSha.RecordCount > 0 then
  begin
    tmrCalcSha.Interval := 100;
    DoCalcNextSha(qSha.FieldByName('id').AsLargeInt,
                  TGlobals.Implode(qSha.FieldByName('path_base').AsString,
                                   qSha.FieldByName('path').AsString,
                                   qSha.FieldByName('name').AsString,
                                   qSha.FieldByName('ext').AsString));
  end else
  begin
    tmrCalcSha.Interval := 1000;
    tmrCalcSha.Enabled := True;
  end;
  qSha.Active := False;
end;

procedure TdmMain.conMainAfterConnect(Sender: TObject);
begin
  qFolders.Active    := True;
  qFiles.Active      := True;
  tmrCalcSha.Enabled := True;
end;

function TdmMain.CreateDB(const DBPath: string): Boolean;
var
  con: TFDConnection;
  scr: TFDScript;
  s: TResourceStream;
begin
  con := TFDConnection.Create(nil);
  scr := TFDScript.Create(nil);
  s := TResourceStream.Create(HInstance, 'RES_DB', 'TEXT');
  try
    con.DriverName := 'SQLite';
    con.Params.Database := DBPath;
    con.Params.Values['OpenMode'] := 'CreateUTF16';
    con.Connected := True;
    scr.Connection := con;
    s.Seek(0, soFromBeginning);
    scr.SQLScripts.Add.SQL.LoadFromStream(s);
    Result := scr.ValidateAll and
              scr.ExecuteAll;
  finally
    s.Free;
    scr.Free;
    con.Free;
  end;
end;

function TdmMain.CreateQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := conMain;
end;

procedure TdmMain.DataModuleCreate(Sender: TObject);
var
  fname: string;
begin
  // Open database. Create if necessary.
  fname := TGlobals.GetDBPath;
  if TFile.Exists(fname) then
    OpenDB(fname)
  else
    if CreateDB(fname) then
      OpenDB(fname)
    else
      TGlobals.ShowWarning('Create database error.');
end;

procedure TdmMain.DataModuleDestroy(Sender: TObject);
begin
  tmrCalcSha.Enabled := False;
end;

procedure TdmMain.DoCalcNextSha(const FileID: Int64; const FilePath: string);
begin
  if TFile.Exists(FilePath) then
  begin
    TThread.CreateAnonymousThread(procedure
    var
      sha: string;
    begin
      if not ShaTryLock then
        Exit;
      sha := THashSHA2.GetHashStringFromFile(FilePath, THashSHA2.TSHA2Version.SHA256);
      TThread.Synchronize(TThread.Current, procedure
      begin
        DoWriteSha(FileID, sha);
        tmrCalcSha.Enabled := True;
      end);
      ShaUnlock;
    end).Start;
  end else
  begin
    DoDeleteFile(FileID);
    ShaUnlock;
  end;
end;

procedure TdmMain.DoDeleteFile(const FileID: Int64);
begin
  with CreateQuery do
    try
      SQL.Text := 'DELETE FROM files WHERE id=:ID';
      ParamByName('ID').AsLargeInt := FileID;
      ExecSQL;
    finally
      Free;
    end;
end;

procedure TdmMain.DoWriteSha(const FileID: Int64; Sha: string);
begin
  with CreateQuery do
    try
      SQL.Text := 'UPDATE files SET sha=:SHA WHERE id=:ID';
      ParamByName('SHA').AsString := Sha;
      ParamByName('ID').AsLargeInt := FileID;
      ExecSQL;
    finally
      Free;
    end;
end;

procedure TdmMain.OpenDB(const DBPath: string);
begin
  conMain.Params.Database := DBPath;
  conMain.Connected := True;
end;

procedure TdmMain.RefreshFiles(FolderID: Int64);
begin
  qFiles.Active := False;
  qFiles.ParamByName('ID').AsLargeInt := FolderID;
  qFiles.Active := True;
end;

procedure TdmMain.RefreshFolders;
begin
  if qFolders.Active then
    qFolders.Refresh
  else
    qFolders.Active := True;
end;

procedure TdmMain.tmrCalcShaTimer(Sender: TObject);
begin
  tmrCalcSha.Enabled := False;
  CalcNextSha;
end;

initialization
  CSSha := TCriticalSection.Create;

finalization
  CSSha.Free;

end.
