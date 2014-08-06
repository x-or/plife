object PersistentLifeForm: TPersistentLifeForm
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Persistent Life '#8212' Conway'#39's Game of Life with Generations'
  ClientHeight = 378
  ClientWidth = 436
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox1: TPaintBox
    Left = 8
    Top = 8
    Width = 300
    Height = 300
    Color = clWhite
    ParentColor = False
    OnMouseDown = PaintBox1MouseDown
    OnMouseMove = PaintBox1MouseMove
    OnMouseUp = PaintBox1MouseUp
    OnPaint = PaintBox1Paint
  end
  object Image1: TImage
    Left = 314
    Top = 344
    Width = 300
    Height = 300
    Visible = False
  end
  object PopulationLabel: TLabel
    Left = 8
    Top = 309
    Width = 65
    Height = 13
    Caption = 'Population: #'
  end
  object Label1: TLabel
    Left = 356
    Top = 66
    Width = 21
    Height = 13
    Caption = 'Rule'
  end
  object Label2: TLabel
    Left = 314
    Top = 88
    Width = 22
    Height = 13
    Caption = 'Birth'
  end
  object Label3: TLabel
    Left = 314
    Top = 115
    Width = 36
    Height = 13
    Caption = 'Survive'
  end
  object Label4: TLabel
    Left = 314
    Top = 142
    Width = 58
    Height = 13
    Caption = 'Generations'
  end
  object RunButton: TButton
    Left = 128
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 0
    OnClick = RunButtonClick
  end
  object LoadButton: TButton
    Left = 16
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Load'
    TabOrder = 1
    OnClick = LoadButtonClick
  end
  object PersistentBirthCheckBox: TCheckBox
    Left = 314
    Top = 24
    Width = 97
    Height = 17
    Caption = 'Persistent birth'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object StopButton: TButton
    Left = 209
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 3
    OnClick = StopButtonClick
  end
  object WriteImagesCheckBox: TCheckBox
    Left = 314
    Top = 43
    Width = 97
    Height = 17
    Caption = 'Write PNG'#39's'
    TabOrder = 4
  end
  object WrapCheckBox: TCheckBox
    Left = 314
    Top = 8
    Width = 97
    Height = 17
    Caption = 'Wrap'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
  object BirthRuleEdit: TEdit
    Left = 356
    Top = 85
    Width = 69
    Height = 21
    TabOrder = 6
    Text = '3'
  end
  object SurviveRuleEdit: TEdit
    Left = 356
    Top = 112
    Width = 69
    Height = 21
    TabOrder = 7
    Text = '23'
  end
  object GenerationsCountEdit: TJvSpinEdit
    Left = 378
    Top = 139
    Width = 50
    Height = 21
    ButtonKind = bkClassic
    MaxValue = 30.000000000000000000
    MinValue = 1.000000000000000000
    Value = 12.000000000000000000
    TabOrder = 8
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Images|*.bmp;*.png;*.jpg|All Files (*.*)|*.*'
    Left = 32
    Top = 352
  end
  object JvThread1: TJvThread
    Exclusive = True
    MaxCount = 0
    RunOnCreate = True
    FreeOnTerminate = True
    OnExecute = JvThread1Execute
    Left = 128
    Top = 352
  end
end
