unit uTestPointLogService;

{$mode objfpc}{$H+}

interface

uses
  Classes, uTestPointLogModel, uResultTypes;

type
  TTestPointLogExportFormat = (tplefCsv, tplefJson);

  TTestPointLogService = class
  private
    FEntries: TList;
    FInvalidLineCount: Integer;
    procedure ClearEntries;
    function CsvValue(const AValue: string): string;
    function EntryAsJson(AEntry: TTestPointLogEntry): string;
    function JsonValueAsText(AObject: TObject; const AName: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromFile(const AFileName: string): TOperationResult;
    function ExportEntries(AEntries: TList; const AFileName: string;
      AFormat: TTestPointLogExportFormat): TOperationResult;
    property Entries: TList read FEntries;
    property InvalidLineCount: Integer read FInvalidLineCount;
  end;

implementation

uses
  fpjson, jsonparser, SysUtils;

constructor TTestPointLogService.Create;
begin
  inherited Create;
  FEntries := TList.Create;
end;

destructor TTestPointLogService.Destroy;
begin
  ClearEntries;
  FEntries.Free;
  inherited Destroy;
end;

procedure TTestPointLogService.ClearEntries;
var
  I: Integer;
begin
  for I := 0 to FEntries.Count - 1 do
    TObject(FEntries[I]).Free;
  FEntries.Clear;
  FInvalidLineCount := 0;
end;

function TTestPointLogService.JsonValueAsText(AObject: TObject;
  const AName: string): string;
var
  Data: TJSONData;
begin
  Result := '';
  if not (AObject is TJSONObject) then
    Exit;
  Data := TJSONObject(AObject).Find(AName);
  if Assigned(Data) and (Data.JSONType <> jtNull) then
  begin
    if Data.JSONType in [jtObject, jtArray] then
      Result := Data.AsJSON
    else
      Result := Data.AsString;
  end;
end;

function TTestPointLogService.LoadFromFile(const AFileName: string): TOperationResult;
var
  Data: TJSONData;
  Entry: TTestPointLogEntry;
  I: Integer;
  Lines: TStringList;
  LineText: string;
  ObjectData: TJSONObject;
begin
  ClearEntries;
  if not FileExists(AFileName) then
    Exit(TOperationResult.Fail('TEST_POINT_LOG_MISSING',
      'The selected Test Point log file does not exist.'));

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);
    for I := 0 to Lines.Count - 1 do
    begin
      LineText := Trim(Lines[I]);
      if LineText = '' then
        Continue;
      Entry := nil;
      try
        Data := GetJSON(LineText);
        try
          if not (Data is TJSONObject) then
          begin
            Inc(FInvalidLineCount);
            Continue;
          end;
          ObjectData := TJSONObject(Data);
          Entry := TTestPointLogEntry.Create;
          Entry.Timestamp := JsonValueAsText(ObjectData, 'timestamp');
          Entry.PointId := JsonValueAsText(ObjectData, 'point_id');
          Entry.Area := JsonValueAsText(ObjectData, 'area');
          Entry.ModuleName := JsonValueAsText(ObjectData, 'module');
          Entry.FolderPath := JsonValueAsText(ObjectData, 'folder_path');
          Entry.FilePath := JsonValueAsText(ObjectData, 'file_path');
          Entry.Status := JsonValueAsText(ObjectData, 'status');
          Entry.DurationMS := StrToInt64Def(JsonValueAsText(ObjectData,
            'duration_ms'), 0);
          Entry.Context := JsonValueAsText(ObjectData, 'context');
          Entry.RequestId := JsonValueAsText(ObjectData, 'request_id');
          Entry.RawJson := LineText;
          FEntries.Add(Entry);
          Entry := nil;
        finally
          Data.Free;
        end;
      except
        on E: Exception do
        begin
          Entry.Free;
          Inc(FInvalidLineCount);
        end;
      end;
    end;
    Result := TOperationResult.Ok('Loaded ' + IntToStr(FEntries.Count) +
      ' Test Point log entries.');
  except
    on E: Exception do
      Result := TOperationResult.Fail('TEST_POINT_LOG_READ_FAILED',
        'Unable to read the Test Point log: ' + E.Message);
  end;
  Lines.Free;
end;

function TTestPointLogService.CsvValue(const AValue: string): string;
var
  Value: string;
begin
  Value := StringReplace(AValue, #13#10, '\n', [rfReplaceAll]);
  Value := StringReplace(Value, #13, '\n', [rfReplaceAll]);
  Value := StringReplace(Value, #10, '\n', [rfReplaceAll]);
  Value := StringReplace(Value, '"', '""', [rfReplaceAll]);
  Result := '"' + Value + '"';
end;

function TTestPointLogService.EntryAsJson(AEntry: TTestPointLogEntry): string;
begin
  Result := AEntry.RawJson;
  if Result = '' then
    Result := '{}';
end;

function TTestPointLogService.ExportEntries(AEntries: TList;
  const AFileName: string; AFormat: TTestPointLogExportFormat): TOperationResult;
var
  Content: TStringList;
  Entry: TTestPointLogEntry;
  I: Integer;
begin
  if not Assigned(AEntries) then
    Exit(TOperationResult.Fail('TEST_POINT_LOG_EXPORT_EMPTY',
      'There are no log entries to export.'));
  try
    Content := TStringList.Create;
    try
      if AFormat = tplefCsv then
      begin
        Content.Add('timestamp,point_id,area,module,folder_path,file_path,status,duration_ms,context,request_id');
        for I := 0 to AEntries.Count - 1 do
        begin
          Entry := TTestPointLogEntry(AEntries[I]);
          Content.Add(CsvValue(Entry.Timestamp) + ',' + CsvValue(Entry.PointId) + ',' +
            CsvValue(Entry.Area) + ',' + CsvValue(Entry.ModuleName) + ',' +
            CsvValue(Entry.FolderPath) + ',' + CsvValue(Entry.FilePath) + ',' +
            CsvValue(Entry.Status) + ',' + IntToStr(Entry.DurationMS) + ',' +
            CsvValue(Entry.Context) + ',' + CsvValue(Entry.RequestId));
        end;
      end
      else
      begin
        Content.Add('[');
        for I := 0 to AEntries.Count - 1 do
        begin
          Entry := TTestPointLogEntry(AEntries[I]);
          if I < AEntries.Count - 1 then
            Content.Add('  ' + EntryAsJson(Entry) + ',')
          else
            Content.Add('  ' + EntryAsJson(Entry));
        end;
        Content.Add(']');
      end;
      Content.SaveToFile(AFileName);
    finally
      Content.Free;
    end;
    Result := TOperationResult.Ok('Exported ' + IntToStr(AEntries.Count) +
      ' Test Point log entries to: ' + AFileName);
  except
    on E: Exception do
      Result := TOperationResult.Fail('TEST_POINT_LOG_EXPORT_FAILED',
        'Unable to export Test Point log entries: ' + E.Message);
  end;
end;

end.
