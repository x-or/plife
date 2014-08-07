unit PersistentLife_Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, JvComponentBase, JvThread, StdCtrls, SyncObjs, JvSpin,
  Mask, JvExMask;

const
  StateSize = 300;
  MaxGenerations = 30;

type
  PGeneration = ^TGeneration;
  TGeneration = array[0..StateSize, 0..StateSize] of Boolean;
  PPopulation = ^TPopulation;
  TPopulation = array[1..MaxGenerations] of TGeneration; // 1 is the last generation
  PLifeRule = ^TLifeRule;
  TLifeRule = array[0..8] of Boolean;

type
  TRGB32 = packed record
    B, G, R, A: Byte;
  end;
  TRGB32Array = packed array[0..MaxInt div SizeOf(TRGB32)-1] of TRGB32;
  PRGB32Array = ^TRGB32Array;

type
  TPersistentLifeForm = class(TForm)
    RunButton: TButton;
    PaintBox1: TPaintBox;
    Image1: TImage;
    PopulationLabel: TLabel;
    LoadButton: TButton;
    OpenDialog1: TOpenDialog;
    PersistentBirthCheckBox: TCheckBox;
    StopButton: TButton;
    WriteImagesCheckBox: TCheckBox;
    WrapCheckBox: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    BirthRuleEdit: TEdit;
    SurviveRuleEdit: TEdit;
    Label4: TLabel;
    GenerationsCountEdit: TJvSpinEdit;
    JvThread1: TJvThread;
    procedure RunButtonClick(Sender: TObject);
    procedure JvThread1Execute(Sender: TObject; Params: Pointer);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fThread: TThread;
    fThreadTerminateEvent: TEvent;
    fWrap: Boolean;
    fPersistentBirth: Boolean;
    fWriteImages: Boolean;
    fCells: array[boolean] of TPopulation;
    fCurrentPopulation: Boolean;
    fInDraw: Boolean;
    fBirthRule: TLifeRule;
    fSurviveRule: TLifeRule;
    fGenerations: Integer;
    fHueToRGB: array[0..255] of TRGB32;
    fIntensityToRGB: array[0..255] of TRGB32;
    function GetCell(g, y, x: Integer): Boolean;
    procedure SetCell(p: Boolean; g, y, x: Integer);
    procedure Clear;
    procedure Stop;
    procedure UpdateUI;
    procedure UpdateVars;
    procedure GameStep;
    procedure Render;
  public
    { Public declarations }
  end;

var
  PersistentLifeForm: TPersistentLifeForm;

implementation
uses Math, GraphUtil, JPEG, PNGImage;

{$R *.dfm}

procedure TPersistentLifeForm.FormCreate(Sender: TObject);
var
  i: Integer;
  c: TColor;
begin
  fGenerations:=MaxGenerations;
  DoubleBuffered:=True;
  for i := Low(fHueToRGB) to High(fHueToRGB) do begin
    c:=ColorHLSToRGB(i, 127, 120);
    fHueToRGB[i].R:=GetRValue(c);
    fHueToRGB[i].G:=GetGValue(c);
    fHueToRGB[i].B:=GetBValue(c);
    fHueToRGB[i].A:=0;

    c:=ColorHLSToRGB(120*240 div 360, 127*i div 255, 120);
    fIntensityToRGB[i].R:=GetRValue(c);
    fIntensityToRGB[i].G:=GetGValue(c);
    fIntensityToRGB[i].B:=GetBValue(c);
    fIntensityToRGB[i].A:=0;
  end;
  fThreadTerminateEvent:=TEvent.Create(nil, False, False, '');
  Clear;
  UpdateUI;
end;

procedure TPersistentLifeForm.FormDestroy(Sender: TObject);
begin
  Stop;
end;

procedure TPersistentLifeForm.Clear;
var
  x, y, g: Integer;
  p: Boolean;
begin
  Image1.Canvas.Brush.Color:=clWhite;
  Image1.Canvas.FillRect(Image1.ClientRect);
  Image1.Refresh;
  for p :=False to True do
    for g := 1 to MaxGenerations do
      for y := 0 to StateSize-1 do
        for x := 0 to StateSize-1 do
            fCells[p, g, y, x]:=False;
end;

procedure TPersistentLifeForm.StopButtonClick(Sender: TObject);
begin
  Stop;
end;

procedure TPersistentLifeForm.Render;
var
  Line: PRGB32Array;
  cell: Boolean;
  x, y, gen, sum, max_sum: Integer;
  c: TRGB32;
  alpha: Byte;
begin
  max_sum:=(fGenerations)*(fGenerations-1) div 2; // sum of the numbers from 1 to fGenerations-1
  Image1.Canvas.Lock;
  Image1.Canvas.Brush.Color:=clBlack;
  Image1.Canvas.FillRect(Image1.ClientRect);
  try
    with Image1.Picture.Bitmap do begin
      PixelFormat := pf32bit;
      for y := 0 to StateSize-1 do begin
        Line:=ScanLine[y];
        for x := 0 to StateSize-1 do begin
          if fCells[fCurrentPopulation, fGenerations, y, x] then begin
            Line[x].R:=255;
            Line[x].G:=0;
            Line[x].B:=0;
            Line[x].A:=0;
          end else begin
            sum:=0;
            for gen := 2 to fGenerations do begin
              cell:=fCells[fCurrentPopulation, gen, y, x];
              if cell then begin
                sum:=sum+(gen-1); // Weighted sum of the live positions
              end;
            end;
            Line[x]:=fIntensityToRGB[255*sum div max_sum];
          end;
        end;
      end;
    end;
  finally
    Image1.Canvas.Unlock;
  end;
end;

procedure TPersistentLifeForm.SetCell(p: Boolean; g, y, x: Integer);
var
  i: Integer;
begin
  if fPersistentBirth then
    for i := g downto 1 do
      fCells[p, i, y, x]:=True
  else
    fCells[p, g, y, x]:=True;
end;

procedure FastSetCell(IsPersistentBirth: Boolean; p: PPopulation; g, y, x: Integer); inline;
var
  i: Integer;
begin
  if IsPersistentBirth then begin
    assert(g<=30);
    case g of
      1: begin
        p[1, y, x]:=True;
      end;
      2: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
      end;
      3: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
      end;
      4: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
      end;
      5: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
        p[5, y, x]:=True;
      end;
      6: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
        p[5, y, x]:=True;
        p[6, y, x]:=True;
      end;
      7: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
        p[5, y, x]:=True;
        p[6, y, x]:=True;
        p[7, y, x]:=True;
      end;
      8: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
        p[5, y, x]:=True;
        p[6, y, x]:=True;
        p[7, y, x]:=True;
        p[8, y, x]:=True;
      end;
      9: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
        p[5, y, x]:=True;
        p[6, y, x]:=True;
        p[7, y, x]:=True;
        p[8, y, x]:=True;
        p[9, y, x]:=True;
      end;
      10: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
        p[5, y, x]:=True;
        p[6, y, x]:=True;
        p[7, y, x]:=True;
        p[8, y, x]:=True;
        p[9, y, x]:=True;
        p[10, y, x]:=True;
      end;
      11: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
        p[5, y, x]:=True;
        p[6, y, x]:=True;
        p[7, y, x]:=True;
        p[8, y, x]:=True;
        p[9, y, x]:=True;
        p[10, y, x]:=True;
        p[11, y, x]:=True;
      end;
      12: begin
        p[1, y, x]:=True;
        p[2, y, x]:=True;
        p[3, y, x]:=True;
        p[4, y, x]:=True;
        p[5, y, x]:=True;
        p[6, y, x]:=True;
        p[7, y, x]:=True;
        p[8, y, x]:=True;
        p[9, y, x]:=True;
        p[10, y, x]:=True;
        p[11, y, x]:=True;
        p[12, y, x]:=True;
      end;
    else
      for i := g downto 1 do
        p[i, y, x]:=True
    end;
  end else
    p[g, y, x]:=True;
end;

function TPersistentLifeForm.GetCell(g, y, x: Integer): Boolean;
begin
  if x < 0 then
    x:=x+StateSize;
  if y < 0 then
    y:=y+StateSize;
  if x >= StateSize then
    x:=x-StateSize;
  if y>=StateSize then
    y:=y-StateSize;
  assert(x>=0);
  assert(y>=0);
  assert(x<StateSize);
  assert(y<StateSize);
  Result:=fCells[fCurrentPopulation, g, y, x];
end;

procedure TPersistentLifeForm.GameStep;
var
  p_new_pop: PPopulation;
  p_old_gen, p_new_gen: PGeneration;
  new_pop: Boolean;
  g, x, y, live_sum: Integer;
  c: Boolean;
  ym1, yp1, xm1, xp1: Integer; // y-1, y+1, x-1, x+1
  birth_rule, survive_rule: TLifeRule;
begin
  birth_rule:=fBirthRule;
  survive_rule:=fSurviveRule;
  new_pop:=not fCurrentPopulation;
  p_new_pop:=@fCells[new_pop];
  for g := 1 to fGenerations do begin
    p_old_gen:=@fCells[fCurrentPopulation, g];
    p_new_gen:=@p_new_pop[g];
    for y := 0 to StateSize-1 do begin
      // up
      if y > 0 then
        ym1:=y-1
      else if fWrap then
        ym1:=StateSize-1
      else
        ym1:=StateSize;
      // down
      if y < StateSize-1 then
        yp1:=y+1
      else if fWrap then
        yp1:=0
      else
        yp1:=StateSize;
      for x := 0 to StateSize-1 do begin
        // left
        if x > 0 then
          xm1:=x-1
        else if fWrap then
          xm1:=StateSize-1
        else
          xm1:=StateSize;
        // right
        if x < StateSize-1 then
          xp1:=x+1
        else if fWrap then
          xp1:=0
        else
        xp1:=StateSize;

        // calculate live cells
        live_sum:=0;
        if p_old_gen[ym1, xm1] then Inc(live_sum);
        if p_old_gen[ym1, x] then Inc(live_sum);
        if p_old_gen[ym1, xp1] then Inc(live_sum);
        if p_old_gen[y, xm1] then Inc(live_sum);
        c:=p_old_gen[y, x];
        if p_old_gen[y, xp1] then Inc(live_sum);
        if p_old_gen[yp1, xm1] then Inc(live_sum);
        if p_old_gen[yp1, x] then Inc(live_sum);
        if p_old_gen[yp1, xp1] then Inc(live_sum);

        // copy
        p_new_gen[y, x]:=c;

        if (not c) then begin
          // "dead" cell
          if (birth_rule[live_sum]) then begin
            // birth
            FastSetCell(fPersistentBirth, p_new_pop, g, y, x);
          end;
        end else if c then begin
          // "live cell"
          if (not survive_rule[live_sum]) then begin
            p_new_gen[y, x]:=False;
            if g>1 then // revive cell in the next generation(s)
              FastSetCell(fPersistentBirth, p_new_pop, g-1, y, x);
          end;
        end;
      end;
    end;
  end;
  fCurrentPopulation:=not fCurrentPopulation;
  if not fWrap then begin
    for g := 1 to fGenerations do begin
        p_new_gen:=@p_new_pop[g];
        for x := 0 to StateSize do
          p_new_gen[StateSize, x]:=False;
        for y := 0 to StateSize do
          p_new_gen[y, StateSize]:=False;
    end;
  end;
end;

procedure TPersistentLifeForm.JvThread1Execute(Sender: TObject; Params: Pointer);
var
  pc: Integer;
  png: TPNGImage;
begin
  png:=TPNGImage.Create;
  png.CompressionLevel:=7;
  pc:=0;

  while True do begin

    if Application.Terminated then
      break;
    if fThreadTerminateEvent.WaitFor(0) <> wrTimeout then
      break;

    Inc(pc);
    PopulationLabel.Caption:=Format('Population: %d', [pc]);

    GameStep;

    Render;

    if fWriteImages then begin
      png.Assign(Image1.Picture.Bitmap);
      png.SaveToFile(Format('life%.5d.png', [pc]));
    end;

    PaintBox1.Invalidate;

  end;

  png.Free;
end;

procedure TPersistentLifeForm.UpdateVars;
var
  s: String;
  i: Integer;
begin
  fWrap:=WrapCheckBox.Checked;
  fPersistentBirth:=PersistentBirthCheckBox.Checked;
  fWriteImages:=WriteImagesCheckBox.Checked;
  for I := 0 to 8 do begin
    fBirthRule[i]:=False;
    fSurviveRule[i]:=False;
  end;
  s:=BirthRuleEdit.Text;
  for i := 1 to Length(s) do begin
    if s[i] in ['1'..'8'] then
      fBirthRule[Ord(s[i])-Ord('0')]:=True;
  end;
  s:=SurviveRuleEdit.Text;
  for i := 1 to Length(s) do begin
    if s[i] in ['1'..'8'] then
      fSurviveRule[Ord(s[i])-Ord('0')]:=True;
  end;
  fGenerations:=Trunc(GenerationsCountEdit.Value);
  fGenerations:=Max(1, fGenerations);
  fGenerations:=Min(MaxGenerations, fGenerations);
end;

procedure TPersistentLifeForm.RunButtonClick(Sender: TObject);
begin
  UpdateVars;
  if fThread = nil then
    fThread:=JvThread1.Execute(nil);
  UpdateUI;
end;

procedure TPersistentLifeForm.Stop;
begin
  if fThread<>nil then begin
    fThreadTerminateEvent.SetEvent;
    JvThread1.WaitFor;
    fThread:=nil;
  end;
  UpdateUI;
end;

procedure TPersistentLifeForm.LoadButtonClick(Sender: TObject);
var
  x, y: Integer;
  bmp: TGraphic;
begin
  Stop;
  if OpenDialog1.Execute(Handle) then begin
    Clear;
    UpdateVars;
    if LowerCase(ExtractFileExt(OpenDialog1.FileName)) = '.jpg' then
      bmp:=TJPEGImage.Create
    else if LowerCase(ExtractFileExt(OpenDialog1.FileName)) = '.png' then
      bmp:=TPNGImage.Create
    else
      bmp:=TBitmap.Create;
    try
      bmp.LoadFromFile(OpenDialog1.FileName);
      Image1.Canvas.Draw(0, 0, bmp);
      for y := 0 to StateSize - 1 do
        for x := 0 to StateSize - 1 do begin
          if Image1.Canvas.Pixels[x, y] = clBlack then
            SetCell(fCurrentPopulation, fGenerations, y, x)
          else
            fCells[fCurrentPopulation, fGenerations, y, x]:=False;
        end;
      PaintBox1.Invalidate;
    finally
      FreeAndNil(bmp);
    end;
  end;
end;

procedure TPersistentLifeForm.UpdateUI;
begin
  WrapCheckBox.Enabled:=fThread=nil;
  PersistentBirthCheckBox.Enabled:=fThread=nil;
  WriteImagesCheckBox.Enabled:=fThread=nil;
  RunButton.Enabled:=fThread=nil;
  StopButton.Enabled:=fThread<>nil;
  BirthRuleEdit.Enabled:=fThread=nil;
  SurviveRuleEdit.Enabled:=fThread=nil;
  GenerationsCountEdit.Enabled:=fThread=nil;
  if Trunc(GenerationsCountEdit.Value)>MaxGenerations then
    GenerationsCountEdit.Value:=MaxGenerations
  else if Trunc(GenerationsCountEdit.Value)<1 then
    GenerationsCountEdit.Value:=1;
end;

procedure TPersistentLifeForm.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  UpdateVars;
  fInDraw:=True;
  if (x < 0) or (y < 0) then
    Exit;
  if (x >= StateSize) or (y >= StateSize) then
    Exit;
  PaintBox1.Canvas.Pixels[x, y]:=PaintBox1.Canvas.Pen.Color;
  Image1.Canvas.Pixels[x, y]:=PaintBox1.Canvas.Pen.Color;
  if Button = mbLeft then
    SetCell(fCurrentPopulation, fGenerations, y, x)
  else
    fCells[fCurrentPopulation, fGenerations, y, x]:=False;
end;

procedure TPersistentLifeForm.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; x,
  y: Integer);
begin
  UpdateVars;
  if fInDraw then begin
    if (x < 0) or (y < 0) then
      Exit;
    if (x >= StateSize) or (y >= StateSize) then
      Exit;
    PaintBox1.Canvas.Pixels[x, y]:=PaintBox1.Canvas.Pen.Color;
    Image1.Canvas.Pixels[x, y]:=PaintBox1.Canvas.Pen.Color;
    if ssLeft in Shift then
      SetCell(fCurrentPopulation, fGenerations, y, x)
    else
      fCells[fCurrentPopulation, fGenerations, y, x]:=False;
  end;
end;

procedure TPersistentLifeForm.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  fInDraw:=False;
end;

procedure TPersistentLifeForm.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Draw(0, 0, Image1.Picture.Graphic);
end;

end.
