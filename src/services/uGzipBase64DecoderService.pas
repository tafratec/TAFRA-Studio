unit uGzipBase64DecoderService;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TGzipBase64DecoderService = class
  private
    function Base64WithoutWhitespace(const AValue: string): string;
    function ExtractEncodedPayload(const AValue: string; out APayload: string;
      out AErrorMessage: string): Boolean;
    function IsValidBase64(const AValue: string): Boolean;
    function GzipPayloadOffset(const AData: string; out AOffset: Integer;
      out AErrorMessage: string): Boolean;
  public
    function TryDecode(const AEncodedText: string; out ADecodedText: string;
      out AErrorMessage: string): Boolean;
  end;

implementation

uses
  Base64, ZStream, fpjson, jsonparser;

function TGzipBase64DecoderService.Base64WithoutWhitespace(
  const AValue: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AValue) do
    if not (AValue[I] in [#9, #10, #13, ' ']) then
      Result := Result + AValue[I];
end;

function TGzipBase64DecoderService.ExtractEncodedPayload(const AValue: string;
  out APayload: string; out AErrorMessage: string): Boolean;
var
  JsonData: TJSONData;
  JsonObject: TJSONObject;
  InputText: string;
begin
  Result := False;
  APayload := AValue;
  AErrorMessage := '';
  InputText := Trim(AValue);
  if (InputText = '') or (InputText[1] <> '{') then
    Exit(True);

  try
    JsonData := GetJSON(InputText);
    try
      if not (JsonData is TJSONObject) then
      begin
        AErrorMessage := 'The JSON input must be an object containing a payload field.';
        Exit;
      end;

      JsonObject := TJSONObject(JsonData);
      if (JsonObject.Find('payload') = nil) or
        (JsonObject.Find('payload').JSONType <> jtString) then
      begin
        AErrorMessage := 'The JSON input does not contain a string payload field.';
        Exit;
      end;

      APayload := JsonObject.Strings['payload'];
      Result := True;
    finally
      JsonData.Free;
    end;
  except
    on E: Exception do
      AErrorMessage := 'The JSON input is invalid: ' + E.Message;
  end;
end;

function TGzipBase64DecoderService.IsValidBase64(const AValue: string): Boolean;
var
  I: Integer;
  PaddingStart: Integer;
begin
  Result := False;
  if (AValue = '') or ((Length(AValue) mod 4) <> 0) then
    Exit;

  PaddingStart := Pos('=', AValue);
  if PaddingStart = 0 then
    PaddingStart := Length(AValue) + 1;

  if (Length(AValue) - PaddingStart + 1) > 2 then
    Exit;

  for I := 1 to Length(AValue) do
    if I < PaddingStart then
    begin
      if not (AValue[I] in ['A'..'Z', 'a'..'z', '0'..'9', '+', '/']) then
        Exit;
    end
    else if AValue[I] <> '=' then
      Exit;

  Result := True;
end;

function TGzipBase64DecoderService.GzipPayloadOffset(const AData: string;
  out AOffset: Integer; out AErrorMessage: string): Boolean;
var
  Flags: Byte;
  ExtraLength: Integer;
begin
  Result := False;
  AOffset := 0;
  AErrorMessage := '';

  if Length(AData) < 18 then
  begin
    AErrorMessage := 'The decoded data is too short to be a gzip stream.';
    Exit;
  end;

  if (Byte(AData[1]) <> $1F) or (Byte(AData[2]) <> $8B) or
    (Byte(AData[3]) <> 8) then
  begin
    AErrorMessage := 'The decoded data is not a gzip stream.';
    Exit;
  end;

  Flags := Byte(AData[4]);
  if (Flags and $E0) <> 0 then
  begin
    AErrorMessage := 'The gzip stream has unsupported header flags.';
    Exit;
  end;

  AOffset := 11;
  if (Flags and $04) <> 0 then
  begin
    if AOffset + 1 > Length(AData) - 8 then
    begin
      AErrorMessage := 'The gzip extra header is incomplete.';
      Exit;
    end;
    ExtraLength := Byte(AData[AOffset]) + (Byte(AData[AOffset + 1]) shl 8);
    Inc(AOffset, 2 + ExtraLength);
  end;

  if (Flags and $08) <> 0 then
    while (AOffset <= Length(AData) - 8) and (AData[AOffset] <> #0) do
      Inc(AOffset);
  if (Flags and $08) <> 0 then
    Inc(AOffset);

  if (Flags and $10) <> 0 then
    while (AOffset <= Length(AData) - 8) and (AData[AOffset] <> #0) do
      Inc(AOffset);
  if (Flags and $10) <> 0 then
    Inc(AOffset);

  if (Flags and $02) <> 0 then
    Inc(AOffset, 2);

  if AOffset > Length(AData) - 8 then
  begin
    AErrorMessage := 'The gzip header is incomplete.';
    Exit;
  end;

  Result := True;
end;

function TGzipBase64DecoderService.TryDecode(const AEncodedText: string;
  out ADecodedText: string; out AErrorMessage: string): Boolean;
var
  Base64Text: string;
  GzipData: string;
  PayloadOffset: Integer;
  CompressedData: TMemoryStream;
  DecompressedData: TMemoryStream;
  DecompressionStream: TDecompressionStream;
begin
  Result := False;
  ADecodedText := '';
  AErrorMessage := '';
  if not ExtractEncodedPayload(AEncodedText, Base64Text, AErrorMessage) then
    Exit;
  Base64Text := Base64WithoutWhitespace(Base64Text);
  if not IsValidBase64(Base64Text) then
  begin
    AErrorMessage := 'Enter valid Base64 text.';
    Exit;
  end;

  try
    GzipData := DecodeStringBase64(Base64Text, True);
    if not GzipPayloadOffset(GzipData, PayloadOffset, AErrorMessage) then
      Exit;

    CompressedData := TMemoryStream.Create;
    DecompressedData := TMemoryStream.Create;
    try
      CompressedData.WriteBuffer(GzipData[PayloadOffset],
        Length(GzipData) - PayloadOffset - 7);
      CompressedData.Position := 0;
      DecompressionStream := TDecompressionStream.Create(CompressedData, True);
      try
        DecompressedData.CopyFrom(DecompressionStream, 0);
      finally
        DecompressionStream.Free;
      end;

      SetLength(ADecodedText, DecompressedData.Size);
      if DecompressedData.Size > 0 then
      begin
        DecompressedData.Position := 0;
        DecompressedData.ReadBuffer(ADecodedText[1], DecompressedData.Size);
      end;
    finally
      DecompressedData.Free;
      CompressedData.Free;
    end;
  except
    on E: Exception do
    begin
      AErrorMessage := 'Unable to decompress the gzip data: ' + E.Message;
      Exit;
    end;
  end;

  Result := True;
end;

end.
