unit uPasswordGeneratorService;

{$mode objfpc}{$H+}

interface

type
  TPasswordCharacterMode = (
    pcmMixed,
    pcmCharactersAndNumbers,
    pcmCharactersOnly,
    pcmNumbersOnly
  );

  TPasswordGeneratorService = class
  private
    function CharactersForMode(AMode: TPasswordCharacterMode): string;
    function RandomCharFrom(const ACharacters: string): Char;
    procedure ShufflePassword(var APassword: string);
  public
    constructor Create;
    function GeneratePassword(ALength: Integer;
      AMode: TPasswordCharacterMode): string;
  end;

implementation

uses
  SysUtils;

const
  LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  NUMBERS = '0123456789';
  SYMBOLS = '!@#$%^&*()-_=+[]{};:,.?/';

constructor TPasswordGeneratorService.Create;
begin
  inherited Create;
  Randomize;
end;

function TPasswordGeneratorService.CharactersForMode(
  AMode: TPasswordCharacterMode): string;
begin
  case AMode of
    pcmMixed:
      Result := LETTERS + NUMBERS + SYMBOLS;
    pcmCharactersAndNumbers:
      Result := LETTERS + NUMBERS;
    pcmCharactersOnly:
      Result := LETTERS;
    pcmNumbersOnly:
      Result := NUMBERS;
  end;
end;

function TPasswordGeneratorService.RandomCharFrom(
  const ACharacters: string): Char;
begin
  if ACharacters = '' then
    Exit(#0);

  Result := ACharacters[Random(Length(ACharacters)) + 1];
end;

procedure TPasswordGeneratorService.ShufflePassword(var APassword: string);
var
  I: Integer;
  J: Integer;
  Temp: Char;
begin
  for I := Length(APassword) downto 2 do
  begin
    J := Random(I) + 1;
    Temp := APassword[I];
    APassword[I] := APassword[J];
    APassword[J] := Temp;
  end;
end;

function TPasswordGeneratorService.GeneratePassword(ALength: Integer;
  AMode: TPasswordCharacterMode): string;
var
  Characters: string;
begin
  Result := '';
  if ALength <= 0 then
    Exit;

  Characters := CharactersForMode(AMode);
  if Characters = '' then
    Exit;

  case AMode of
    pcmMixed:
      begin
        if ALength >= 1 then
          Result := Result + RandomCharFrom(LETTERS);
        if ALength >= 2 then
          Result := Result + RandomCharFrom(NUMBERS);
        if ALength >= 3 then
          Result := Result + RandomCharFrom(SYMBOLS);
      end;
    pcmCharactersAndNumbers:
      begin
        if ALength >= 1 then
          Result := Result + RandomCharFrom(LETTERS);
        if ALength >= 2 then
          Result := Result + RandomCharFrom(NUMBERS);
      end;
  end;

  while Length(Result) < ALength do
    Result := Result + RandomCharFrom(Characters);

  ShufflePassword(Result);
end;

end.
