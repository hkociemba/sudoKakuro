object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'SudoKakuro Solver 0.1'
  ClientHeight = 471
  ClientWidth = 527
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    527
    471)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 529
    Height = 416
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Fixedsys'
    Font.Style = []
    ParentFont = False
    PopupMenu = PopupMenu1
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object BSolve: TButton
    Left = 136
    Top = 438
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Solve'
    Enabled = False
    TabOrder = 1
    OnClick = BSolveClick
  end
  object CheckOutlineBoxes: TCheckBox
    Left = 8
    Top = 438
    Width = 97
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Outline Boxes'
    TabOrder = 2
  end
  object BAddSolution: TButton
    Left = 248
    Top = 438
    Width = 129
    Height = 25
    Caption = 'Find different solution'
    Enabled = False
    TabOrder = 3
    OnClick = BAddSolutionClick
  end
  object PopupMenu1: TPopupMenu
    Left = 480
    Top = 432
    object Paste1: TMenuItem
      Caption = 'Paste'
      ShortCut = 16470
      OnClick = PasteClick
    end
  end
end
