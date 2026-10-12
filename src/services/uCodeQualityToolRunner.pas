unit uCodeQualityToolRunner;

{$mode objfpc}{$H+}

interface

uses
  Classes, uPHPToolRunner, uProcessRunner, uResultTypes;

type
  TCodeQualityToolRunner = class
  private
    FProcessRunner: TProcessRunner;
    FPHPToolRunner: TPHPToolRunner;
  public
    constructor Create(AProcessRunner: TProcessRunner;
      APHPToolRunner: TPHPToolRunner);
    function ExecuteProcessTool(const AExecutablePath: string;
      AArguments: TStrings; const AWorkingDirectory: string;
      ATimeoutMS: Cardinal): TProcessResult;
    function ExecutePHPTool(const AToolPath: string; AArguments: TStrings;
      const AWorkingDirectory: string): TPHPToolResult;
    function ExecutePHPProcessTool(const AToolPath: string; AArguments: TStrings;
      const AWorkingDirectory: string; ATimeoutMS: Cardinal): TProcessResult;
    function ConfiguredPHPExecutablePath: string;
    property ProcessRunner: TProcessRunner read FProcessRunner;
    property PHPToolRunner: TPHPToolRunner read FPHPToolRunner;
  end;

implementation

constructor TCodeQualityToolRunner.Create(AProcessRunner: TProcessRunner;
  APHPToolRunner: TPHPToolRunner);
begin
  inherited Create;
  FProcessRunner := AProcessRunner;
  FPHPToolRunner := APHPToolRunner;
end;

function TCodeQualityToolRunner.ExecuteProcessTool(
  const AExecutablePath: string; AArguments: TStrings;
  const AWorkingDirectory: string; ATimeoutMS: Cardinal): TProcessResult;
begin
  if not Assigned(FProcessRunner) then
  begin
    Result := TProcessResult.Create;
    Result.Success := False;
    Result.ErrorCode := 'PROCESS_RUNNER_MISSING';
    Result.MessageText := 'Process runner is not available.';
    Exit;
  end;

  Result := FProcessRunner.Execute(AExecutablePath, AArguments,
    AWorkingDirectory, ATimeoutMS);
end;

function TCodeQualityToolRunner.ExecutePHPTool(const AToolPath: string;
  AArguments: TStrings; const AWorkingDirectory: string): TPHPToolResult;
begin
  if not Assigned(FPHPToolRunner) then
  begin
    Result := TPHPToolResult.Create;
    Result.Success := False;
    Result.ErrorCode := 'PHP_TOOL_RUNNER_MISSING';
    Result.MessageText := 'PHP tool runner is not available.';
    Exit;
  end;

  Result := FPHPToolRunner.ExecuteTool(AToolPath, AArguments,
    AWorkingDirectory);
end;

function TCodeQualityToolRunner.ExecutePHPProcessTool(
  const AToolPath: string; AArguments: TStrings;
  const AWorkingDirectory: string; ATimeoutMS: Cardinal): TProcessResult;
begin
  if not Assigned(FPHPToolRunner) then
  begin
    Result := TProcessResult.Create;
    Result.Success := False;
    Result.ErrorCode := 'PHP_TOOL_RUNNER_MISSING';
    Result.MessageText := 'PHP tool runner is not available.';
    Exit;
  end;

  Result := FPHPToolRunner.ExecuteScript(AToolPath, AArguments,
    AWorkingDirectory, ATimeoutMS);
end;

function TCodeQualityToolRunner.ConfiguredPHPExecutablePath: string;
begin
  if Assigned(FPHPToolRunner) then
    Result := FPHPToolRunner.ConfiguredPHPExecutablePath
  else
    Result := '';
end;

end.
