unit uLogger;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TLogLevel = (llInfo, llWarning, llError);
  TLogEvent = procedure(Sender: TObject; ALevel: TLogLevel;
    const AMessage: string) of object;

  TLogger = class
  private
    FOnLog: TLogEvent;
    procedure Write(ALevel: TLogLevel; const AMessage: string);
  public
    procedure Info(const AMessage: string);
    procedure Warning(const AMessage: string);
    procedure Error(const AMessage: string);
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

function LogLevelToText(ALevel: TLogLevel): string;

implementation

function LogLevelToText(ALevel: TLogLevel): string;
begin
  case ALevel of
    llWarning: Result := 'Warning';
    llError: Result := 'Error';
  else
    Result := 'Info';
  end;
end;

procedure TLogger.Write(ALevel: TLogLevel; const AMessage: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, ALevel, AMessage);
end;

procedure TLogger.Info(const AMessage: string);
begin
  Write(llInfo, AMessage);
end;

procedure TLogger.Warning(const AMessage: string);
begin
  Write(llWarning, AMessage);
end;

procedure TLogger.Error(const AMessage: string);
begin
  Write(llError, AMessage);
end;

end.
