unit uSourceFileService;

{$mode objfpc}{$H+}

interface

uses
  uResultTypes;

type
  TSourceFileResult = class(TOperationResult)
  private
    FContent: string;
    FFilePath: string;
  public
    constructor Create(ASuccess: Boolean; const AMessage: string;
      const AErrorCode: string = ''; const AFilePath: string = '';
      const AContent: string = '');
    property Content: string read FContent;
    property FilePath: string read FFilePath;
  end;

  TSourceFileService = class
  private
    FMaxFileSize: Int64;
    function IsBinaryFile(const AFilePath: string): Boolean;
  public
    constructor Create;
    function LoadTextFile(const AFilePath: string): TSourceFileResult;
    property MaxFileSize: Int64 read FMaxFileSize write FMaxFileSize;
  end;

implementation

uses
  Classes, SysUtils;

constructor TSourceFileResult.Create(ASuccess: Boolean; const AMessage: string;
  const AErrorCode: string; const AFilePath: string; const AContent: string);
begin
  inherited Create(ASuccess, AMessage, AErrorCode);
  FFilePath := AFilePath;
  FContent := AContent;
end;

constructor TSourceFileService.Create;
begin
  inherited Create;
  FMaxFileSize := 5 * 1024 * 1024;
end;

function TSourceFileService.IsBinaryFile(const AFilePath: string): Boolean;
var
  Stream: TFileStream;
  Buffer: array[0..4095] of Byte;
  ReadCount: Integer;
  I: Integer;
begin
  Result := False;
  Stream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
  try
    FillChar(Buffer, SizeOf(Buffer), 0);
    ReadCount := Stream.Read(Buffer, SizeOf(Buffer));
    for I := 0 to ReadCount - 1 do
      if Buffer[I] = 0 then
      begin
        Result := True;
        Exit;
      end;
  finally
    Stream.Free;
  end;
end;

function TSourceFileService.LoadTextFile(const AFilePath: string
  ): TSourceFileResult;
var
  FileText: TStringList;
  Stream: TFileStream;
  Size: Int64;
begin
  if Trim(AFilePath) = '' then
    Exit(TSourceFileResult.Create(False, 'No file path was supplied.',
      'SOURCE_PATH_EMPTY'));

  if not FileExists(AFilePath) then
    Exit(TSourceFileResult.Create(False, 'File not found: ' + AFilePath,
      'SOURCE_FILE_NOT_FOUND', AFilePath));

  try
    Stream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
    try
      Size := Stream.Size;
    finally
      Stream.Free;
    end;

    if (FMaxFileSize > 0) and (Size > FMaxFileSize) then
      Exit(TSourceFileResult.Create(False,
        'File is too large to preview safely: ' + AFilePath,
        'SOURCE_FILE_TOO_LARGE', AFilePath));

    if IsBinaryFile(AFilePath) then
      Exit(TSourceFileResult.Create(False,
        'Binary files cannot be shown in the source viewer: ' + AFilePath,
        'SOURCE_FILE_BINARY', AFilePath));

    FileText := TStringList.Create;
    try
      FileText.LoadFromFile(AFilePath);
      Result := TSourceFileResult.Create(True, 'Source file loaded.',
        '', AFilePath, FileText.Text);
    finally
      FileText.Free;
    end;
  except
    on E: Exception do
      Result := TSourceFileResult.Create(False, E.Message,
        'SOURCE_FILE_LOAD_ERROR', AFilePath);
  end;
end;

end.
