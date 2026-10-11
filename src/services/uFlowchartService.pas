unit uFlowchartService;

{$mode objfpc}{$H+}

interface

uses
  Classes, uAppPaths, uPHPToolRunner, uResultTypes;

type
  TFlowchartResult = class(TOperationResult)
  private
    FSvgText: string;
  public
    constructor Create(ASuccess: Boolean; const AMessage: string;
      const AErrorCode: string = ''; const ASvgText: string = '');
    property SvgText: string read FSvgText;
  end;

  TFlowchartService = class
  private
    FAppPaths: TAppPaths;
    FPHPToolRunner: TPHPToolRunner;
    function FlowchartToolPath: string;
    function EscapeSvg(const AText: string): string;
    function RenderSvgFromJson(const AJsonText: string): TFlowchartResult;
  public
    constructor Create(AAppPaths: TAppPaths; APHPToolRunner: TPHPToolRunner);
    function ListMethods(const AFilePath: string): TStringList;
    function GenerateMethodSvg(const AFilePath, AMethodName: string
      ): TFlowchartResult;
  end;

implementation

uses
  fpjson, jsonparser, SysUtils;

constructor TFlowchartResult.Create(ASuccess: Boolean; const AMessage: string;
  const AErrorCode: string; const ASvgText: string);
begin
  inherited Create(ASuccess, AMessage, AErrorCode);
  FSvgText := ASvgText;
end;

constructor TFlowchartService.Create(AAppPaths: TAppPaths;
  APHPToolRunner: TPHPToolRunner);
begin
  inherited Create;
  FAppPaths := AAppPaths;
  FPHPToolRunner := APHPToolRunner;
end;

function TFlowchartService.FlowchartToolPath: string;
begin
  Result := FAppPaths.PHPToolsPath + DirectorySeparator + 'method-flowchart.php';
end;

function TFlowchartService.EscapeSvg(const AText: string): string;
begin
  Result := StringReplace(AText, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

function TFlowchartService.ListMethods(const AFilePath: string): TStringList;
var
  Args: TStringList;
  Data: TJSONData;
  I: Integer;
  MethodObj: TJSONObject;
  MethodsArray: TJSONArray;
  Node: TJSONData;
  PHPResult: TPHPToolResult;
  RootObj: TJSONObject;
begin
  Result := TStringList.Create;

  if not Assigned(FPHPToolRunner) then
    Exit;

  Args := TStringList.Create;
  try
    Args.Add('--file');
    Args.Add(AFilePath);
    Args.Add('--list');

    PHPResult := FPHPToolRunner.ExecuteTool(FlowchartToolPath, Args,
      FAppPaths.PHPToolsPath);
    try
      if not PHPResult.Success then
        Exit;

      Data := GetJSON(PHPResult.RawOutput);
      try
        if not (Data is TJSONObject) then
          Exit;

        RootObj := TJSONObject(Data);
        Node := RootObj.Find('methods');
        if not (Node is TJSONArray) then
          Exit;

        MethodsArray := TJSONArray(Node);
        for I := 0 to MethodsArray.Count - 1 do
          if MethodsArray.Items[I] is TJSONObject then
          begin
            MethodObj := TJSONObject(MethodsArray.Items[I]);
            Result.Add(MethodObj.Get('name', ''));
          end;
      finally
        Data.Free;
      end;
    finally
      PHPResult.Free;
    end;
  finally
    Args.Free;
  end;
end;

function TFlowchartService.RenderSvgFromJson(
  const AJsonText: string): TFlowchartResult;
var
  Data: TJSONData;
  EdgesArray: TJSONArray;
  Height: Integer;
  I: Integer;
  LabelText: string;
  FlowMethodName: string;
  Node: TJSONData;
  NodeObj: TJSONObject;
  NodesArray: TJSONArray;
  NodeType: string;
  RootObj: TJSONObject;
  Svg: TStringList;
  Width: Integer;
  X: Integer;
  Y: Integer;
begin
  try
    Data := GetJSON(AJsonText);
    try
      if not (Data is TJSONObject) then
        Exit(TFlowchartResult.Create(False,
          'Flowchart tool returned invalid JSON.', 'FLOWCHART_INVALID_JSON'));

      RootObj := TJSONObject(Data);
      if not RootObj.Get('success', False) then
        Exit(TFlowchartResult.Create(False, RootObj.Get('message', ''),
          RootObj.Get('error_code', 'FLOWCHART_TOOL_ERROR')));

      Node := RootObj.Find('nodes');
      if not (Node is TJSONArray) then
        Exit(TFlowchartResult.Create(False,
          'Flowchart model does not contain nodes.', 'FLOWCHART_NODES_MISSING'));

      NodesArray := TJSONArray(Node);
      Node := RootObj.Find('edges');
      if Node is TJSONArray then
        EdgesArray := TJSONArray(Node)
      else
        EdgesArray := nil;

      FlowMethodName := RootObj.Get('method', 'Method');
      Width := 720;
      Height := 120 + (NodesArray.Count * 100);
      X := Width div 2;

      Svg := TStringList.Create;
      try
        Svg.Add('<?xml version="1.0" encoding="UTF-8"?>');
        Svg.Add('<svg xmlns="http://www.w3.org/2000/svg" width="' +
          IntToStr(Width) + '" height="' + IntToStr(Height) +
          '" viewBox="0 0 ' + IntToStr(Width) + ' ' + IntToStr(Height) + '">');
        Svg.Add('<style>text{font-family:Arial,sans-serif;font-size:13px}.title{font-size:18px;font-weight:bold}.node{fill:#f9fbff;stroke:#1f4e79;stroke-width:2}.decision{fill:#fff4cc}.loop{fill:#e8f5e9}.return{fill:#fdecea}.edge{stroke:#555;stroke-width:1.5;marker-end:url(#arrow)}</style>');
        Svg.Add('<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#555"/></marker></defs>');
        Svg.Add('<rect x="0" y="0" width="100%" height="100%" fill="white"/>');
        Svg.Add('<text x="' + IntToStr(X) + '" y="34" text-anchor="middle" class="title">' +
          EscapeSvg(FlowMethodName) + '</text>');

        for I := 0 to NodesArray.Count - 1 do
        begin
          if not (NodesArray.Items[I] is TJSONObject) then
            Continue;

          NodeObj := TJSONObject(NodesArray.Items[I]);
          NodeType := NodeObj.Get('type', 'statement');
          LabelText := EscapeSvg(NodeObj.Get('label', ''));
          Y := 80 + (I * 100);

          if I < NodesArray.Count - 1 then
            Svg.Add('<line x1="' + IntToStr(X) + '" y1="' + IntToStr(Y + 42) +
              '" x2="' + IntToStr(X) + '" y2="' + IntToStr(Y + 88) +
              '" class="edge"/>');

          if NodeType = 'decision' then
          begin
            Svg.Add('<polygon points="' + IntToStr(X) + ',' + IntToStr(Y) +
              ' ' + IntToStr(X + 150) + ',' + IntToStr(Y + 36) +
              ' ' + IntToStr(X) + ',' + IntToStr(Y + 72) +
              ' ' + IntToStr(X - 150) + ',' + IntToStr(Y + 36) +
              '" class="node decision"/>');
            Svg.Add('<text x="' + IntToStr(X) + '" y="' + IntToStr(Y + 40) +
              '" text-anchor="middle">' + LabelText + '</text>');
          end
          else
          begin
            if NodeType = 'loop' then
              Svg.Add('<rect x="' + IntToStr(X - 150) + '" y="' +
                IntToStr(Y) + '" width="300" height="72" rx="8" class="node loop"/>')
            else if NodeType = 'return' then
              Svg.Add('<rect x="' + IntToStr(X - 150) + '" y="' +
                IntToStr(Y) + '" width="300" height="72" rx="20" class="node return"/>')
            else
              Svg.Add('<rect x="' + IntToStr(X - 150) + '" y="' +
                IntToStr(Y) + '" width="300" height="72" rx="12" class="node"/>');

            Svg.Add('<text x="' + IntToStr(X) + '" y="' + IntToStr(Y + 40) +
              '" text-anchor="middle">' + LabelText + '</text>');
          end;
        end;

        if Assigned(EdgesArray) then
          Svg.Add('<!-- Edges in this first renderer are displayed as a vertical sequence. Edge count: ' +
            IntToStr(EdgesArray.Count) + ' -->');
        Svg.Add('</svg>');

        Result := TFlowchartResult.Create(True, 'SVG flowchart generated.',
          '', Svg.Text);
      finally
        Svg.Free;
      end;
    finally
      Data.Free;
    end;
  except
    on E: Exception do
      Result := TFlowchartResult.Create(False, E.Message,
        'FLOWCHART_RENDER_ERROR');
  end;
end;

function TFlowchartService.GenerateMethodSvg(const AFilePath,
  AMethodName: string): TFlowchartResult;
var
  Args: TStringList;
  PHPResult: TPHPToolResult;
begin
  if not Assigned(FPHPToolRunner) then
    Exit(TFlowchartResult.Create(False, 'PHP tool runner is not available.',
      'PHP_TOOL_RUNNER_MISSING'));

  Args := TStringList.Create;
  try
    Args.Add('--file');
    Args.Add(AFilePath);
    Args.Add('--method');
    Args.Add(AMethodName);

    PHPResult := FPHPToolRunner.ExecuteTool(FlowchartToolPath, Args,
      FAppPaths.PHPToolsPath);
    try
      if not PHPResult.Success then
        Exit(TFlowchartResult.Create(False, PHPResult.MessageText,
          PHPResult.ErrorCode));

      Result := RenderSvgFromJson(PHPResult.RawOutput);
    finally
      PHPResult.Free;
    end;
  finally
    Args.Free;
  end;
end;

end.
