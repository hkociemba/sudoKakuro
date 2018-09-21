object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'SudoKakuro Solver 0.1'
  ClientHeight = 527
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
    527)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 529
    Height = 449
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
    Left = 111
    Top = 463
    Width = 129
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Solve'
    Enabled = False
    TabOrder = 1
    OnClick = BSolveClick
  end
  object CheckOutlineBoxes: TCheckBox
    Left = 8
    Top = 467
    Width = 97
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Outline Boxes'
    TabOrder = 2
  end
  object BAddSolution: TButton
    Left = 111
    Top = 494
    Width = 129
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Find different solution'
    Enabled = False
    TabOrder = 3
    OnClick = BAddSolutionClick
  end
  object BReduce: TButton
    Left = 422
    Top = 489
    Width = 97
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Reduce Puzzle'
    TabOrder = 4
    Visible = False
  end
  object GroupBox1: TGroupBox
    Left = 282
    Top = 463
    Width = 123
    Height = 56
    Caption = 'Additional Constraints'
    TabOrder = 5
    object CBSudokuX: TCheckBox
      Left = 7
      Top = 16
      Width = 97
      Height = 17
      Caption = 'SudokuX'
      TabOrder = 0
    end
    object CBSudokuP: TCheckBox
      Left = 7
      Top = 33
      Width = 90
      Height = 17
      Caption = 'SudokuP'
      TabOrder = 1
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 472
    Top = 456
    object Paste1: TMenuItem
      Caption = 'Paste'
      ShortCut = 16470
      OnClick = PasteClick
    end
  end
end
