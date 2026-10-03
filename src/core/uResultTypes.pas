unit uResultTypes;

{$mode objfpc}{$H+}

interface

type
  TOperationResult = class
  private
    FSuccess: Boolean;
    FErrorCode: string;
    FMessage: string;
  public
    constructor Create(ASuccess: Boolean; const AMessage: string;
      const AErrorCode: string = '');
    class function Ok(const AMessage: string = ''): TOperationResult;
    class function Fail(const AErrorCode, AMessage: string): TOperationResult;
    property Success: Boolean read FSuccess;
    property ErrorCode: string read FErrorCode;
    property MessageText: string read FMessage;
  end;

  TProcessResult = class
  private
    FSuccess: Boolean;
    FExecutablePath: string;
    FExitCode: Integer;
    FStdOutText: string;
    FStdErrText: string;
    FErrorCode: string;
    FMessage: string;
    FTimedOut: Boolean;
  public
    property Success: Boolean read FSuccess write FSuccess;
    property ExecutablePath: string read FExecutablePath write FExecutablePath;
    property ExitCode: Integer read FExitCode write FExitCode;
    property StdOutText: string read FStdOutText write FStdOutText;
    property StdErrText: string read FStdErrText write FStdErrText;
    property ErrorCode: string read FErrorCode write FErrorCode;
    property MessageText: string read FMessage write FMessage;
    property TimedOut: Boolean read FTimedOut write FTimedOut;
  end;

  TPHPToolResult = class
  private
    FSuccess: Boolean;
    FErrorCode: string;
    FMessage: string;
    FRawOutput: string;
    FPHPVersion: string;
  public
    property Success: Boolean read FSuccess write FSuccess;
    property ErrorCode: string read FErrorCode write FErrorCode;
    property MessageText: string read FMessage write FMessage;
    property RawOutput: string read FRawOutput write FRawOutput;
    property PHPVersion: string read FPHPVersion write FPHPVersion;
  end;

implementation

constructor TOperationResult.Create(ASuccess: Boolean; const AMessage: string;
  const AErrorCode: string);
begin
  inherited Create;
  FSuccess := ASuccess;
  FMessage := AMessage;
  FErrorCode := AErrorCode;
end;

class function TOperationResult.Ok(const AMessage: string): TOperationResult;
begin
  Result := TOperationResult.Create(True, AMessage);
end;

class function TOperationResult.Fail(const AErrorCode, AMessage: string
  ): TOperationResult;
begin
  Result := TOperationResult.Create(False, AMessage, AErrorCode);
end;

end.
