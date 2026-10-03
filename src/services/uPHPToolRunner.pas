unit uPHPToolRunner;

{$mode objfpc}{$H+}

interface

uses
  Classes, uAppPaths, uProcessRunner, uResultTypes, uSettingsService;

type
  TPHPToolRunner = class
  private
    FAppPaths: TAppPaths;
    FProcessRunner: TProcessRunner;
    FSettingsService: TSettingsService;
    function ParseToolResult(const ARawOutput: string): TPHPToolResult;
    function PHPExecutablePath: string;
  public
    constructor Create(AAppPaths: TAppPaths; AProcessRunner: TProcessRunner;
      ASettingsService: TSettingsService = nil);
    function ExecuteTool(const AToolPath: string; AArguments: TStrings;
      const AWorkingDirectory: string = ''): TPHPToolResult;
    function ExecuteHealthCheck: TPHPToolResult;
  end;

implementation

uses
  fpjson, jsonparser, SysUtils;

constructor TPHPToolRunner.Create(AAppPaths: TAppPaths;
  AProcessRunner: TProcessRunner; ASettingsService: TSettingsService);
begin
  inherited Create;
  FAppPaths := AAppPaths;
  FProcessRunner := AProcessRunner;
  FSettingsService := ASettingsService;
end;

function TPHPToolRunner.PHPExecutablePath: string;
begin
  if Assigned(FSettingsService) then
    Result := FSettingsService.StudioPHPExecutablePath
  else
    Result := FAppPaths.PHPExecutablePath;
end;

function TPHPToolRunner.ParseToolResult(const ARawOutput: string): TPHPToolResult;
var
  Data: TJSONData;
  Obj: TJSONObject;
begin
  Result := TPHPToolResult.Create;
  Result.RawOutput := ARawOutput;

  try
    Data := GetJSON(ARawOutput);
    try
      if not (Data is TJSONObject) then
      begin
        Result.Success := False;
        Result.ErrorCode := 'INVALID_JSON_RESPONSE';
        Result.MessageText := 'PHP tool did not return a JSON object.';
        Exit;
      end;

      Obj := TJSONObject(Data);
      Result.Success := Obj.Get('success', False);
      Result.MessageText := Obj.Get('message', '');
      Result.ErrorCode := Obj.Get('error_code', '');
      Result.PHPVersion := Obj.Get('php_version', '');
    finally
      Data.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorCode := 'JSON_PARSE_ERROR';
      Result.MessageText := E.Message;
    end;
  end;
end;

function TPHPToolRunner.ExecuteTool(const AToolPath: string;
  AArguments: TStrings; const AWorkingDirectory: string): TPHPToolResult;
var
  Args: TStringList;
  ProcessResult: TProcessResult;
  I: Integer;
begin
  if not Assigned(FProcessRunner) then
  begin
    Result := TPHPToolResult.Create;
    Result.Success := False;
    Result.ErrorCode := 'PROCESS_RUNNER_MISSING';
    Result.MessageText := 'Process runner is not available.';
    Exit;
  end;

  if not FileExists(AToolPath) then
  begin
    Result := TPHPToolResult.Create;
    Result.Success := False;
    Result.ErrorCode := 'PHP_TOOL_NOT_FOUND';
    Result.MessageText := 'PHP tool not found: ' + AToolPath;
    Exit;
  end;

  Args := TStringList.Create;
  try
    Args.Add(AToolPath);
    if Assigned(AArguments) then
      for I := 0 to AArguments.Count - 1 do
        Args.Add(AArguments[I]);

    ProcessResult := FProcessRunner.Execute(PHPExecutablePath, Args,
      AWorkingDirectory, 10000);
    try
      if not ProcessResult.Success then
      begin
        if Trim(ProcessResult.StdOutText) <> '' then
        begin
          Result := ParseToolResult(Trim(ProcessResult.StdOutText));
          if (Result.ErrorCode <> 'JSON_PARSE_ERROR') and
            (Result.ErrorCode <> 'INVALID_JSON_RESPONSE') then
            Exit;

          Result.Free;
        end;

        Result := TPHPToolResult.Create;
        Result.Success := False;
        Result.ErrorCode := ProcessResult.ErrorCode;
        Result.MessageText := ProcessResult.MessageText;
        Result.RawOutput := ProcessResult.StdOutText + ProcessResult.StdErrText;
        Exit;
      end;

      Result := ParseToolResult(Trim(ProcessResult.StdOutText));
    finally
      ProcessResult.Free;
    end;
  finally
    Args.Free;
  end;
end;

function TPHPToolRunner.ExecuteHealthCheck: TPHPToolResult;
begin
  Result := ExecuteTool(FAppPaths.PHPHealthCheckToolPath, nil,
    FAppPaths.PHPToolsPath);
end;

end.
