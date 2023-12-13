unit Unit1;

{
  * Copyright 2023 Alexey Anisimov mailto:softlight<гав-гав>ya.ru
  *
  * Licensed under the Apache License, Version 2.0 (the "License");
  * you may not use this file except in compliance with the License.
  * You may obtain a copy of the License at
  *
  *      http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS,
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the License.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Mask,
  Vcl.ExtCtrls, System.Actions, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnMan,
  Generics.Defaults, Generics.Collections;

type

  TFileItem = class
  private
    FFileName: string;
    FSize: Integer;
    FMD5: string;
  public
    property FileName: string read FFileName write FFileName;
    property Size: Integer read FSize write FSize;
    property MD5: string read FMD5 write FMD5;

    constructor Create(const AFileName: string; const ASize: Integer; const AMD5: string);
  end;

  TForm1 = class(TForm)
    Panel1: TPanel;
    LabeledEditMasterFolder: TLabeledEdit;
    RichEdit1: TRichEdit;
    LabeledEditWorkFolder: TLabeledEdit;
    ActionManager1: TActionManager;
    ActionBuildIndex: TAction;
    ButtonBuildIndex: TButton;
    ButtonSort: TButton;
    ActionSort: TAction;
    procedure ActionBuildIndexExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ActionSortExecute(Sender: TObject);
  private
    MasterFileIndexList : TList<TFileItem>;
    WorkFileIndexList : TList<TFileItem>;
    Comparer: IComparer<TFileItem>;
    DelFolder: string;

    procedure BuildFileIndex(const AFolder: string; var An: Integer; AList: TList<TFileItem>; const AExceptFolder: string);
    procedure SearchAndDeleteDup(AMasterList: TList<TFileItem>; AWorkList: TList<TFileItem>; var An: Integer);
    function ElapsedTime(const AMsec: Cardinal): string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  IOUtils, IdHash, IdHashMessageDigest, Math;

constructor TFileItem.Create(const AFileName: string; const ASize: Integer; const AMD5: string);
begin
  Self.FFileName := AFileName;
  Self.FSize := ASize;
  Self.FMD5 := AMD5;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := TPath.GetFileNameWithoutExtension(GetModuleName(HInstance));

  Comparer := TDelegatedComparer<TFileItem>.Create(
    function(const Left, Right: TFileItem): Integer
    var
      c1: Integer;
      c2: Integer;
    begin
      Result := 0;
      c1 := CompareText(Left.md5, Right.md5);
      c2 := CompareValue(Left.Size, Right.Size);
      if c1 <> 0 then
        Result := c1;
      if c2 <> 0 then
        Result := c2;
    end);

  MasterFileIndexList := TList<TFileItem>.Create(Comparer);
  WorkFileIndexList := TList<TFileItem>.Create();

  RichEdit1.Clear;

  {$IFDEF Debug}
  LabeledEditMasterFolder.EditText := 'C:\Sort\1-Master\';
  LabeledEditWorkFolder.EditText := 'C:\Sort\2-Work\';
  {$ENDIF}

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MasterFileIndexList.Free;
  WorkFileIndexList.Free;
end;

procedure TForm1.ActionBuildIndexExecute(Sender: TObject);
var
  Start: Cardinal;
  Stop: Cardinal;
  n: Integer;
  s: string;
begin
  if not TDirectory.Exists(LabeledEditMasterFolder.EditText) then
    raise Exception.Create('Master folder is not exists.');

  RichEdit1.Lines.Add(Format('Building index for %s ...', [LabeledEditMasterFolder.EditText]));
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;
  Start := GetTickCount;

  BuildFileIndex(LabeledEditMasterFolder.EditText, n, MasterFileIndexList, '');
  MasterFileIndexList.Sort;

  Screen.Cursor := crDefault;
  Stop := GetTickCount;

  s := Format('Done! Elapsed time: %s. Scanned %u file(s).', [ElapsedTime(Stop - Start), n]);
  RichEdit1.Lines.Add(s);
end;


procedure TForm1.ActionSortExecute(Sender: TObject);
var
  Start: Cardinal;
  Stop: Cardinal;
  n: Integer;
  nd: Integer;
  s: string;
begin
  if not TDirectory.Exists(LabeledEditWorkFolder.EditText) then
    raise Exception.Create('Work folder is not exists.');
  if MasterFileIndexList.Count = 0 then
    raise Exception.Create('File index is empty.');
  DelFolder := IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(LabeledEditWorkFolder.EditText) + 'DEL');

  RichEdit1.Lines.Add('Sorting ...');
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;
  Start := GetTickCount;

  BuildFileIndex(LabeledEditWorkFolder.EditText, n, WorkFileIndexList, DelFolder);
  SearchAndDeleteDup(MasterFileIndexList, WorkFileIndexList, nd);

  Screen.Cursor := crDefault;
  Stop := GetTickCount;

  s := Format('Done! Elapsed time: %s. Processed: %u file(s). Deleted: %u duplicate(s).', [ElapsedTime(Stop - Start), n, nd]);
  RichEdit1.Lines.Add(s);

end;

procedure TForm1.BuildFileIndex(const AFolder: string; var An: Integer; AList: TList<TFileItem>; const AExceptFolder: string);
var
  FileNames: TArray<string>;
  FileName: string;
  FileItem: TFileItem;
  IdMD5: TIdHashMessageDigest5;
  FS: TFileStream;
  md5: string;
begin
  An := 0;
  AList.Clear;
  FileNames := TDirectory.GetFiles(AFolder, '*.*', TSearchOption.soAllDirectories);
  for FileName in FileNames do
  begin
    if (AExceptFolder = '') or (LowerCase(AExceptFolder) <> LowerCase(IncludeTrailingPathDelimiter(TPath.GetDirectoryName(FileName)))) then
    begin
      IdMD5 := TIdHashMessageDigest5.Create;
      FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
      try
        md5 := LowerCase(IdMD5.HashStreamAsHex(FS));
        FileItem := TFileItem.Create(FileName, FS.Size, md5);
        AList.Add(FileItem);
        Inc(An);
      finally
        FS.Free;
        IdMD5.Free;
      end;
    end;
  end;
end;

procedure TForm1.SearchAndDeleteDup(AMasterList: TList<TFileItem>; AWorkList: TList<TFileItem>; var An: Integer);
var
  FileItem: TFileItem;
  i: Integer;
begin
  if not TDirectory.Exists(DelFolder) then
    TDirectory.CreateDirectory(DelFolder);

  An := 0;
  for i := 0 to AWorkList.Count - 1 do
  begin
    FileItem := AWorkList.Items[i];
     if MasterFileIndexList.Contains(FileItem) then
       begin
         RichEdit1.Lines.Add('del: ' + FileItem.FileName);
         TFile.Move(FileItem.FileName, DelFolder + ExtractFileName(FileItem.FileName));
         Inc(An);
       end;
  end;

end;

function TForm1.ElapsedTime(const AMsec: Cardinal): string;
begin
  if AMsec < 1000 then
    Result := Format('%u ms', [AMsec])
  else
    Result := Format('%u sec', [AMsec div 1000]);
end;

end.
