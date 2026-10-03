unit uSettingsService;

{$mode objfpc}{$H+}

interface

uses
  Classes, uAppPaths, uProcessRunner, uResultTypes, uStudioSettings;

type
  TSettingsService = class
  private
    FAppPaths: TAppPaths;
    FProcessRunner: TProcessRunner;
    FSettings: TStudioSettings;
    function SettingsFilePath: string;
    function ResolvePath(const APath: string): string;
  public
    constructor Create(AAppPaths: TAppPaths; AProcessRunner: TProcessRunner);
    destructor Destroy; override;
    procedure ApplyDefaults(ASettings: TStudioSettings);
    function Load: TOperationResult;
    function Save(ASettings: TStudioSettings): TOperationResult;
    function StudioPHPExecutablePath: string;
    function ProjectPHPExecutablePath: string;
    function TestPHPExecutable(const AExecutablePath: string): TOperationResult;
    property Settings: TStudioSettings read FSettings;
  end;

implementation

uses
  fpjson, jsonparser, SysUtils;

constructor TSettingsService.Create(AAppPaths: TAppPaths;
  AProcessRunner: TProcessRunner);
begin
  inherited Create;
  FAppPaths := AAppPaths;
  FProcessRunner := AProcessRunner;
  FSettings := TStudioSettings.Create;
  ApplyDefaults(FSettings);
end;

destructor TSettingsService.Destroy;
begin
  FSettings.Free;
  inherited Destroy;
end;

function TSettingsService.SettingsFilePath: string;
begin
  Result := FAppPaths.ConfigPath + DirectorySeparator + 'studio-settings.json';
end;

function TSettingsService.ResolvePath(const APath: string): string;
begin
  Result := Trim(APath);
  if Result = '' then
    Exit;

  if (ExtractFileDrive(Result) <> '') or
    (Copy(Result, 1, 2) = '\\') then
    Exit;

  Result := IncludeTrailingPathDelimiter(FAppPaths.ApplicationRoot) + Result;
end;

procedure TSettingsService.ApplyDefaults(ASettings: TStudioSettings);
begin
  if not Assigned(ASettings) then
    Exit;

  if ASettings.StudioPHPPath = '' then
    ASettings.StudioPHPPath := FAppPaths.PHPExecutablePath;

  if ASettings.ProjectPHPMode = '' then
    ASettings.ProjectPHPMode := 'auto';

  if ASettings.ComposerRuntimeMode = '' then
    ASettings.ComposerRuntimeMode := 'project_php';

  if ASettings.SourceFontName = '' then
    ASettings.SourceFontName := 'Consolas';

  if ASettings.SourceFontSize <= 0 then
    ASettings.SourceFontSize := 10;
end;

function TSettingsService.Load: TOperationResult;
var
  Data: TJSONData;
  Root: TJSONObject;
  PHPObj: TJSONObject;
  ComposerObj: TJSONObject;
  SourceViewerObj: TJSONObject;
  Node: TJSONData;
  Path: string;
  FileText: TStringList;
begin
  ApplyDefaults(FSettings);
  Path := SettingsFilePath;

  if not FileExists(Path) then
    Exit(TOperationResult.Ok('Settings file not found; defaults are active.'));

  try
    FileText := TStringList.Create;
    try
      FileText.LoadFromFile(Path);
      Data := GetJSON(FileText.Text);
      try
        if not (Data is TJSONObject) then
          Exit(TOperationResult.Fail('INVALID_SETTINGS_JSON',
            'Settings file must contain a JSON object.'));

        Root := TJSONObject(Data);
        Node := Root.Find('php');
        if Assigned(Node) and (Node is TJSONObject) then
        begin
          PHPObj := TJSONObject(Node);
          FSettings.StudioPHPPath := PHPObj.Get('studio_php',
            FSettings.StudioPHPPath);
          FSettings.ProjectPHPPath := PHPObj.Get('project_php', '');
          FSettings.ProjectPHPMode := PHPObj.Get('project_php_mode',
            FSettings.ProjectPHPMode);
        end;

        Node := Root.Find('composer');
        if Assigned(Node) and (Node is TJSONObject) then
        begin
          ComposerObj := TJSONObject(Node);
          FSettings.ComposerPath := ComposerObj.Get('composer_path', '');
          FSettings.ComposerRuntimeMode := ComposerObj.Get('runtime_mode',
            FSettings.ComposerRuntimeMode);
          FSettings.ComposerCustomPHPPath := ComposerObj.Get('custom_php', '');
        end;

        Node := Root.Find('source_viewer');
        if Assigned(Node) and (Node is TJSONObject) then
        begin
          SourceViewerObj := TJSONObject(Node);
          FSettings.SourceFontName := SourceViewerObj.Get('font_name',
            FSettings.SourceFontName);
          FSettings.SourceFontSize := SourceViewerObj.Get('font_size',
            FSettings.SourceFontSize);
        end;

        ApplyDefaults(FSettings);
        Result := TOperationResult.Ok('Settings loaded.');
      finally
        Data.Free;
      end;
    finally
      FileText.Free;
    end;
  except
    on E: Exception do
      Result := TOperationResult.Fail('SETTINGS_LOAD_ERROR', E.Message);
  end;
end;

function TSettingsService.Save(ASettings: TStudioSettings): TOperationResult;
var
  Root: TJSONObject;
  PHPObj: TJSONObject;
  ComposerObj: TJSONObject;
  SourceViewerObj: TJSONObject;
  Text: string;
  FileText: TStringList;
begin
  if not Assigned(ASettings) then
    Exit(TOperationResult.Fail('SETTINGS_MISSING',
      'No settings were supplied for saving.'));

  ApplyDefaults(ASettings);
  ForceDirectories(FAppPaths.ConfigPath);

  try
    Root := TJSONObject.Create;
    try
      PHPObj := TJSONObject.Create;
      PHPObj.Add('studio_php', ASettings.StudioPHPPath);
      PHPObj.Add('project_php', ASettings.ProjectPHPPath);
      PHPObj.Add('project_php_mode', ASettings.ProjectPHPMode);
      Root.Add('php', PHPObj);

      ComposerObj := TJSONObject.Create;
      ComposerObj.Add('composer_path', ASettings.ComposerPath);
      ComposerObj.Add('runtime_mode', ASettings.ComposerRuntimeMode);
      ComposerObj.Add('custom_php', ASettings.ComposerCustomPHPPath);
      Root.Add('composer', ComposerObj);

      SourceViewerObj := TJSONObject.Create;
      SourceViewerObj.Add('font_name', ASettings.SourceFontName);
      SourceViewerObj.Add('font_size', ASettings.SourceFontSize);
      Root.Add('source_viewer', SourceViewerObj);

      Text := Root.FormatJSON;

      if not DirectoryExists(FAppPaths.ConfigPath) then
        ForceDirectories(FAppPaths.ConfigPath);

      if not DirectoryExists(FAppPaths.ConfigPath) then
        Exit(TOperationResult.Fail('CONFIG_DIRECTORY_MISSING',
          'Unable to create config directory.'));

      FileText := TStringList.Create;
      try
        Text := StringReplace(Text, LineEnding, sLineBreak, [rfReplaceAll]);
        Text := Text + sLineBreak;
        FileText.SetText(PChar(Text));
        FileText.SaveToFile(SettingsFilePath);
      finally
        FileText.Free;
      end;

      FSettings.Assign(ASettings);
      ApplyDefaults(FSettings);
      Result := TOperationResult.Ok('Settings saved.');
    finally
      Root.Free;
    end;
  except
    on E: Exception do
      Result := TOperationResult.Fail('SETTINGS_SAVE_ERROR', E.Message);
  end;
end;

function TSettingsService.StudioPHPExecutablePath: string;
begin
  Result := ResolvePath(FSettings.StudioPHPPath);
  if Result = '' then
    Result := FAppPaths.PHPExecutablePath;
end;

function TSettingsService.ProjectPHPExecutablePath: string;
begin
  Result := ResolvePath(FSettings.ProjectPHPPath);
end;

function TSettingsService.TestPHPExecutable(const AExecutablePath: string
  ): TOperationResult;
var
  Args: TStringList;
  ProcessResult: TProcessResult;
  ExePath: string;
begin
  ExePath := ResolvePath(AExecutablePath);

  if ExePath = '' then
    Exit(TOperationResult.Fail('PHP_PATH_EMPTY',
      'PHP executable path is empty.'));

  if not FileExists(ExePath) then
    Exit(TOperationResult.Fail('PHP_NOT_FOUND',
      'PHP executable not found: ' + ExePath));

  Args := TStringList.Create;
  try
    Args.Add('-v');
    ProcessResult := FProcessRunner.Execute(ExePath, Args, '', 10000);
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
