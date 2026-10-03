unit uModuleManagementService;

{$mode objfpc}{$H+}

interface

uses
  Classes, uAppPaths, uPHPToolRunner, uProjectModel, uResultTypes;

type
  TModuleManagementAction = (
    mmaCreateModule,
    mmaCreateSubmodule,
    mmaEditModuleProperties,
    mmaEditSubmoduleProperties,
    mmaReorderSubmodules,
    mmaDeleteSubmodule,
    mmaDeleteModule,
    mmaCheckModuleNaming,
    mmaCheckSubmoduleNaming
  );

  TModuleManagementContext = record
    Project: TTAFRAProject;
    ModuleName: string;
    SubmoduleName: string;
    NodePath: string;
  end;

  TModuleManagementService = class
  private
    FAppPaths: TAppPaths;
    FPHPToolRunner: TPHPToolRunner;
    function ActionName(AAction: TModuleManagementAction): string;
    function BackendToolPath: string;
  public
    constructor Create(AAppPaths: TAppPaths; APHPToolRunner: TPHPToolRunner);
    function ActionCaption(AAction: TModuleManagementAction): string;
    function BuildPreview(AAction: TModuleManagementAction;
      const AContext: TModuleManagementContext): string;
    function Execute(AAction: TModuleManagementAction;
      const AContext: TModuleManagementContext): TOperationResult;
  end;

implementation

uses
  SysUtils;

constructor TModuleManagementService.Create(AAppPaths: TAppPaths;
  APHPToolRunner: TPHPToolRunner);
begin
  inherited Create;
  FAppPaths := AAppPaths;
  FPHPToolRunner := APHPToolRunner;
end;

function TModuleManagementService.ActionName(AAction: TModuleManagementAction
  ): string;
begin
  case AAction of
    mmaCreateModule: Result := 'create-module';
    mmaCreateSubmodule: Result := 'create-submodule';
    mmaEditModuleProperties: Result := 'edit-module-properties';
    mmaEditSubmoduleProperties: Result := 'edit-submodule-properties';
    mmaReorderSubmodules: Result := 'reorder-submodules';
    mmaDeleteSubmodule: Result := 'delete-submodule';
    mmaDeleteModule: Result := 'delete-module';
    mmaCheckModuleNaming: Result := 'check-module-naming';
    mmaCheckSubmoduleNaming: Result := 'check-submodule-naming';
  else
    Result := 'module-management';
  end;
end;

function TModuleManagementService.BackendToolPath: string;
begin
  if Assigned(FAppPaths) then
    Result := FAppPaths.PHPToolsPath + DirectorySeparator + 'module-management.php'
  else
    Result := '';
end;

function TModuleManagementService.ActionCaption(AAction: TModuleManagementAction
  ): string;
begin
  case AAction of
    mmaCreateModule: Result := 'Create Module';
    mmaCreateSubmodule: Result := 'Create Submodule';
    mmaEditModuleProperties: Result := 'Edit Module Properties';
    mmaEditSubmoduleProperties: Result := 'Edit Submodule Properties';
    mmaReorderSubmodules: Result := 'Reorder Submodules';
    mmaDeleteSubmodule: Result := 'Delete Submodule';
    mmaDeleteModule: Result := 'Delete Module';
    mmaCheckModuleNaming: Result := 'Check Module Naming Case';
    mmaCheckSubmoduleNaming: Result := 'Check Submodule Naming Case';
  else
    Result := 'Module Management';
  end;
end;

function TModuleManagementService.BuildPreview(AAction: TModuleManagementAction;
  const AContext: TModuleManagementContext): string;
begin
  Result := ActionCaption(AAction) + LineEnding + LineEnding;

  if Assigned(AContext.Project) then
    Result := Result + 'Project: ' + AContext.Project.Name + LineEnding;

  if AContext.ModuleName <> '' then
    Result := Result + 'Module: ' + AContext.ModuleName + LineEnding;

  if AContext.SubmoduleName <> '' then
    Result := Result + 'Submodule: ' + AContext.SubmoduleName + LineEnding;

  if AContext.NodePath <> '' then
    Result := Result + 'Path: ' + AContext.NodePath + LineEnding;

  Result := Result + LineEnding +
    'This command will run through the Studio PHP CLI backend and return a ' +
    'structured JSON response.';
end;

function TModuleManagementService.Execute(AAction: TModuleManagementAction;
  const AContext: TModuleManagementContext): TOperationResult;
var
  Args: TStringList;
  PHPResult: TPHPToolResult;
  ToolPath: string;
begin
  if not Assigned(AContext.Project) then
    Exit(TOperationResult.Fail('PROJECT_NOT_OPEN',
      'Open a TAFRA project before running module-management actions.'));

  if not Assigned(FPHPToolRunner) then
    Exit(TOperationResult.Fail('PHP_TOOL_RUNNER_MISSING',
      'PHP tool runner is not available.'));

  ToolPath := BackendToolPath;
  if ToolPath = '' then
    Exit(TOperationResult.Fail('PHP_TOOL_PATH_MISSING',
      'Module-management backend path is not configured.'));

  Args := TStringList.Create;
  try
    Args.Add('--project=' + AContext.Project.RootPath);
    Args.Add('--action=' + ActionName(AAction));

    if AContext.ModuleName <> '' then
      Args.Add('--module=' + AContext.ModuleName);

    if AContext.SubmoduleName <> '' then
      Args.Add('--submodule=' + AContext.SubmoduleName);

    PHPResult := FPHPToolRunner.ExecuteTool(ToolPath, Args, AContext.Project.RootPath);
    try
      if PHPResult.Success then
        Result := TOperationResult.Ok(PHPResult.MessageText)
      else if PHPResult.MessageText <> '' then
        Result := TOperationResult.Fail(PHPResult.ErrorCode, PHPResult.MessageText)
      else
        Result := TOperationResult.Fail(PHPResult.ErrorCode, PHPResult.RawOutput);
    finally
      PHPResult.Free;
    end;
  finally
    Args.Free;
  end;
end;

end.
