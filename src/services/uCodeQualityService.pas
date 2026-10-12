unit uCodeQualityService;

{$mode objfpc}{$H+}

interface

uses
  Classes, uAppPaths, uCodeQualityModel, uCodeQualityToolRunner, uProjectModel,
  uResultTypes;

type
  TCodeQualityService = class
  private
    FToolRunner: TCodeQualityToolRunner;
    FAppPaths: TAppPaths;
    FConfiguration: TCodeQualityConfiguration;
    procedure AddConfigurationFinding(AReport: TCodeQualityReport);
    procedure AddToolDetectionFindings(AReport: TCodeQualityReport;
      AProject: TTAFRAProject);
    procedure AddToolDisabledFinding(AReport: TCodeQualityReport;
      const AToolName: string);
    procedure AddToolExecutionFailure(AReport: TCodeQualityReport;
      const AToolName: string; AProcessResult: TProcessResult);
    procedure AddToolFinding(AReport: TCodeQualityReport;
      const AToolName, AToolPath, AConfigPath: string);
    procedure AddInitialTAFRAChecks(AReport: TCodeQualityReport;
      AProject: TTAFRAProject; const AScopePath: string);
    procedure AddAnalysisTargets(AArguments: TStrings;
      const AProjectPath, AScopePath: string; AInitialCount: Integer);
    function DetectPHPCSFixerPath(const AProjectPath: string): string;
    function DetectPHPCSPath(const AProjectPath: string): string;
    function DetectPHPStanPath(const AProjectPath: string): string;
    function DetectRectorPath(const AProjectPath: string): string;
    function FindFirstExisting(const AProjectPath: string;
      const ACandidates: array of string): string;
    function ExecuteAnalysisTool(const AToolPath: string; AArguments: TStrings;
      const AWorkingDirectory: string; ATimeoutMS: Cardinal;
      AReport: TCodeQualityReport; const AToolName: string): TProcessResult;
    procedure AddToolStatus(AReport: TCodeQualityReport; const AToolName,
      AToolPath, AOutcome, AStandardError: string; AElapsedMilliseconds: QWord);
    procedure AddStudioDefaultRulesWarning(AReport: TCodeQualityReport;
      const AToolName, AToolPath, AConfigPath: string);
    function ToolSource(const AToolPath: string): string;
    function IsExcludedPath(const ARelativePath: string): Boolean;
    function IsIncludedPath(const ARelativePath: string): Boolean;
    function NormalizeRelativePath(const APath: string): string;
    function PathIsInScope(const APath, AScopePath: string): Boolean;
    procedure ParsePHPCSFixerOutput(AReport: TCodeQualityReport;
      const AOutput: string);
    procedure ParsePHPCSOutput(AReport: TCodeQualityReport;
      const AOutput: string);
    procedure ParsePHPStanOutput(AReport: TCodeQualityReport;
      const AOutput: string);
    function ProjectPath(const AProjectPath, ARelativePath: string): string;
    function ProjectToolConfigPath(const AProjectPath: string;
      const ACandidates: array of string): string;
    procedure RunPHPCSFixerDryRun(AReport: TCodeQualityReport;
      AProject: TTAFRAProject; const AScopePath: string);
    procedure RunPHPCSAnalysis(AReport: TCodeQualityReport;
      AProject: TTAFRAProject; const AScopePath: string);
    procedure RunPHPStanAnalysis(AReport: TCodeQualityReport;
      AProject: TTAFRAProject; const AScopePath: string);
    procedure RunReadOnlyAnalyses(AReport: TCodeQualityReport;
      AProject: TTAFRAProject; const AScopePath: string);
    function AnalyzeInternal(AProject: TTAFRAProject; const AScopePath,
      AScopeDescription: string): TCodeQualityReport;
  public
    constructor Create(AToolRunner: TCodeQualityToolRunner; AAppPaths: TAppPaths);
    destructor Destroy; override;
    function AnalyzeProject(AProject: TTAFRAProject): TCodeQualityReport;
    function AnalyzeScope(AProject: TTAFRAProject; const AScopePath,
      AScopeDescription: string): TCodeQualityReport;
    property Configuration: TCodeQualityConfiguration read FConfiguration;
    property ToolRunner: TCodeQualityToolRunner read FToolRunner;
  end;

implementation

uses
  fpjson, jsonparser, SysUtils;

constructor TCodeQualityService.Create(AToolRunner: TCodeQualityToolRunner;
  AAppPaths: TAppPaths);
begin
  inherited Create;
  FToolRunner := AToolRunner;
  FAppPaths := AAppPaths;
  FConfiguration := TCodeQualityConfiguration.Create;
end;

destructor TCodeQualityService.Destroy;
begin
  FConfiguration.Free;
  inherited Destroy;
end;

function TCodeQualityService.ProjectPath(const AProjectPath,
  ARelativePath: string): string;
begin
  Result := IncludeTrailingPathDelimiter(AProjectPath) + ARelativePath;
end;

function TCodeQualityService.ProjectToolConfigPath(const AProjectPath: string;
  const ACandidates: array of string): string;
begin
  Result := FindFirstExisting(AProjectPath, ACandidates);
end;

function TCodeQualityService.FindFirstExisting(const AProjectPath: string;
  const ACandidates: array of string): string;
var
  I: Integer;
  CandidatePath: string;
begin
  Result := '';
  for I := Low(ACandidates) to High(ACandidates) do
  begin
    CandidatePath := ProjectPath(AProjectPath, ACandidates[I]);
    if FileExists(CandidatePath) then
      Exit(CandidatePath);
  end;
end;

procedure TCodeQualityService.AddToolStatus(AReport: TCodeQualityReport;
  const AToolName, AToolPath, AOutcome, AStandardError: string;
  AElapsedMilliseconds: QWord);
var
  PHPPath: string;
begin
  if not Assigned(AReport) then
    Exit;

  if (LowerCase(ExtractFileExt(AToolPath)) = '.bat') or
    (LowerCase(ExtractFileExt(AToolPath)) = '.cmd') then
    PHPPath := 'System PATH (Composer wrapper)'
  else
    PHPPath := FToolRunner.ConfiguredPHPExecutablePath;

  AReport.AddToolStatus(TCodeQualityToolStatus.Create(AToolName, AToolPath,
    ToolSource(AToolPath), PHPPath, AOutcome, AStandardError,
    AElapsedMilliseconds));
end;

function TCodeQualityService.ToolSource(const AToolPath: string): string;
var
  StudioToolsPath: string;
begin
  if AToolPath = '' then
    Exit('Not available');

  if Assigned(FAppPaths) then
  begin
    StudioToolsPath := IncludeTrailingPathDelimiter(FAppPaths.PHPToolsPath);
    if SameText(Copy(AToolPath, 1, Length(StudioToolsPath)), StudioToolsPath) then
      Exit('Studio-bundled');
  end;
  Result := 'Project-local';
end;

procedure TCodeQualityService.AddStudioDefaultRulesWarning(
  AReport: TCodeQualityReport; const AToolName, AToolPath, AConfigPath: string);
begin
  if (AConfigPath <> '') or (ToolSource(AToolPath) <> 'Studio-bundled') or
    not Assigned(AReport) then
    Exit;

  AReport.AddFinding(TCodeQualityFinding.Create(
    AToolName,
    AReport.ProjectPath,
    '',
    0,
    0,
    'Configuration',
    cqsWarning,
    cqrSafe,
    'Studio-bundled ' + AToolName +
      ' ran without a project configuration file; default rules were used.',
    'Add a project configuration file to make the analysis rules explicit.'));
end;

function TCodeQualityService.ExecuteAnalysisTool(const AToolPath: string;
  AArguments: TStrings; const AWorkingDirectory: string;
  ATimeoutMS: Cardinal; AReport: TCodeQualityReport;
  const AToolName: string): TProcessResult;
var
  ElapsedMilliseconds: QWord;
  Extension: string;
  StartTicks: QWord;
begin
  StartTicks := GetTickCount64;
  Extension := LowerCase(ExtractFileExt(AToolPath));
  if (Extension = '.bat') or (Extension = '.cmd') or (Extension = '.exe') then
    Result := FToolRunner.ExecuteProcessTool(AToolPath, AArguments,
      AWorkingDirectory, ATimeoutMS)
  else
    Result := FToolRunner.ExecutePHPProcessTool(AToolPath, AArguments,
      AWorkingDirectory, ATimeoutMS);

  ElapsedMilliseconds := GetTickCount64 - StartTicks;
  if Result.Success then
    AddToolStatus(AReport, AToolName, AToolPath, 'Completed',
      Result.StdErrText, ElapsedMilliseconds)
  else if Result.TimedOut then
    AddToolStatus(AReport, AToolName, AToolPath, 'Timed out',
      Result.StdErrText, ElapsedMilliseconds)
  else if Trim(Result.StdOutText) <> '' then
    AddToolStatus(AReport, AToolName, AToolPath,
      'Completed with findings (exit code ' + IntToStr(Result.ExitCode) + ')',
      Result.StdErrText, ElapsedMilliseconds)
  else
    AddToolStatus(AReport, AToolName, AToolPath,
      'Failed (exit code ' + IntToStr(Result.ExitCode) + ')',
      Result.StdErrText, ElapsedMilliseconds);
end;

function TCodeQualityService.DetectPHPCSFixerPath(
  const AProjectPath: string): string;
begin
  Result := FindFirstExisting(AProjectPath, [
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'php-cs-fixer.bat',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'php-cs-fixer.cmd',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'php-cs-fixer.exe',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'php-cs-fixer']);
  if (Result = '') and Assigned(FAppPaths) then
    Result := FindFirstExisting(FAppPaths.PHPToolsPath, [
      'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'php-cs-fixer',
      'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'php-cs-fixer.bat']);
end;

function TCodeQualityService.DetectPHPCSPath(const AProjectPath: string
  ): string;
begin
  Result := FindFirstExisting(AProjectPath, [
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpcs.bat',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpcs.cmd',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpcs.exe',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpcs']);
  if (Result = '') and Assigned(FAppPaths) then
    Result := FindFirstExisting(FAppPaths.PHPToolsPath, [
      'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpcs',
      'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpcs.bat']);
end;

function TCodeQualityService.DetectPHPStanPath(const AProjectPath: string
  ): string;
begin
  Result := FindFirstExisting(AProjectPath, [
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpstan.bat',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpstan.cmd',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpstan.exe',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpstan']);
  if (Result = '') and Assigned(FAppPaths) then
    Result := FindFirstExisting(FAppPaths.PHPToolsPath, [
      'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpstan',
      'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'phpstan.bat']);
end;

function TCodeQualityService.DetectRectorPath(const AProjectPath: string
  ): string;
begin
  Result := FindFirstExisting(AProjectPath, [
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'rector.bat',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'rector.cmd',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'rector.exe',
    'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'rector']);
  if (Result = '') and Assigned(FAppPaths) then
    Result := FindFirstExisting(FAppPaths.PHPToolsPath, [
      'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'rector',
      'vendor' + DirectorySeparator + 'bin' + DirectorySeparator + 'rector.bat']);
end;

function TCodeQualityService.NormalizeRelativePath(const APath: string): string;
begin
  Result := StringReplace(APath, '/', DirectorySeparator, [rfReplaceAll]);
  Result := StringReplace(Result, '\', DirectorySeparator, [rfReplaceAll]);
end;

function TCodeQualityService.PathIsInScope(const APath,
  AScopePath: string): Boolean;
var
  NormalizedPath: string;
  NormalizedScope: string;
begin
  if AScopePath = '' then
    Exit(True);

  NormalizedPath := ExcludeTrailingPathDelimiter(ExpandFileName(APath));
  NormalizedScope := ExcludeTrailingPathDelimiter(ExpandFileName(AScopePath));
  Result := SameText(NormalizedPath, NormalizedScope) or
    (DirectoryExists(NormalizedScope) and
      SameText(Copy(NormalizedPath, 1, Length(IncludeTrailingPathDelimiter(
        NormalizedScope))), IncludeTrailingPathDelimiter(NormalizedScope)));
end;

procedure TCodeQualityService.AddAnalysisTargets(AArguments: TStrings;
  const AProjectPath, AScopePath: string; AInitialCount: Integer);
var
  I: Integer;
begin
  if AScopePath <> '' then
  begin
    AArguments.Add(AScopePath);
    Exit;
  end;

  for I := 0 to FConfiguration.IncludedPaths.Count - 1 do
    if DirectoryExists(ProjectPath(AProjectPath, FConfiguration.IncludedPaths[I])) then
      AArguments.Add(FConfiguration.IncludedPaths[I]);
  if AArguments.Count = AInitialCount then
    AArguments.Add(AProjectPath);
end;

function TCodeQualityService.IsExcludedPath(const ARelativePath: string
  ): Boolean;
var
  I: Integer;
  PathText: string;
  ExcludedPath: string;
begin
  Result := False;
  PathText := NormalizeRelativePath(ARelativePath);

  for I := 0 to FConfiguration.ExcludedPaths.Count - 1 do
  begin
    ExcludedPath := NormalizeRelativePath(FConfiguration.ExcludedPaths[I]);
    if (PathText = ExcludedPath) or
      (Pos(IncludeTrailingPathDelimiter(ExcludedPath), PathText) = 1) or
      (Pos(DirectorySeparator + ExcludedPath + DirectorySeparator,
        PathText) > 0) then
      Exit(True);
  end;
end;

function TCodeQualityService.IsIncludedPath(const ARelativePath: string
  ): Boolean;
var
  I: Integer;
  PathText: string;
  IncludedPath: string;
begin
  Result := FConfiguration.IncludedPaths.Count = 0;
  PathText := NormalizeRelativePath(ARelativePath);

  for I := 0 to FConfiguration.IncludedPaths.Count - 1 do
  begin
    IncludedPath := NormalizeRelativePath(FConfiguration.IncludedPaths[I]);
    if (PathText = IncludedPath) or
      (Pos(IncludeTrailingPathDelimiter(IncludedPath), PathText) = 1) then
      Exit(True);
  end;
end;

procedure TCodeQualityService.AddToolFinding(AReport: TCodeQualityReport;
  const AToolName, AToolPath, AConfigPath: string);
var
  MessageText: string;
  Recommendation: string;
  Severity: TCodeQualitySeverity;
begin
  if AToolPath <> '' then
  begin
    Severity := cqsInfo;
    MessageText := AToolName + ' was detected.';
    if AConfigPath <> '' then
      Recommendation := 'Configuration detected: ' + AConfigPath
    else
      Recommendation := 'Tool is available. Add a project-specific configuration if custom rules are needed.';
  end
  else
  begin
    Severity := cqsWarning;
    MessageText := AToolName + ' was not detected in project vendor/bin.';
    Recommendation := 'Install or configure ' + AToolName +
      ' later if this analysis capability should be enabled. TAFRA Studio does not install it automatically.';
  end;

  AReport.AddFinding(TCodeQualityFinding.Create(
    AToolName,
    AToolPath,
    '',
    0,
    0,
    'Tool Detection',
    Severity,
    cqrSafe,
    MessageText,
    Recommendation));
end;

procedure TCodeQualityService.AddToolDisabledFinding(
  AReport: TCodeQualityReport; const AToolName: string);
begin
  AReport.AddFinding(TCodeQualityFinding.Create(
    AToolName,
    '',
    '',
    0,
    0,
    'Configuration',
    cqsInfo,
    cqrSafe,
    AToolName + ' is disabled in the current Code Quality configuration.',
    'Enable this tool later if this analysis capability should be included.'));
end;

procedure TCodeQualityService.AddToolExecutionFailure(
  AReport: TCodeQualityReport; const AToolName: string;
  AProcessResult: TProcessResult);
begin
  if not Assigned(AReport) or not Assigned(AProcessResult) then
    Exit;

  AReport.AddFinding(TCodeQualityFinding.Create(
    AToolName,
    AReport.ProjectPath,
    '',
    0,
    0,
    'Tool Execution',
    cqsWarning,
    cqrSafe,
    AToolName + ' did not return a usable analysis report. ' +
      AProcessResult.MessageText,
    'Check the tool configuration and output. Raw stderr: ' +
      Trim(AProcessResult.StdErrText)));
end;

procedure TCodeQualityService.AddConfigurationFinding(
  AReport: TCodeQualityReport);
var
  MessageText: string;
  Recommendation: string;
begin
  if not Assigned(AReport) or not Assigned(FConfiguration) then
    Exit;

  MessageText :=
    'Code Quality read-only configuration is active. ' +
    'Included paths: ' + FConfiguration.IncludedPaths.CommaText + '. ' +
    'Excluded paths: ' + FConfiguration.ExcludedPaths.CommaText + '. ' +
    'Timeout: ' + IntToStr(FConfiguration.TimeoutMS) + ' ms.';

  Recommendation :=
    'Enabled tools: PHP-CS-Fixer=' +
    BoolToStr(FConfiguration.PHPCSFixerEnabled, True) +
    ', PHPCS=' + BoolToStr(FConfiguration.PHPCSEnabled, True) +
    ', PHPStan=' + BoolToStr(FConfiguration.PHPStanEnabled, True) +
    ', Rector=' + BoolToStr(FConfiguration.RectorEnabled, True) + '.';

  AReport.AddFinding(TCodeQualityFinding.Create(
    'TAFRA Studio',
    AReport.ProjectPath,
    '',
    0,
    0,
    'Configuration',
    cqsInfo,
    cqrSafe,
    MessageText,
    Recommendation));
end;

procedure TCodeQualityService.ParsePHPCSFixerOutput(
  AReport: TCodeQualityReport; const AOutput: string);
var
  Data: TJSONData;
  FileItem: TJSONData;
  FilesArray: TJSONArray;
  I: Integer;
  Obj: TJSONObject;
  FileName: string;
begin
  if Trim(AOutput) = '' then
    Exit;

  try
    Data := GetJSON(AOutput);
    try
      if not (Data is TJSONObject) then
        Exit;

      Obj := TJSONObject(Data);
      FileItem := Obj.Find('files');
      if not (FileItem is TJSONArray) then
        Exit;

      FilesArray := TJSONArray(FileItem);
      for I := 0 to FilesArray.Count - 1 do
      begin
        if FilesArray.Items[I] is TJSONObject then
          FileName := TJSONObject(FilesArray.Items[I]).Get('name', '')
        else
          FileName := '';

        if FileName = '' then
          Continue;

        AReport.AddFinding(TCodeQualityFinding.Create(
          'PHP-CS-Fixer',
          FileName,
          ExtractRelativePath(IncludeTrailingPathDelimiter(AReport.ProjectPath),
            FileName),
          0,
          0,
          'Formatting',
          cqsWarning,
          cqrSafe,
          'Formatting changes are available for this file.',
          'Review PHP-CS-Fixer dry-run output before applying any cleanup.'));
      end;
    finally
      Data.Free;
    end;
  except
    on E: Exception do
      AReport.AddFinding(TCodeQualityFinding.Create(
        'PHP-CS-Fixer',
        AReport.ProjectPath,
        '',
        0,
        0,
        'Tool Output',
        cqsWarning,
        cqrSafe,
        'Unable to parse PHP-CS-Fixer JSON output.',
        E.Message));
  end;
end;

procedure TCodeQualityService.ParsePHPCSOutput(
  AReport: TCodeQualityReport; const AOutput: string);
var
  Data: TJSONData;
  FilesData: TJSONData;
  FileData: TJSONData;
  MessagesData: TJSONData;
  FileName: string;
  FileObj: TJSONObject;
  FilesObj: TJSONObject;
  I: Integer;
  J: Integer;
  MessageObj: TJSONObject;
  MessagesArray: TJSONArray;
  RootObj: TJSONObject;
  Severity: TCodeQualitySeverity;
begin
  if Trim(AOutput) = '' then
    Exit;

  try
    Data := GetJSON(AOutput);
    try
      if not (Data is TJSONObject) then
        Exit;

      RootObj := TJSONObject(Data);
      FilesData := RootObj.Find('files');
      if not (FilesData is TJSONObject) then
        Exit;

      FilesObj := TJSONObject(FilesData);
      for I := 0 to FilesObj.Count - 1 do
      begin
        FileName := FilesObj.Names[I];
        FileData := FilesObj.Items[I];
        if not (FileData is TJSONObject) then
          Continue;

        FileObj := TJSONObject(FileData);
        MessagesData := FileObj.Find('messages');
        if not (MessagesData is TJSONArray) then
          Continue;

        MessagesArray := TJSONArray(MessagesData);
        for J := 0 to MessagesArray.Count - 1 do
        begin
          if not (MessagesArray.Items[J] is TJSONObject) then
            Continue;

          MessageObj := TJSONObject(MessagesArray.Items[J]);
          if SameText(MessageObj.Get('type', ''), 'ERROR') then
            Severity := cqsCritical
          else
            Severity := cqsWarning;

          AReport.AddFinding(TCodeQualityFinding.Create(
            'PHPCS',
            FileName,
            ExtractRelativePath(IncludeTrailingPathDelimiter(AReport.ProjectPath),
              FileName),
            MessageObj.Get('line', 0),
            MessageObj.Get('column', 0),
            MessageObj.Get('source', 'Coding Standard'),
            Severity,
            cqrSafe,
            MessageObj.Get('message', ''),
            'Review the coding-standard violation and apply only approved fixes.'));
        end;
      end;
    finally
      Data.Free;
    end;
  except
    on E: Exception do
      AReport.AddFinding(TCodeQualityFinding.Create(
        'PHPCS',
        AReport.ProjectPath,
        '',
        0,
        0,
        'Tool Output',
        cqsWarning,
        cqrSafe,
        'Unable to parse PHPCS JSON output.',
        E.Message));
  end;
end;

procedure TCodeQualityService.ParsePHPStanOutput(
  AReport: TCodeQualityReport; const AOutput: string);
var
  Data: TJSONData;
  FileData: TJSONData;
  FileName: string;
  FilesData: TJSONData;
  FilesObj: TJSONObject;
  I: Integer;
  J: Integer;
  MessageObj: TJSONObject;
  MessagesArray: TJSONArray;
  MessagesData: TJSONData;
  RootObj: TJSONObject;
begin
  if Trim(AOutput) = '' then
    Exit;

  try
    Data := GetJSON(AOutput);
    try
      if not (Data is TJSONObject) then
        Exit;

      RootObj := TJSONObject(Data);
      FilesData := RootObj.Find('files');
      if not (FilesData is TJSONObject) then
        Exit;

      FilesObj := TJSONObject(FilesData);
      for I := 0 to FilesObj.Count - 1 do
      begin
        FileName := FilesObj.Names[I];
        FileData := FilesObj.Items[I];
        if not (FileData is TJSONObject) then
          Continue;

        MessagesData := TJSONObject(FileData).Find('messages');
        if not (MessagesData is TJSONArray) then
          Continue;

        MessagesArray := TJSONArray(MessagesData);
        for J := 0 to MessagesArray.Count - 1 do
        begin
          if not (MessagesArray.Items[J] is TJSONObject) then
            Continue;

          MessageObj := TJSONObject(MessagesArray.Items[J]);
          AReport.AddFinding(TCodeQualityFinding.Create(
            'PHPStan',
            FileName,
            ExtractRelativePath(IncludeTrailingPathDelimiter(AReport.ProjectPath),
              FileName),
            MessageObj.Get('line', 0),
            0,
            'Static Analysis',
            cqsWarning,
            cqrLow,
            MessageObj.Get('message', ''),
            'Review the static-analysis finding before changing code.'));
        end;
      end;
    finally
      Data.Free;
    end;
  except
    on E: Exception do
      AReport.AddFinding(TCodeQualityFinding.Create(
        'PHPStan',
        AReport.ProjectPath,
        '',
        0,
        0,
        'Tool Output',
        cqsWarning,
        cqrSafe,
        'Unable to parse PHPStan JSON output.',
        E.Message));
  end;
end;

procedure TCodeQualityService.AddToolDetectionFindings(
  AReport: TCodeQualityReport; AProject: TTAFRAProject);
var
  ToolPath: string;
  ConfigPath: string;
begin
  if not Assigned(AReport) or not Assigned(AProject) then
    Exit;

  if FConfiguration.PHPCSFixerEnabled then
  begin
    ToolPath := DetectPHPCSFixerPath(AProject.RootPath);
    ConfigPath := FindFirstExisting(AProject.RootPath, [
      '.php-cs-fixer.php',
      '.php-cs-fixer.dist.php']);
    AddToolFinding(AReport, 'PHP-CS-Fixer', ToolPath, ConfigPath);
  end
  else
    AddToolDisabledFinding(AReport, 'PHP-CS-Fixer');

  if FConfiguration.PHPCSEnabled then
  begin
    ToolPath := DetectPHPCSPath(AProject.RootPath);
    ConfigPath := FindFirstExisting(AProject.RootPath, [
      'phpcs.xml',
      'phpcs.xml.dist']);
    AddToolFinding(AReport, 'PHPCS', ToolPath, ConfigPath);
  end
  else
    AddToolDisabledFinding(AReport, 'PHPCS');

  if FConfiguration.PHPStanEnabled then
  begin
    ToolPath := DetectPHPStanPath(AProject.RootPath);
    ConfigPath := FindFirstExisting(AProject.RootPath, [
      'phpstan.neon',
      'phpstan.neon.dist']);
    AddToolFinding(AReport, 'PHPStan', ToolPath, ConfigPath);
  end
  else
    AddToolDisabledFinding(AReport, 'PHPStan');

  if FConfiguration.RectorEnabled then
  begin
    ToolPath := DetectRectorPath(AProject.RootPath);
    ConfigPath := FindFirstExisting(AProject.RootPath, [
      'rector.php',
      'rector.php.dist']);
    AddToolFinding(AReport, 'Rector', ToolPath, ConfigPath);
  end
  else
    AddToolDisabledFinding(AReport, 'Rector');
end;

procedure TCodeQualityService.RunPHPCSFixerDryRun(
  AReport: TCodeQualityReport; AProject: TTAFRAProject; const AScopePath: string);
var
  Args: TStringList;
  ConfigPath: string;
  ProcessResult: TProcessResult;
  ToolPath: string;
begin
  if not FConfiguration.PHPCSFixerEnabled then
  begin
    AddToolStatus(AReport, 'PHP-CS-Fixer', '', 'Disabled', '', 0);
    Exit;
  end;

  ToolPath := DetectPHPCSFixerPath(AProject.RootPath);
  if ToolPath = '' then
  begin
    AddToolStatus(AReport, 'PHP-CS-Fixer', '', 'Not available', '', 0);
    Exit;
  end;
  ConfigPath := ProjectToolConfigPath(AProject.RootPath, [
    '.php-cs-fixer.php', '.php-cs-fixer.dist.php']);
  AddStudioDefaultRulesWarning(AReport, 'PHP-CS-Fixer', ToolPath, ConfigPath);

  Args := TStringList.Create;
  try
    Args.Add('fix');
    Args.Add('--dry-run');
    Args.Add('--format=json');
    Args.Add('--using-cache=no');
    if ConfigPath <> '' then
      Args.Add('--config=' + ConfigPath);
    Args.Add('--');
    AddAnalysisTargets(Args, AProject.RootPath, AScopePath, Args.Count);

    ProcessResult := ExecuteAnalysisTool(ToolPath, Args,
      AProject.RootPath, FConfiguration.TimeoutMS, AReport, 'PHP-CS-Fixer');
    try
      if Trim(ProcessResult.StdOutText) <> '' then
        ParsePHPCSFixerOutput(AReport, ProcessResult.StdOutText)
      else if not ProcessResult.Success then
        AddToolExecutionFailure(AReport, 'PHP-CS-Fixer', ProcessResult);
    finally
      ProcessResult.Free;
    end;
  finally
    Args.Free;
  end;
end;

procedure TCodeQualityService.RunPHPCSAnalysis(AReport: TCodeQualityReport;
  AProject: TTAFRAProject; const AScopePath: string);
var
  Args: TStringList;
  ConfigPath: string;
  ProcessResult: TProcessResult;
  ToolPath: string;
begin
  if not FConfiguration.PHPCSEnabled then
  begin
    AddToolStatus(AReport, 'PHPCS', '', 'Disabled', '', 0);
    Exit;
  end;

  ToolPath := DetectPHPCSPath(AProject.RootPath);
  if ToolPath = '' then
  begin
    AddToolStatus(AReport, 'PHPCS', '', 'Not available', '', 0);
    Exit;
  end;
  ConfigPath := ProjectToolConfigPath(AProject.RootPath, [
    'phpcs.xml', 'phpcs.xml.dist']);
  AddStudioDefaultRulesWarning(AReport, 'PHPCS', ToolPath, ConfigPath);

  Args := TStringList.Create;
  try
    Args.Add('--report=json');
    if ConfigPath <> '' then
      Args.Add('--standard=' + ConfigPath);
    AddAnalysisTargets(Args, AProject.RootPath, AScopePath, Args.Count);

    ProcessResult := ExecuteAnalysisTool(ToolPath, Args,
      AProject.RootPath, FConfiguration.TimeoutMS, AReport, 'PHPCS');
    try
      if Trim(ProcessResult.StdOutText) <> '' then
        ParsePHPCSOutput(AReport, ProcessResult.StdOutText)
      else if not ProcessResult.Success then
        AddToolExecutionFailure(AReport, 'PHPCS', ProcessResult);
    finally
      ProcessResult.Free;
    end;
  finally
    Args.Free;
  end;
end;

procedure TCodeQualityService.RunPHPStanAnalysis(AReport: TCodeQualityReport;
  AProject: TTAFRAProject; const AScopePath: string);
var
  Args: TStringList;
  ConfigPath: string;
  ProcessResult: TProcessResult;
  ToolPath: string;
begin
  if not FConfiguration.PHPStanEnabled then
  begin
    AddToolStatus(AReport, 'PHPStan', '', 'Disabled', '', 0);
    Exit;
  end;

  ToolPath := DetectPHPStanPath(AProject.RootPath);
  if ToolPath = '' then
  begin
    AddToolStatus(AReport, 'PHPStan', '', 'Not available', '', 0);
    Exit;
  end;
  ConfigPath := ProjectToolConfigPath(AProject.RootPath, [
    'phpstan.neon', 'phpstan.neon.dist']);
  AddStudioDefaultRulesWarning(AReport, 'PHPStan', ToolPath, ConfigPath);

  Args := TStringList.Create;
  try
    Args.Add('analyse');
    Args.Add('--error-format=json');
    Args.Add('--no-progress');
    if ConfigPath <> '' then
      Args.Add('--configuration=' + ConfigPath);
    AddAnalysisTargets(Args, AProject.RootPath, AScopePath, Args.Count);

    ProcessResult := ExecuteAnalysisTool(ToolPath, Args,
      AProject.RootPath, FConfiguration.TimeoutMS, AReport, 'PHPStan');
    try
      if Trim(ProcessResult.StdOutText) <> '' then
        ParsePHPStanOutput(AReport, ProcessResult.StdOutText)
      else if not ProcessResult.Success then
        AddToolExecutionFailure(AReport, 'PHPStan', ProcessResult);
    finally
      ProcessResult.Free;
    end;
  finally
    Args.Free;
  end;
end;

procedure TCodeQualityService.AddInitialTAFRAChecks(
  AReport: TCodeQualityReport; AProject: TTAFRAProject; const AScopePath: string);
var
  FileText: TStringList;
  I: Integer;
  ProjectFile: TTAFRAProjectFile;
  Text: string;
begin
  if not Assigned(AReport) or not Assigned(AProject) then
    Exit;

  if (AScopePath = '') and not DirectoryExists(AProject.RootPath + DirectorySeparator + 'app' +
    DirectorySeparator + 'modules') then
    AReport.AddFinding(TCodeQualityFinding.Create(
      'TAFRA Rules',
      AProject.RootPath,
      '',
      0,
      0,
      'TAFRA Structure',
      cqsWarning,
      cqrSafe,
      'TAFRA modules directory was not found.',
      'Verify that this project follows the expected TAFRA app/modules structure.'));

  for I := 0 to AProject.Files.Count - 1 do
  begin
    ProjectFile := TTAFRAProjectFile(AProject.Files[I]);
    if not SameText(ProjectFile.Extension, '.php') then
      Continue;

    if not PathIsInScope(ProjectFile.Path, AScopePath) then
      Continue;

    if IsExcludedPath(ProjectFile.RelativePath) or
      not IsIncludedPath(ProjectFile.RelativePath) then
      Continue;

    if (Pos('Controller', ProjectFile.Name) = 0) and
      (Pos(DirectorySeparator + 'controllers' + DirectorySeparator,
        NormalizeRelativePath(ProjectFile.RelativePath)) = 0) then
      Continue;

    if not FileExists(ProjectFile.Path) then
      Continue;

    FileText := TStringList.Create;
    try
      try
        FileText.LoadFromFile(ProjectFile.Path);
        Text := LowerCase(FileText.Text);
      except
        Continue;
      end;

      if (Pos('select ', Text) > 0) or (Pos('insert ', Text) > 0) or
        (Pos('update ', Text) > 0) or (Pos('delete ', Text) > 0) or
        (Pos('$this->db', Text) > 0) or (Pos('mysqli_', Text) > 0) then
        AReport.AddFinding(TCodeQualityFinding.Create(
          'TAFRA Rules',
          ProjectFile.Path,
          ProjectFile.RelativePath,
          0,
          0,
          'Controller Responsibility',
          cqsWarning,
          cqrMedium,
          'Possible database or business logic was found in a controller.',
          'Review whether this logic belongs in a model or service.'));
    finally
      FileText.Free;
    end;
  end;
end;

procedure TCodeQualityService.RunReadOnlyAnalyses(
  AReport: TCodeQualityReport; AProject: TTAFRAProject; const AScopePath: string);
begin
  if not Assigned(AReport) or not Assigned(AProject) or not Assigned(FToolRunner) then
    Exit;

  RunPHPCSFixerDryRun(AReport, AProject, AScopePath);
  RunPHPCSAnalysis(AReport, AProject, AScopePath);
  RunPHPStanAnalysis(AReport, AProject, AScopePath);
  AddInitialTAFRAChecks(AReport, AProject, AScopePath);
end;

function TCodeQualityService.AnalyzeInternal(AProject: TTAFRAProject;
  const AScopePath, AScopeDescription: string): TCodeQualityReport;
begin
  if Assigned(AProject) then
    Result := TCodeQualityReport.Create(AProject.RootPath)
  else
    Result := TCodeQualityReport.Create('');

  if not Assigned(AProject) then
  begin
    Result.AddFinding(TCodeQualityFinding.Create(
      'TAFRA Studio',
      '',
      '',
      0,
      0,
      'Foundation',
      cqsCritical,
      cqrSafe,
      'No project is available for code quality analysis.',
      'Open a project before running code quality analysis.'));
    Exit;
  end;

  Result.GeneratedAt := Now;
  Result.ScopePath := AScopePath;
  Result.ScopeDescription := AScopeDescription;
  Result.AddFinding(TCodeQualityFinding.Create(
    'TAFRA Studio',
    AProject.RootPath,
    '',
    0,
    0,
    'Foundation',
    cqsInfo,
    cqrSafe,
    'Code Quality service layer is available.',
    'Tool detection is read-only and checks project-local Composer binaries first, then Studio-bundled tools.'));

  AddConfigurationFinding(Result);
  AddToolDetectionFindings(Result, AProject);
  RunReadOnlyAnalyses(Result, AProject, AScopePath);
end;

function TCodeQualityService.AnalyzeProject(
  AProject: TTAFRAProject): TCodeQualityReport;
begin
  Result := AnalyzeInternal(AProject, '', 'Entire project');
end;

function TCodeQualityService.AnalyzeScope(AProject: TTAFRAProject;
  const AScopePath, AScopeDescription: string): TCodeQualityReport;
begin
  if not Assigned(AProject) then
    Exit(AnalyzeInternal(nil, '', 'No project'));
  if (AScopePath = '') or not (FileExists(AScopePath) or DirectoryExists(AScopePath)) or
    not PathIsInScope(AScopePath, AProject.RootPath) then
    Exit(AnalyzeInternal(nil, '', 'Invalid scope'));
  Result := AnalyzeInternal(AProject, AScopePath, AScopeDescription);
end;

end.
