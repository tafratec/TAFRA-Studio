unit uComposerRunner;

{$mode objfpc}{$H+}

interface

uses
  Classes, uProcessRunner, uResultTypes, uSettingsService, uStudioSettings;

type
  TComposerRunner = class
  private
    FProcessRunner: TProcessRunner;
    FSettingsService: TSettingsService;
    function IsComposerPhar(const APath: string): Boolean;
    function CommandProcessorPath: string;
    function ComposerPHPPath(ASettings: TStudioSettings): string;
  public
    constructor Create(AProcessRunner: TProcessRunner;
      ASettingsService: TSettingsService);
    function TestComposer(ASettings: TStudioSettings): TOperationResult;
  end;

implementation

uses
  SysUtils;

constructor TComposerRunner.Create(AProcessRunner: TProcessRunner;
  ASettingsService: TSettingsService);
begin
  inherited Create;
  FProcessRunner := AProcessRunner;
  FSettingsService := ASettingsService;
end;

function TComposerRunner.IsComposerPhar(const APath: string): Boolean;
begin
  Result := SameText(ExtractFileExt(APath), '.phar');
end;

function TComposerRunner.CommandProcessorPath: string;
begin
  Result := GetEnvironmentVariable('ComSpec');
  if Result = '' then
    Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('SystemRoot')) +
      'System32' + DirectorySeparator + 'cmd.exe';
end;

function TComposerRunner.ComposerPHPPath(ASettings: TStudioSettings): string;
begin
  Result := '';
  if not Assigned(ASettings) or not Assigned(FSettingsService) then
    Exit;

  if SameText(ASettings.ComposerRuntimeMode, 'studio_php') then
    Result := FSettingsService.StudioPHPExecutablePath
  else if SameText(ASettings.ComposerRuntimeMode, 'custom_php') then
    Result := ASettings.ComposerCustomPHPPath
  else
  begin
    Result := FSettingsService.ProjectPHPExecutablePath;
    if Result = '' then
      Result := FSettingsService.StudioPHPExecutablePath;
  end;
end;

function TComposerRunner.TestComposer(ASettings: TStudioSettings
  ): TOperationResult;
var
  Args: TStringList;
  ProcessResult: TProcessResult;
  ComposerPath: string;
  ExecutablePath: string;
begin
  if not Assigned(ASettings) then
    Exit(TOperationResult.Fail('SETTINGS_MISSING',
      'Composer settings are not available.'));

  ComposerPath := Trim(ASettings.ComposerPath);
  if ComposerPath = '' then
    Exit(TOperationResult.Fail('COMPOSER_PATH_EMPTY',
      'Composer path is empty.'));

  if not FileExists(ComposerPath) then
    Exit(TOperationResult.Fail('COMPOSER_NOT_FOUND',
      'Composer executable not found: ' + ComposerPath));

  Args := TStringList.Create;
  try
    if IsComposerPhar(ComposerPath) then
    begin
      ExecutablePath := ComposerPHPPath(ASettings);
      if ExecutablePath = '' then
        Exit(TOperationResult.Fail('COMPOSER_PHP_MISSING',
          'No PHP executable is configured for composer.phar.'));

      Args.Add(ComposerPath);
      Args.Add('--version');
    end
    else if SameText(ExtractFileExt(ComposerPath), '.bat') or
      SameText(ExtractFileExt(ComposerPath), '.cmd') then
    begin
      ExecutablePath := CommandProcessorPath;
      Args.Add('/C');
      Args.Add(ComposerPath);
      Args.Add('--version');
    end
    else
    begin
      ExecutablePath := ComposerPath;
      Args.Add('--version');
    end;

    ProcessResult := FProcessRunner.Execute(ExecutablePath, Args, '', 15000);
    try
      if ProcessResult.Success then
        Result := TOperationResult.Ok(Trim(ProcessResult.StdOutText))
      else
        Result := TOperationResult.Fail(ProcessResult.ErrorCode,
          ProcessResult.MessageText + ' ' + Trim(ProcessResult.StdErrText));
    finally
      ProcessResult.Free;
    end;
  finally
    Args.Free;
  end;
end;

end.
