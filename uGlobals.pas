unit uGlobals;

interface

uses
  System.IOUtils, Vcl.Dialogs, Vcl.FileCtrl, System.SysUtils,
  System.UITypes, Winapi.ShellApi, Winapi.Windows;

type TGlobals = class
  public
    class function GetPathWork: string;
    class function GetDBPath: string;
    class procedure ShowWarning(const Text: string);
    class procedure ShowError(const Text: string);
    class function ShowQuestionYN(const Text: string): Boolean;
    class function ShowOpenFolder(const Caption: string; var Folder: string): Boolean;
    class function ShowInput(const Caption, Prompt: string; var Text: string): Boolean;
    class function Implode(const BasePath, Path, Name, Ext: string): string;
    class procedure Execute(const FilePath: string; const SelectInfolder: Boolean = False);
end;

implementation

const
  DIR_WORK = 'RacBooks';
  FILE_DB = 'RacBooks.db';

{ TGlobals }

class procedure TGlobals.Execute(const FilePath: string;
  const SelectInfolder: Boolean);
begin
  if not TFile.Exists(FilePath) then
    Exit;
  if SelectInfolder then
    ShellExecute(0, 'open', 'explorer.exe', PWideChar(Format('/select,"%s"', [FilePath])), nil, SW_SHOW)
  else
    ShellExecute(0, 'open', PWideChar(FilePath), nil, nil, SW_SHOW);
end;

class function TGlobals.GetDBPath: string;
begin
  Result := TPath.Combine(TGlobals.GetPathWork, FILE_DB);
end;

class function TGlobals.GetPathWork: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, DIR_WORK);
  if not TDirectory.Exists(Result) then
    TDirectory.CreateDirectory(Result);
end;

class function TGlobals.Implode(const BasePath, Path, Name,
  Ext: string): string;
begin
  Result := TPath.Combine(BasePath, Path);
  Result := TPath.Combine(Result, Name) + '.' + Ext;
end;

class procedure TGlobals.ShowError(const Text: string);
begin
  MessageDlg(Text, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
end;

class function TGlobals.ShowInput(const Caption, Prompt: string;
  var Text: string): Boolean;
begin
  Result := InputQuery(Caption, Prompt, Text);
end;

class function TGlobals.ShowOpenFolder(const Caption: string;
  var Folder: string): Boolean;
begin
  Result := False;
  if Win32MajorVersion >= 6 then
    with TFileOpenDialog.Create(nil) do
      try
        Title := Caption;
        Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem]; // YMMV
        OkButtonLabel := 'Select';
        DefaultFolder := Folder;
        FileName := Folder;
        if Execute then
        begin
          Folder := FileName;
          Result := True;
        end;
      finally
        Free;
      end
  else
    if SelectDirectory(Caption, ExtractFileDrive(Folder), Folder,
               [sdNewUI, sdNewFolder]) then
    begin
      Folder := Folder;
      Result := True;
    end;
end;

class function TGlobals.ShowQuestionYN(const Text: string): Boolean;
begin
  Result := MessageDlg(Text, TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0) = mrYes;
end;

class procedure TGlobals.ShowWarning(const Text: string);
begin
  MessageDlg(Text, TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], 0);
end;

end.
